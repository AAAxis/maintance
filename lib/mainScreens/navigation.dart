
import 'package:driver_app/authentication/email_login.dart';
import 'package:driver_app/mainScreens/buildings.dart';
import 'package:driver_app/mainScreens/tasks.dart';
import 'package:driver_app/mainScreens/users.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NavigationScreen extends StatefulWidget {
  @override
  _NavigationScreenState createState() => _NavigationScreenState();
}

class _NavigationScreenState extends State<NavigationScreen> {
  int _currentIndex = 1;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> signOutAndClearPrefs(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => EmailLoginScreen()),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          BuildingProgressScreen(),
          TasksScreen(),
          UsersScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),




          BottomNavigationBarItem(
            icon: Icon(Icons.task_alt_outlined),
            label: 'My Tasks',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt_outlined),
            label: 'My Tenants',
          ),



        ],
      ),
    );
  }
}