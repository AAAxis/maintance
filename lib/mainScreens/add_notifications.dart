import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddNotificationScreen extends StatefulWidget {
  @override
  _AddNotificationScreenState createState() => _AddNotificationScreenState();
}

class _AddNotificationScreenState extends State<AddNotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  Future<void> _addNotification() async {
    final String title = _titleController.text;
    final String message = _messageController.text;

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    await _firestore.collection('notifications').add({
      'title': title,
      'description': message,
      'timestamp': FieldValue.serverTimestamp(), // Use server timestamp
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notification added successfully')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Notification"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                prefixIcon: Icon(Icons.notifications), // Icon for title

              ),
            ),
            SizedBox(height: 16), // Space between text fields
            TextField(
              controller: _messageController,
              decoration: InputDecoration(
                labelText: 'Message',
                prefixIcon: Icon(Icons.message), // Icon for message

              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addNotification,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add), // Icon for the add button
                  SizedBox(width: 8), // Space between icon and text
                  Text('Add Notification'),
                ],
              ),
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
