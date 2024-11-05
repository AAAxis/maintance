import 'package:driver_app/authentication/tenant_creation.dart';
import 'package:driver_app/mainScreens/drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class User {
  final String id;
  final String nickname;
  final String building;
  final String phone;

  User({
    required this.id,
    required this.nickname,
    required this.building,
    required this.phone,
  });
}

class UsersTenantScreen extends StatefulWidget {
  @override
  _UsersTenantScreenState createState() => _UsersTenantScreenState();
}

class _UsersTenantScreenState extends State<UsersTenantScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<User> _filteredUsers = [];

  Future<void> _fetchUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedBuilding = prefs.getString('building');

    List<User> userList = [];
    var usersSnapshot = await _firestore.collection('phone').get();

    for (var userDoc in usersSnapshot.docs) {
      User user = User(
        id: userDoc.id,
        nickname: userDoc['nickname'],
        building: userDoc['building'],
        phone: userDoc['phone'],
      );

      if (storedBuilding == null || user.building == storedBuilding) {
        userList.add(user);
      }
    }

    setState(() {
      _filteredUsers = userList;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('tenants')),
      ),
      body: ListView.builder(
        itemCount: _filteredUsers.length,
        itemBuilder: (context, index) {
          User user = _filteredUsers[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            elevation: 4,
            child: ListTile(
              leading: Icon(Icons.person, color: Colors.black),
              title: Text(user.nickname),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${tr('building')}: ${user.building}'),
                  Text('${tr('phone')}: ${user.phone}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
