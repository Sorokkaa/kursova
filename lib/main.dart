import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:kursova/pages/sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Облік витрат',
      home: SignInScreen(),
    );
  }
}