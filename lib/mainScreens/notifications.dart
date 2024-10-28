import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/mainScreens/drawer.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications') // Replace with your notifications collection// Ensure notifications are ordered by time
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No notifications available."));
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              return ListTile(
                title: Text(notification['title'] ?? 'No Title'),
                subtitle: Text(notification['message'] ?? 'No Message'),
                trailing: Text(
                  notification['timestamp']?.toDate().toString() ?? '',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
