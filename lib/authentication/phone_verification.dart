import 'package:driver_app/authentication/email_login.dart';
import 'package:driver_app/mainScreens/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart'; // Import for localization

class PhoneVerificationScreen extends StatefulWidget {
  @override
  _PhoneVerificationScreenState createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _phoneController = TextEditingController(text: '+972'); // Prefill with +972
  final _codeController = TextEditingController();
  late String _verificationCode; // Verification code received from the API
  bool _isLoading = false;
  bool _isCodeSent = false;

  Future<void> _sendVerification() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a phone number".tr())),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Query Firestore to find the document with the matching phone number
      final querySnapshot = await FirebaseFirestore.instance
          .collection('phone')
          .where('phone', isEqualTo: phone)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Phone number not found".tr())),
        );
        return;
      }

      // Retrieve email, nickname, and building from the document
      final doc = querySnapshot.docs.first;
      final email = doc.get('email');
      final nickname = doc.get('nickname');
      final building = doc.get('building');

      // Send the email to your API
      final response = await http.get(
        Uri.parse('https://polskoydm.pythonanywhere.com/global_auth?email=$email'),
      );

      if (response.statusCode == 200) {
        // Parse the verification code from the response
        final responseData = json.decode(response.body);
        _verificationCode = responseData['verification_code'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification email sent".tr())),
        );
        setState(() {
          _isCodeSent = true; // Code has been sent, show code input field
        });

        // Store the nickname and building in local storage
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('nickname', nickname); // Store nickname
        await prefs.setString('building', building); // Store building
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to send verification email".tr())),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $e".tr())),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _verifyCode() async {
    String verificationCode = _codeController.text.trim();

    print("Entered verification code: $verificationCode");

    if (verificationCode == _verificationCode) {
      // Store the phone number in local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('phone', _phoneController.text); // Store the entered phone number

      // Navigate to the home screen if the code matches
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeTenantScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid verification code".tr())),
      );
    }
  }

  void _navigateToBusinessLogin() {
    // Navigate to Business Login screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EmailLoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Authentication".tr()),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Phone Number Input Field
              if (!_isCodeSent) ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "Phone Number".tr(),
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
              ] else ...[
                Text(
                  "${_phoneController.text}".tr(),
                  style: TextStyle(fontSize: 16),
                ),
              ],
              SizedBox(height: 24.0),

              // Send Button
              if (!_isCodeSent) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendVerification,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                        : Text("Send".tr()),
                  ),
                ),
              ],

              // Verification Code Field
              if (_isCodeSent) ...[
                SizedBox(height: 10.0),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Enter Code".tr(),
                    border: OutlineInputBorder(),
                    filled: true,
                  ),
                ),
                SizedBox(height: 16.0),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _verifyCode,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text("Verify".tr()),
                  ),
                ),
              ],

              // Links for Business Login
              SizedBox(height: 24.0),
              TextButton(
                onPressed: _navigateToBusinessLogin,
                child: Text(
                  "Login as Property Manager".tr(),
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
