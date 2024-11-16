import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:kursova/pages/main_page.dart';


class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Стан для видимості пароля
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 24.0),
              const Center(
                child: Text(
                  'Sign up',
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24.0),
              // Name field
              TextFormField(
                controller: _nameController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Заповніть поле 'Name'";
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Name:',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
              const SizedBox(height: 16.0),
              // Email field
              TextFormField(
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Заповніть поле 'Email'";
                  }
                  final emailRegExp = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegExp.hasMatch(value)) {
                    return "Введіть коректну електронну адресу";
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Email:',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
              const SizedBox(height: 16.0),
              // Password field with show/hide functionality
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword, // Це визначає видимість пароля
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Заповніть поле 'Password'";
                  }
                  if (value.length < 7) {
                    return "Пароль має містити принаймні 7 символів";
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Password:',
                  border: const OutlineInputBorder(),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility // Іконка для приховування
                          : Icons.visibility_off, // Іконка для показу
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              // Sign up button
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState?.validate() == true) {
                          try {
                            // Реєстрація користувача
                            UserCredential userCredential = await FirebaseAuth.instance
                                .createUserWithEmailAndPassword(
                              email: _emailController.text,
                              password: _passwordController.text,
                            );

                            // Додавання додаткових даних у Firestore
                            await FirebaseFirestore.instance.collection('users').doc(userCredential.user?.uid).set({
                              'name': _nameController.text,
                              'email': _emailController.text,
                              'password': _passwordController.text,
                              'created_at': FieldValue.serverTimestamp(),
                            });

                            // Показати повідомлення про успішну реєстрацію
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sign up successfully!')),
                            );

                            // Переходимо на головний екран після затримки
                            Future.delayed(const Duration(seconds: 2), () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (context) => ExpensesListScreen()), // Заміна на ваш головний екран
                              );
                            });
                          } catch (e) {
                            // Помилка при реєстрації
                            showDialog(
                              context: context,
                              builder: (BuildContext ctx) {
                                return AlertDialog(
                                  title: const Text('Error'),
                                  content: Text(e.toString()),
                                );
                              },
                            );
                          }
                        }
                      },
                    child: const Text("Sign up"),
                  ),
                ),
              ),
              const SizedBox(height: 16.0),
              // Back button
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);  // Повернення назад до сторінки входу
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                    ),
                    child: const Text("Back"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
