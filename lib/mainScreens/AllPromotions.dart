import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

class AllPromotionsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("all_promotions".tr()), // Translated title
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAllPromotions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("error".tr(args: [snapshot.error.toString()]))); // Translated error message
          }

          final promotions = snapshot.data ?? [];
          if (promotions.isEmpty) {
            return Center(child: Text("no_promotions".tr())); // Translated no promotions message
          }

          return ListView.builder(
            itemCount: promotions.length,
            itemBuilder: (context, index) {
              final item = promotions[index];
              final link = item['link'] as String?;

              return ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                leading: Icon(Icons.local_offer, color: Colors.black), // Leading icon
                title: Text(
                  item['title'] ?? 'unnamed_promotion'.tr(), // Translated unnamed promotion
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  item['description'] ?? 'no_details'.tr(), // Translated no details
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                onTap: () {
                  if (link != null && link.isNotEmpty) {
                    _openLink(link);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('no_link_available'.tr())), // Translated no link available message
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

  Future<List<Map<String, dynamic>>> _fetchAllPromotions() async {
    final promotionsSnapshot = await FirebaseFirestore.instance.collection('promotions').get();
    return promotionsSnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  void _openLink(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
