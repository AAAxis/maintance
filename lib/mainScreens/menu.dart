import 'package:driver_app/authentication/phone_verification.dart';
import 'package:driver_app/mainScreens/AllTask.dart';
import 'package:driver_app/mainScreens/add_task.dart';
import 'package:driver_app/mainScreens/cardData.dart';
import 'package:driver_app/mainScreens/share.dart';
import 'package:driver_app/mainScreens/tenants.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class MenuDrawer extends StatelessWidget {
  MenuDrawer();

  Future<Map<String, String?>> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final nickname = prefs.getString('nickname');
    final phone = prefs.getString('phone');
    final building = prefs.getString('building');

    return {
      'nickname': nickname,
      'phone': phone,
      'building': building,
    };
  }

  Future<void> signOutAndClearPrefs(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => PhoneVerificationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<Map<String, String?>>(
        future: _loadUserData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data!;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Colors.blue),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userData['nickname'] ?? tr('nickname_not_available'),
                      style: TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    SizedBox(height: 8),
                    Text(
                      userData['phone'] ?? tr('phone_not_available'),
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text(
                      userData['building'] ?? tr('building_not_available'),
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),

              ListTile(
                leading: const Icon(Icons.task_alt, color: Colors.black),
                title: Text(
                  tr('add_tasks'),
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  // Replace 'YourServiceTypeHere' with the actual service type you want to pass
                  String serviceType = 'basic'; // Assign the appropriate service type
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AppointmentsPage(serviceType: serviceType)),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.black),
                title: Text(
                  tr('payment'),
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PaymentScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.people_alt_outlined, color: Colors.black),
                title: Text(
                  tr('tenants'),
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => UsersTenantScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.black),
                title: Text(
                  tr('share'),
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SharePage()),
                  );
                },
              ),
              const Divider(
                height: 10,
                color: Colors.grey,
                thickness: 2,
              ),
              ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.black),
                title: Text(
                  tr('sign_out'),
                  style: TextStyle(color: Colors.black),
                ),
                onTap: () {
                  signOutAndClearPrefs(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
