import 'package:driver_app/authentication/phone_verification.dart';
import 'package:driver_app/mainScreens/buildings.dart';
import 'package:driver_app/mainScreens/notifications.dart';
import 'package:driver_app/mainScreens/payments.dart';
import 'package:driver_app/mainScreens/profile.dart';
import 'package:driver_app/mainScreens/promotion_screen.dart';
import 'package:driver_app/mainScreens/services_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomDrawer extends StatelessWidget {
  CustomDrawer();

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
    // Get the current user
    final User? user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user?.email != null)
                  Text(
                    user!.email!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline_outlined, color: Colors.black),
            title: const Text(
              "Profile",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.credit_card, color: Colors.black),
            title: const Text(
              "Payments",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PaymentRecordsScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.sailing, color: Colors.black),
            title: const Text(
              "Promotions",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PromotionsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_laundry_service, color: Colors.black),
            title: const Text(
              "Services",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ServicesScreen()),
              );
            },
          ),


          ListTile(
            leading: const Icon(Icons.notifications_none_rounded, color: Colors.black),
            title: const Text(
              "Notifications",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotificationsScreen()),
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
            title: const Text(
              "Sign Out",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              signOutAndClearPrefs(context);
            },
          ),
        ],
      ),
    );
  }
}
