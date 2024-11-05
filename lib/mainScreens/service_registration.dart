import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceRegistrationScreen extends StatefulWidget {
  @override
  _ServiceRegistrationScreenState createState() => _ServiceRegistrationScreenState();
}

class _ServiceRegistrationScreenState extends State<ServiceRegistrationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _linkController = TextEditingController(); // Controller for the link field

  Future<void> _createService() async {
    final String name = _nameController.text;
    final String priceString = _priceController.text;
    final String link = _linkController.text;

    if (name.isEmpty || priceString.isEmpty || link.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    double price = double.tryParse(priceString) ?? 0;

    await _firestore.collection('services').add({
      'title': name,
      'price': price,
      'link': link, // Store the link field
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Service created successfully')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Service'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.label), // Icon for Name field
              ),
            ),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price',
                prefixIcon: Icon(Icons.attach_money), // Icon for Price field
              ),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                labelText: 'Link',
                prefixIcon: Icon(Icons.link), // Icon for Link field
              ),
              keyboardType: TextInputType.url,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createService,
              child: Text('Add Service'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Set button color
                foregroundColor: Colors.white, // Set text color
              ),
            ),
          ],
        ),
      ),
    );
  }
}
