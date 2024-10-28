import 'dart:io'; // For platform detection
import 'package:driver_app/authentication/email_login.dart';
import 'package:driver_app/mainScreens/navigation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore to store user data
import 'package:the_apple_sign_in/the_apple_sign_in.dart'; // Apple Sign-In package

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _businessNameController = TextEditingController();

  String? businessName;
  String? errorMessage;
  String? selectedBuildingName;

  List<String> buildingNames = []; // List to hold building names

  @override
  void initState() {
    super.initState();
    fetchBuildingNames(); // Fetch buildings when the screen initializes
  }

  Future<void> fetchBuildingNames() async {
    try {
      // Fetch the buildings from Firestore
      QuerySnapshot snapshot = await _firestore.collection('markers').get();
      List<String> names = [];
      for (var doc in snapshot.docs) {
        names.add(doc['name']);
      }
      setState(() {
        buildingNames = names; // Update the state with the fetched building names
      });
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load buildings: $e";
      });
    }
  }

  Future<void> checkAndRegisterUser(User? user) async {
    if (user != null) {
      // Check if the user document already exists in Firestore
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // If the user document does not exist, prompt for business name and building selection
        promptForBusinessName();
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavigationScreen()),
        );
        // Optionally, you can handle the case where the user is already registered
        setState(() {
          errorMessage = "User is already registered."; // Notify user if needed
        });
      }
    }
  }



  Future<void> promptForBusinessName() async {
    // Preselect "Barber Shop" and initialize a disabled submit button
    setState(() {
      selectedBuildingName = buildingNames.isNotEmpty ? buildingNames[0] : null;
    });

    bool isSubmitEnabled = false;
    String? phoneNumber;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Data"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _businessNameController,
                    decoration: InputDecoration(hintText: "Enter Name"),
                    onChanged: (value) {
                      setState(() {
                        isSubmitEnabled = value.trim().length >= 3 && (phoneNumber?.trim().length ?? 0) >= 10;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(hintText: "Enter Phone"),
                    onChanged: (value) {
                      setState(() {
                        phoneNumber = value; // Store the phone number
                        isSubmitEnabled = _businessNameController.text.trim().length >= 3 && phoneNumber!.trim().length >= 10;
                      });
                    },
                  ),
                  SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: selectedBuildingName,
                    hint: Text("Select Building"),
                    items: buildingNames.map((String buildingName) {
                      return DropdownMenuItem<String>(
                        value: buildingName,
                        child: Text(buildingName),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        selectedBuildingName = newValue;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitEnabled
                      ? () {
                    setState(() {
                      businessName = _businessNameController.text.trim();
                    });
                    Navigator.of(context).pop();
                    registerUser(phoneNumber); // Pass the phone number here
                  }
                      : null, // Disable the button if conditions are not met
                  child: Text("Submit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> registerUser(String? phoneNumber) async {
    if (businessName != null && selectedBuildingName != null) {
      try {
        User? user = _auth.currentUser;

        // Check if the user document already exists
        DocumentSnapshot userDoc = await _firestore.collection('users').doc(user?.uid).get();

        // Proceed with registration only if the document does not exist
        if (!userDoc.exists) {
          // Prepare user data
          await _firestore.collection('users').doc(user?.uid).set({
            'nickname': businessName,
            'address': selectedBuildingName,
            'phone': phoneNumber, // Add phone number to Firestore
            'email': user?.email, // Add the user's email
            'created_at': FieldValue.serverTimestamp(), // Set created_at to server timestamp
            'paid': false, // Set paid to true
            // Add any other user details you need
          });

          // Navigate to the next screen after successful registration
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => NavigationScreen()),
          );
        } else {
          setState(() {
            errorMessage = "User already registered."; // Notify that user already exists
          });
        }
      } catch (e) {
        setState(() {
          errorMessage = "Failed to register user: $e";
        });
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      await checkAndRegisterUser(userCredential.user); // This method should also call promptForBusinessName()
    } catch (e) {
      setState(() {
        errorMessage = "Google Sign-in failed: $e";
      });
    }
  }

  Future<void> signInWithApple() async {
    try {
      if (await TheAppleSignIn.isAvailable()) {
        final AuthorizationResult result = await TheAppleSignIn.performRequests(
            [AppleIdRequest(requestedScopes: [Scope.email, Scope.fullName])]
        );

        switch (result.status) {
          case AuthorizationStatus.authorized:
            final appleCredential = result.credential!;
            OAuthProvider oAuthProvider = OAuthProvider("apple.com");
            final credential = oAuthProvider.credential(
              idToken: String.fromCharCodes(appleCredential.identityToken!),
              accessToken: String.fromCharCodes(appleCredential.authorizationCode!),
            );

            UserCredential userCredential = await _auth.signInWithCredential(credential);
            await checkAndRegisterUser(userCredential.user); // This method should also call promptForBusinessName()
            break;
          case AuthorizationStatus.error:
            setState(() {
              errorMessage = "Apple Sign-in failed.";
            });
            break;
          case AuthorizationStatus.cancelled:
            print("User cancelled Apple Sign-In");
            break;
        }
      } else {
        setState(() {
          errorMessage = "Apple Sign-In is not available on this device.";
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Apple Sign-In failed: $e";
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'images/background.jpeg',

            ),
          ),

          if (errorMessage != null)
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Text(
                errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),

          Positioned(
            bottom: 60,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (Platform.isAndroid)
                  ElevatedButton.icon(
                    onPressed: signInWithGoogle,
                    icon: Icon(Icons.login, color: Colors.white),
                    label: Text("Sign in with Google",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),

                SizedBox(height: 10),

                if (Platform.isIOS)
                  ElevatedButton.icon(
                    onPressed: signInWithApple,
                    icon: Icon(Icons.apple, color: Colors.white),
                    label: Text("Sign in with Apple",
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),

                SizedBox(height: 10),

                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EmailLoginScreen()),
                    );
                  },
                  icon: Icon(Icons.email, color: Colors.white),
                  label: Text("Sign in with Email",
                      style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
