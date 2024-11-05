import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/authentication/phone_verification.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _sharableLinkController = TextEditingController();


  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      _nicknameController.text = userData['nickname'] ?? '';
      _emailController.text = userData['email'] ?? '';
      _phoneController.text = userData['phone'] ?? '';
      _addressController.text = userData['address'] ?? '';
      _sharableLinkController.text = userData['sharableLink'] ?? '';
    }
  }


  Future<void> _updateProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'nickname': _nicknameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'sharableLink': _sharableLinkController.text,
        });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile updated successfully.")),
      );
    }
  }

  final String _url = "https://maintance-f744d.web.app/delete.html"; // Replace with your actual URL

  void _openWebLink(BuildContext context) async {
    if (await canLaunch(_url)) {
      await launch(_url);
    } else {
      // Handle the error if the link can't be opened
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not launch $_url")),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(labelText: "Name"),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: "Phone"),
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _sharableLinkController,
                decoration: InputDecoration(labelText: "Sharable Link"),
              ),
              SizedBox(height: 20),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _updateProfile();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: Text("Save", style: TextStyle(color: Colors.white)),
                      ),
                      SizedBox(width: 10),
           OutlinedButton(
          onPressed: () => _openWebLink(context),
    style: OutlinedButton.styleFrom(
    side: BorderSide(color: Colors.red),
    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
    ),
    child: Text("Delete Account", style: TextStyle(color: Colors.red)),
    ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
