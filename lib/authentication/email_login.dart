import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/mainScreens/navigation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({Key? key}) : super(key: key);

  @override
  _EmailLoginScreenState createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';

  Future<void> signInWithEmail() async {
    setState(() {
      errorMessage = '';
    });

    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        DocumentSnapshot userData = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userData.exists) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('uid', userCredential.user!.uid);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => NavigationScreen()),
          );
        } else {
          setState(() {
            errorMessage = tr("error_user_data_not_found");
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = tr("error_login_failed");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tr("welcome_back"),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: tr("email"),
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: tr("password"),
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: signInWithEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  tr("sign_in"),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    errorMessage,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () async {
                  const url = 'https://maintance-f744d.web.app/index.html'; // Replace with your actual link
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    // Handle the error if the URL can't be launched
                    setState(() {
                      errorMessage = tr("error_invalid_url");
                    });
                  }
                },
                child: Text(
                  tr("no_account_join_us"),
                  style: TextStyle(color: Colors.blue),
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
