import 'dart:async';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:driver_app/authentication/phone_verification.dart';
import 'package:driver_app/mainScreens/dashboard.dart';
import 'package:driver_app/mainScreens/navigation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MySplashScreen extends StatefulWidget {
  const MySplashScreen({Key? key}) : super(key: key);

  @override
  State<MySplashScreen> createState() => _MySplashScreenState();
}

class _MySplashScreenState extends State<MySplashScreen> {



  Future<void> _requestPermissionManually() async {
    final trackingStatus = await AppTrackingTransparency.requestTrackingAuthorization();
    print('Manual tracking permission request status: $trackingStatus');

    final prefs = await SharedPreferences.getInstance();

    if (trackingStatus == TrackingStatus.authorized) {
      // User granted permission
      await prefs.setBool('trackingPermissionStatus', true);
    } else {
      // User denied permission or not determined, store it as false
      await prefs.setBool('trackingPermissionStatus', false);
    }
  }

  @override
  void initState() {
    super.initState();
    _checkCurrentUser(context);
  }

  void _checkCurrentUser(BuildContext context) {
    Timer(Duration(seconds: 3), () async {
      // Check if the user is authenticated
      User? user = FirebaseAuth.instance.currentUser;

      // Fetch phone number from local storage
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? storedPhone = prefs.getString('phone');

      if (user != null) {
        // User is authenticated, navigate to the main screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavigationScreen()),
        );
      } else if (storedPhone != null) {
        // User is not authenticated but has phone stored, navigate to Limited screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeTenantScreen()),
        );
      } else {
        // User is not authenticated and no phone stored, navigate to login screen
        _requestPermissionManually();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PhoneVerificationScreen()),
        );
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (_) {
        // Handle vertical swipe to continue
        _requestPermissionManually();
      },
      child: Material(
        child: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10), // Optional: Round image corners
                  child: SizedBox(

                    child: Image.asset(
                      "images/background.jpeg",
                      fit: BoxFit.cover, // Covers the entire box
                    ),
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}