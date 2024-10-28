import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuildingProgressScreen extends StatefulWidget {
  @override
  _BuildingProgressScreenState createState() => _BuildingProgressScreenState();
}

class _BuildingProgressScreenState extends State<BuildingProgressScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<Map<String, Map<String, dynamic>>> _streamBuildingData() async* {
    while (true) {
      Map<String, Map<String, dynamic>> buildingData = {};

      var buildingsSnapshot = await _firestore.collection('markers').get();
      for (var building in buildingsSnapshot.docs) {
        String buildingName = building['name'];
        String address = building['address'];
        int capacity = building['capacity'];
        String documentId = building.id;
        buildingData[buildingName] = {
          'address': address,
          'capacity': capacity,
          'paidUserCount': 0,
          'documentId': documentId,
        };
      }

      var usersSnapshot = await _firestore.collection('users').where('paid', isEqualTo: true).get();
      for (var user in usersSnapshot.docs) {
        String userAddress = user['address'];
        if (buildingData.containsKey(userAddress)) {
          buildingData[userAddress]!['paidUserCount'] += 1;
        }
      }

      yield buildingData;
      await Future.delayed(Duration(seconds: 5));
    }
  }

  Future<List<Map<String, dynamic>>> _fetchUsersForBuilding(String buildingName) async {
    var usersSnapshot = await _firestore.collection('users').where('address', isEqualTo: buildingName).get();
    return usersSnapshot.docs.map((doc) => {
      'id': doc.id,
      'nickname': doc['nickname'],
      'paid': doc['paid'],
    }).toList();
  }

  Future<void> _togglePaidStatus(List<String> userIds, bool newStatus) async {
    WriteBatch batch = _firestore.batch();
    for (String userId in userIds) {
      var userRef = _firestore.collection('users').doc(userId);
      batch.update(userRef, {'paid': newStatus});
    }
    await batch.commit();
  }

  Future<void> _deleteMark(String markId) async {
    await _firestore.collection('markers').doc(markId).delete();
  }

  Future<bool> _showConfirmationDialog(String buildingName, String documentId) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the building "$buildingName" from Firebase?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _deleteMark(documentId);
                Navigator.of(context).pop(true);
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    ).then((value) => value ?? false);
  }

  void _showUsersBottomSheet(String buildingName) async {
    List<Map<String, dynamic>> users = await _fetchUsersForBuilding(buildingName);
    List<String> selectedUserIds = users.where((user) => user['paid']).map((user) => user['id'] as String).toList();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Users in $buildingName', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        var user = users[index];
                        return CheckboxListTile(
                          title: Text(user['nickname'], style: TextStyle(fontSize: 16)),
                          value: selectedUserIds.contains(user['id']),
                          onChanged: (isChecked) {
                            setState(() {
                              if (isChecked == true) {
                                selectedUserIds.add(user['id']);
                              } else {
                                selectedUserIds.remove(user['id']);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      if (selectedUserIds.isNotEmpty) {
                        await _togglePaidStatus(selectedUserIds, true);
                      }
                      List<String> allUserIds = users.map((user) => user['id'] as String).toList();
                      List<String> uncheckedUserIds = allUserIds.where((id) => !selectedUserIds.contains(id)).toList();
                      if (uncheckedUserIds.isNotEmpty) {
                        await _togglePaidStatus(uncheckedUserIds, false);
                      }
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black, side: BorderSide(color: Colors.black), // Text color
                    ),
                    child: Text('Submit Changes'),
                  ),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buildings list')),
      body: StreamBuilder<Map<String, Map<String, dynamic>>>(
        stream: _streamBuildingData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return Center(child: Text('No data available.'));
          }

          final buildingData = snapshot.data!;

          return ListView.builder(
            itemCount: buildingData.length,
            itemBuilder: (context, index) {
              String buildingName = buildingData.keys.elementAt(index);
              var data = buildingData[buildingName]!;

              int capacity = data['capacity'];
              int paidUserCount = data['paidUserCount'];
              double percentagePaid = capacity > 0 ? (paidUserCount / capacity) * 100 : 0;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4,
                child: Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.business, color: Colors.black), // Leading icon
                      title: Text(
                        buildingName,
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['address'],
                            style: TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Capacity: ${data['capacity']} - Paid Users: ${data['paidUserCount']}',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.black),
                        onPressed: () async {
                          bool confirmed = await _showConfirmationDialog(buildingName, data['documentId']);
                          if (confirmed) {
                            // Handle deletion success if needed
                          }
                        },
                      ),
                      onTap: () => _showUsersBottomSheet(buildingName),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          LinearProgressIndicator(
                            value: percentagePaid / 100, // Convert percentage to a value between 0.0 and 1.0
                            backgroundColor: Colors.grey[300],
                            color: Colors.blue,
                          ),
                          SizedBox(height: 8),

                          Text(
                            'Progress: ${percentagePaid.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 16),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

}
