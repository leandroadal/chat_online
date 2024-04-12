import 'dart:io';

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

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      _currentUser = user;
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
      };
      //FirebaseFirestore.instance.collection('messages').add({
      //'text': message,
      //'time': FieldValue.serverTimestamp(),
      //'user': FirebaseAuth.instance.currentUser?.uid,
      //});

      if (imgFile != null) {
        UploadTask task = FirebaseStorage.instance
            .ref()
            .child(DateTime.now().millisecondsSinceEpoch.toString())
            .putFile(imgFile);

        TaskSnapshot taskSnapshot = await task;
        String url = await taskSnapshot.ref.getDownloadURL();
        data["imgUrl"] = url;
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
        title: Text(''),
        elevation: 0,
        //backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('messages').snapshots(),
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
                        final message =
                            documents[index].data() as Map<String, dynamic>;
                        final text = message['text'] ?? '';
                        return ListTile(
                          title: Text(text),
                        );
                      },
                    );
                }
              },
            ),
          ),
          TextComposer(
            sendMessage: _sendMessage,
          ),
        ],
      ),
    );
  }
}
