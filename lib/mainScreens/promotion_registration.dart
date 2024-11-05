import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class PromotionRegistrationScreen extends StatefulWidget {
  @override
  _PromotionRegistrationScreenState createState() => _PromotionRegistrationScreenState();
}

class _PromotionRegistrationScreenState extends State<PromotionRegistrationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _linkController = TextEditingController(); // Controller for link
  DateTime? _selectedDate;

  Future<void> _createPromotion() async {
    final String title = _titleController.text;
    final String description = _descriptionController.text;
    final String link = _linkController.text;

    // Check if all fields are filled
    if (title.isEmpty || description.isEmpty || link.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Create a new promotion document in Firestore with the selected date and link
    await _firestore.collection('promotions').add({
      'title': title,
      'description': description,
      'link': link, // Store the link
      'date': _selectedDate,
    });

    // Show a success message and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Promotion created successfully')),
    );

    Navigator.pop(context);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create Promotion'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.title),
              ),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            TextField(
              controller: _linkController,
              decoration: InputDecoration(
                labelText: 'Link',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text('Selected Date: ${_selectedDate != null ? _selectedDate!.toLocal().toString().split(' ')[0] : 'No date selected'}'),
              trailing: IconButton(
                icon: Icon(Icons.calendar_today),
                onPressed: () => _selectDate(context),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createPromotion,
              child: Text('Add Promotion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
