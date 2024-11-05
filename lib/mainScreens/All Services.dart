import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

class AllServicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("all_services".tr()), // Translated title
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('services').get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("error".tr(args: [snapshot.error.toString()])));
          }

          final services = snapshot.data!.docs;

          if (services.isEmpty) {
            return Center(child: Text("no_services".tr())); // Translated no services message
          }

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index].data() as Map<String, dynamic>;
              final link = service['link'] as String?;

              return ListTile(
                leading: Icon(Icons.cleaning_services_outlined),
                title: Text(service['title'] ?? 'unnamed_service'.tr()), // Translated service title
                subtitle: Text(service['description'] != null ? '${service['description']}' : 'no_price'.tr()), // Translated price
                onTap: () {
                  if (link != null && link.isNotEmpty) {
                    _openLink(link);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('no_link'.tr())), // Translated no link message
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  void _openLink(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'could_not_launch'.tr(args: [url]); // Translated error message for URL launch failure
    }
  }
}
