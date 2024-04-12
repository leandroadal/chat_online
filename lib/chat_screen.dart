import 'dart:io';

import 'package:chat_online/chat_message.dart';
import 'package:chat_online/text_composer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  User? _currentUser;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Future<User?> _getUser() async {
    if (_currentUser != null) return _currentUser;

    FirebaseAuth auth = FirebaseAuth.instance;
    User? user;

    try {
      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      final GoogleSignInAuthentication googleSignInAuthentication =
          await googleSignInAccount!.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleSignInAuthentication.idToken,
          accessToken: googleSignInAuthentication.accessToken);

      final UserCredential userCredential =
          await auth.signInWithCredential(credential);

      user = userCredential.user;
      return user;
    } catch (error) {
      print(error);
      return null;
    }
  }

  void _sendMessage({String? message, File? imgFile}) async {
    final User? user = await _getUser();

    if (user == null) {
      //if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Não foi possível fazer o login. Tente novamente.'),
        backgroundColor: Colors.red,
      ));
    } else {
      Map<String, dynamic> data = {
        "uid": user!.uid,
        "senderName": user.displayName,
        "senderPhotoUrl": user.photoURL,
        'time': Timestamp.now(),
      };
      //FirebaseFirestore.instance.collection('messages').add({
      //'text': message,
      //'time': FieldValue.serverTimestamp(),
      //'user': FirebaseAuth.instance.currentUser?.uid,
      //});

      if (imgFile != null) {
        UploadTask task = FirebaseStorage.instance
            .ref()
            .child(user.uid +
                DateTime.now()
                    .millisecondsSinceEpoch
                    .toString()) // adiciona o id do usuário para evirar imagens com mesmo nome
            .putFile(imgFile);

        setState(() {
          _isLoading = true;
        });

        TaskSnapshot taskSnapshot = await task;
        String url = await taskSnapshot.ref.getDownloadURL();
        data["imgUrl"] = url;

        setState(() {
          _isLoading = false;
        });
      }

      if (message != null) {
        data['text'] = message;
      }

      FirebaseFirestore.instance.collection('messages').add(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_currentUser != null
            ? 'Olá, ${_currentUser?.displayName}'
            : 'Chat'),
        elevation: 0,
        //backgroundColor: Colors.blue,
        actions: [
          _currentUser != null
              ? IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    await googleSignIn.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Voce saiu com sucesso!'),
                      backgroundColor: Colors.red,
                    ));
                  },
                )
              : Container(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .orderBy('time')
                  .snapshots(),
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.none:
                  case ConnectionState.waiting:
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  default:
                    List<DocumentSnapshot> documents =
                        snapshot.data!.docs.reversed.toList();

                    return ListView.builder(
                      itemCount: documents.length,
                      reverse: true,
                      itemBuilder: (context, index) {
                        final messageData =
                            documents[index].data() as Map<String, dynamic>;
                        final bool mine = messageData['uid'] ==
                            FirebaseAuth.instance.currentUser?.uid;
                        return ChatMessage(
                          data: messageData,
                          mine: mine,
                        );
                      },
                    );
                }
              },
            ),
          ),
          _isLoading ? const LinearProgressIndicator() : Container(),
          TextComposer(
            sendMessage: _sendMessage,
          ),
        ],
      ),
    );
  }
}
