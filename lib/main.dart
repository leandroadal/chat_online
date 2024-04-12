import 'package:chat_online/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding
      .ensureInitialized(); // para garantir que o ambiente do Flutter esteja pronto para o Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());

  final db = FirebaseFirestore.instance;

  final express = <String, dynamic>{
    'text': 'Olá Mundo!',
    'from': 'Leandro',
    'read': false
  };

  /*
  db.collection('messages').doc().set(express);
  //await Firebase.initializeApp();
  FirebaseFirestore.instance.collection('messages').snapshots().listen((event) {
    event.docs.forEach((element) {
      print(element.data());
    });
  });
  */
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ChatScreen(),
        theme: ThemeData(
          primaryColor: Colors.blue,
          appBarTheme: AppBarTheme(
            color: Colors.blue,
          ),
          iconTheme: IconThemeData(
            color: Colors.blue,
          ),
        ));
  }
}
