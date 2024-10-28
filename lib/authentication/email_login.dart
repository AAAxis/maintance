import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/authentication/register_user.dart';
import 'package:driver_app/mainScreens/navigation.dart'; // Update with your navigation screen// Update with your registration screen
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

final FirebaseAuth _auth = FirebaseAuth.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestore instance

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({Key? key}) : super(key: key);

  @override
  _EmailLoginScreenState createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String errorMessage = '';

  // Method to handle user login with Firebase Authentication
  Future<void> signInWithEmail() async {
    setState(() {
      errorMessage = ''; // Reset error message
    });

    try {
      // Attempt to sign in user with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // Check if the user is successfully logged in
      if (userCredential.user != null) {
        // Fetch additional user data if needed from Firestore
        DocumentSnapshot userData = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (userData.exists) {
          // Navigate to the main navigation screen after successful login
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => NavigationScreen()), // Update with your actual navigation screen
          );
        } else {
          setState(() {
            errorMessage = "User data not found.";
          });
        }
      }
    } catch (e) {
      // Display error message if login fails
      setState(() {
        errorMessage = 'Login failed. Please check your email and password.';
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
                "Welcome Back!",
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
                  labelText: "Email",
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
                  labelText: "Password",
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
                  "Sign In",
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
              // Link to registration screen
              TextButton(
                onPressed: () {
                  // Navigate to the registration screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UserRegistrationScreen()), // Update with your actual registration screen
                  );
                },
                child: Text(
                  "Don't have an account? Register here",
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
