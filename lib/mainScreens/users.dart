import 'package:driver_app/authentication/tenant_creation.dart';
import 'package:driver_app/mainScreens/drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class UsersScreen extends StatefulWidget {
  @override
  _UsersScreenState createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<User> _allUsers = [];
  List<User> _filteredUsers = [];
  List<String> _buildings = [];
  String _selectedBuilding = 'All'; // Dropdown value for buildings

  Future<void> _fetchUsers() async {
    List<User> userList = [];
    var usersSnapshot = await _firestore.collection('phone').get();

    for (var userDoc in usersSnapshot.docs) {
      userList.add(User(
        id: userDoc.id,
        nickname: userDoc['nickname'],
        building: userDoc['building'],
        phone: userDoc['phone'],
      ));
    }
    setState(() {
      _allUsers = userList;
      _filteredUsers = userList; // Initially, all users are filtered
    });
  }

  Future<void> _fetchBuildings() async {
    var buildingsSnapshot = await _firestore.collection('markers').get();
    List<String> buildingList = ['All']; // Initialize with "All"

    for (var buildingDoc in buildingsSnapshot.docs) {
      buildingList.add(buildingDoc['name']); // Assuming building documents have a 'name' field
    }
    setState(() {
      _buildings = buildingList; // Populate the buildings dropdown
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _fetchBuildings(); // Fetch buildings when the widget is initialized
  }

  void _filterUsers(String query) {
    setState(() {
      String searchQuery = query.toLowerCase();
      _filteredUsers = _allUsers
          .where((user) =>
      user.nickname.toLowerCase().contains(searchQuery) &&
          (_selectedBuilding == 'All' || user.building == _selectedBuilding))
          .toList();
    });
  }

  void _filterByBuilding(String? building) {
    setState(() {
      _selectedBuilding = building ?? 'All'; // Update selected building
      _filteredUsers = _allUsers
          .where((user) =>
      (_selectedBuilding == 'All' || user.building == _selectedBuilding))
          .toList();
    });
  }

  Future<void> _editUser(User user) async {
    final TextEditingController nicknameController =
    TextEditingController(text: user.nickname);
    final TextEditingController buildingController =
    TextEditingController(text: user.building);
    final TextEditingController phoneController =
    TextEditingController(text: user.phone);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nicknameController,
                decoration: InputDecoration(labelText: 'Nickname'),
              ),
              TextField(
                controller: buildingController,
                decoration: InputDecoration(labelText: 'Building'),
              ),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Phone'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _firestore.collection('phone').doc(user.id).update({
                  'nickname': nicknameController.text,
                  'building': buildingController.text,
                  'phone': phoneController.text,
                });
                Navigator.pop(context);
                _fetchUsers(); // Refresh the user list
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteUser(String userId) async {
    await _firestore.collection('phone').doc(userId).delete();
  }

  Future<void> _addUser() async {
    // Navigate to Add User Screen
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TenantRegistrationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenants'),
      ),
      drawer: CustomDrawer(),
      body: Column(
        children: [
          // Building dropdown
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedBuilding,
              onChanged: _filterByBuilding,
              items: _buildings.map((String building) {
                return DropdownMenuItem<String>(
                  value: building,
                  child: Text(building),
                );
              }).toList(),
            ),
          ),
          // Search field


          Expanded(
            child: ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                User user = _filteredUsers[index];
                return Dismissible(
                  key: Key(user.id),
                  background: Container(color: Colors.red),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Confirm Deletion'),
                          content: Text('Are you sure you want to delete ${user.nickname}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                _deleteUser(user.id);
                                Navigator.of(context).pop(true);
                              },
                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${user.nickname} deleted')),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 4,
                    child: ListTile(
                      leading: Icon(Icons.person, color: Colors.black), // Leading icon
                      title: Text(user.nickname),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Building: ${user.building}'),
                          Text('Phone: ${user.phone}'),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.black), // Pen icon for edit
                        onPressed: () => _editUser(user), // Open edit dialog on tap
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addUser,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue, // Set the background color
      ),
    );
  }
}
