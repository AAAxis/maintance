import 'package:driver_app/authentication/email_login.dart';
import 'package:driver_app/authentication/hello.dart';
import 'package:driver_app/authentication/register_user.dart';
import 'package:driver_app/mainScreens/add_item.dart';
import 'package:driver_app/mainScreens/notifications.dart';
import 'package:driver_app/mainScreens/payment.dart';
import 'package:driver_app/mainScreens/profile.dart';
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
      MaterialPageRoute(builder: (context) => LoginScreen()),
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
            leading: const Icon(Icons.add_circle_outline, color: Colors.black),
            title: const Text(
              "Add User",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UserRegistrationScreen()),
              );
            },
          ),



          ListTile(
            leading: const Icon(Icons.task_alt_outlined, color: Colors.black),
            title: const Text(
              "Add Task",
              style: TextStyle(color: Colors.black),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AppointmentsPage()),
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
