import 'package:driver_app/authentication/email_login.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRegistrationScreen extends StatefulWidget {
  @override
  _UserRegistrationScreenState createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _selectedAddress; // To hold the selected address
  List<String> _addressList = []; // To store fetched address list

  // Method to fetch address list from Firestore
  Future<void> _fetchAddressList() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('markers').get();
    setState(() {
      _addressList = snapshot.docs.map((doc) => doc['name'] as String).toList();
      if (_addressList.isNotEmpty) {
        _selectedAddress = _addressList[0]; // Preselect the first address
      }
    });
  }

  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String uid = userCredential.user!.uid;

        CollectionReference users = FirebaseFirestore.instance.collection('users');
        await users.doc(uid).set({
          'nickname': _nameController.text.trim(),
          'address': _selectedAddress, // Store the selected address
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'created_at': FieldValue.serverTimestamp(),
          'paid': false
        });

        // Clear the text fields after successful registration
        _nameController.clear();
        _emailController.clear();
        _phoneController.clear();
        _passwordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User added successfully to Firestore and Auth!')),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => EmailLoginScreen()),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchAddressList(); // Fetch addresses when the widget is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add User'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              // Dropdown to select address
              DropdownButtonFormField<String>(
                value: _selectedAddress,
                decoration: InputDecoration(
                  labelText: 'Select Building',
                  border: OutlineInputBorder(),
                ),
                items: _addressList.map((address) {
                  return DropdownMenuItem(
                    value: address,
                    child: Text(address),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAddress = value; // Update the selected address
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select an address';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _registerUser,
                icon: Icon(Icons.add, color: Colors.white),
                label: Text('Add', style: TextStyle(fontSize: 18, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
