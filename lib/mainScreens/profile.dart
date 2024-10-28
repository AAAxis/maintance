import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser; // Get the current user

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users') // Replace with your users collection
            .doc(user?.uid) // Fetch user data using UID
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("User data not found."));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Name: ${userData['nickname'] ?? 'No Name'}", // Display nickname
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 10),
                Text(
                  "Email: ${userData['email'] ?? 'No Email'}", // Display email
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 20),
                Text(
                  "Phone: ${userData['phone'] ?? 'No Phone'}", // Display phone
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 20),
                Text(
                  "Building: ${userData['address'] ?? 'No Address'}", // Display address
                  style: TextStyle(fontSize: 20),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _removeAccount(context, user),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Remove Account",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Method to remove the user account
  Future<void> _removeAccount(BuildContext context, User? user) async {
    if (user != null) {
      try {
        // Delete user data from Firestore
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();

        // Delete user from Firebase Authentication
        await user.delete();

        // Show success message and navigate to the login screen or splash screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Account successfully removed.")),
        );

        // Optionally navigate to the login or splash screen
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
      } catch (e) {
        // Handle errors (e.g., user not found, or user cannot be deleted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }
}
