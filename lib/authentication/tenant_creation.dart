import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TenantRegistrationScreen extends StatefulWidget {
  @override
  _TenantRegistrationScreenState createState() => _TenantRegistrationScreenState();
}

class _TenantRegistrationScreenState extends State<TenantRegistrationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _selectedBuilding;
  List<String> _buildings = [];

  @override
  void initState() {
    super.initState();
    _fetchBuildings();
  }

  Future<void> _fetchBuildings() async {
    try {
      // Fetch building data from Firestore
      var buildingsSnapshot = await _firestore.collection('markers').get();
      List<String> buildingsList = [];

      for (var buildingDoc in buildingsSnapshot.docs) {
        buildingsList.add(buildingDoc['name']); // Assuming 'name' is the field containing the building name
      }

      setState(() {
        _buildings = buildingsList;
      });
    } catch (e) {
      print('Error fetching buildings: $e');
    }
  }

  Future<void> _createUser() async {
    final String nickname = _nicknameController.text;
    final String building = _selectedBuilding ?? ''; // Use the selected building
    final String phone = _phoneController.text;
    final String email = _emailController.text;

    // Check if all fields are filled
    if (nickname.isEmpty || building.isEmpty || phone.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Create a new user document in Firestore
    await _firestore.collection('phone').add({
      'nickname': nickname,
      'building': building,
      'phone': phone,
      'email': email,
    });

    // Show a success message and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tenant created successfully')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Tenant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nicknameController,
              decoration: InputDecoration(
                labelText: 'Nickname',
                prefixIcon: Icon(Icons.person), // Icon for nickname
              ),
            ),
            DropdownButtonFormField<String>(
              value: _selectedBuilding,
              decoration: InputDecoration(
                labelText: 'Building',
                prefixIcon: Icon(Icons.apartment), // Icon for building
              ),
              items: _buildings.map((String building) {
                return DropdownMenuItem<String>(
                  value: building,
                  child: Text(building),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedBuilding = newValue; // Update the selected building
                });
              },
              isExpanded: true,
            ),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone',
                prefixIcon: Icon(Icons.phone), // Icon for phone
              ),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email), // Icon for email
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createUser,
              child: Text('Add Tenant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Set button color
                foregroundColor: Colors.white, // Set text color to white
              ),
            ),

          ],
        ),
      ),
    );
  }
}
