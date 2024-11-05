import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class AllNotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("all_notifications".tr()), // Translated title
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('notifications').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("error".tr(args: [snapshot.error.toString()]))); // Translated error message
          }

          final notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return Center(child: Text("no_notifications".tr())); // Translated no notifications message
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: Icon(Icons.notifications), // Notification icon
                title: Text(notification['title'] ?? 'no_title'.tr()), // Translated title
                subtitle: Text(notification['description'] ?? 'no_message'.tr()), // Translated message
              );
            },
          );
        },
      ),
    );
  }
}
