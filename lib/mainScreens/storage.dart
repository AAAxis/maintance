import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:driver_app/mainScreens/drawer.dart';
import 'package:driver_app/mainScreens/edit_item.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';




class Item {
  final String id;
  final String status;
  final String type;
  final String description;
  final String purchaseDate;

  Item({
    required this.id,
    required this.status,
    required this.type,
    required this.description,
    required this.purchaseDate,
  });
}




// New screen for displaying  and Broken items with additional tabs
class StorageBrokenItemsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Tasks'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Orders'),
              Tab(text: 'Users'),

            ],
          ),
        ),
        drawer: CustomDrawer(),
        body: TabBarView(
          children: [
            _StorageTab(), // Storage tab with nested tabs
            Center(child: AssignedItemsScreen()), // Placeholder for Assigned view

          ],
        ),
      ),
    );
  }
}


class AssignedItemsScreen extends StatefulWidget {
  @override
  _AssignedItemsScreenState createState() => _AssignedItemsScreenState();
}

class _AssignedItemsScreenState extends State<AssignedItemsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: // Ensure you call setState when the search query changes
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by Name ...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                  print("Search Query: $_searchQuery"); // Debug statement
                });
              },

            )

          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!userSnapshot.hasData || userSnapshot.data!.docs.isEmpty) {
                  return Center(child: Text('No users found.'));
                }

                final users = userSnapshot.data!.docs
                    .where((userDoc) {
                  final userName = userDoc['nickname'].toString().toLowerCase();
                  return userName.contains(_searchQuery);
                })
                    .toList();

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final userId = userDoc.id;
                    final userName = userDoc['nickname'];
                    final userPhone = userDoc['phone'];

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('orders')
                          .where('assignedTo', isEqualTo: userId)
                          .snapshots(),
                      builder: (context, itemSnapshot) {
                        if (itemSnapshot.connectionState == ConnectionState.waiting) {
                          return ListTile(
                            leading: Icon(Icons.person),
                            title: Text(userName),
                          );
                        }

                        if (!itemSnapshot.hasData || itemSnapshot.data!.docs.isEmpty) {
                          return ListTile(
                            leading: Icon(Icons.person),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(userName),
                              ],
                            ),
                            subtitle: Text('Phone: $userPhone\nNo items assigned.'),
                          );
                        }

                        final items = itemSnapshot.data!.docs;
                        final itemCount = items.length;

                        return ListTile(
                          leading: Icon(Icons.person),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(userName),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userPhone),
                              Text('$itemCount item${itemCount != 1 ? 's' : ''} found.'),
                            ],
                          ),
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Assigned for $userName',
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                      SizedBox(height: 10),
                                      Expanded(
                                        child: ListView.builder(
                                          itemCount: items.length,
                                          itemBuilder: (context, itemIndex) {
                                            final itemDoc = items[itemIndex];
                                            final itemName = itemDoc['description'];
                                            final itemType = itemDoc['address'];
                                            final itemDate = itemDoc['datetime'];
                                            final itemId = itemDoc.id;

                                            String formattedDate = '';
                                            if (itemDate is Timestamp) {
                                              formattedDate = DateFormat('yyyy-MM-dd').format(itemDate.toDate());
                                            }

                                            return ListTile(
                                              leading: Icon(Icons.device_hub, size: 24),
                                              title: Text('Description $itemName'),
                                              subtitle: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text('Building: $itemType'),
                                                  Text('Date: $formattedDate'),
                                                ],
                                              ),
                                              trailing: IconButton(
                                                icon: Icon(Icons.clear, color: Colors.red),
                                                onPressed: () {
                                                  FirebaseFirestore.instance
                                                      .collection('orders')
                                                      .doc(itemId)
                                                      .update({
                                                    'assignedTo': null,
                                                    'status': 'Storage',
                                                  }).then((_) {
                                                    Navigator.of(context).pop();
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text('Unassigned $itemName from $userName'),
                                                      ),
                                                    );
                                                  });
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



class _StorageTab extends StatefulWidget {
  @override
  __StorageTabState createState() => __StorageTabState();
}

class __StorageTabState extends State<_StorageTab> {
  String _searchQuery = ''; // To hold the search query

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSearchField(), // Add search field
            _buildItemsList(context), // Call the method to build the item list
          ],
        ),
      ),
    );
  }
// Method to build the search field
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by Description ...',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.search),

        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase(); // Update search query
          });
        },
      ),
    );
  }





  // Method to build the item list for "Broken" and "Storage" statuses
  Widget _buildItemsList(BuildContext context) {
    return FutureBuilder<List<Item>>(
      future: _fetchItems(), // Fetch items with desired statuses
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return ListTile(
            title: Text('No items found.'),
          );
        }

        final items = snapshot.data! // List of fetched items
            .where((item) => item.description.toLowerCase().contains(_searchQuery)) // Filter items by search query
            .toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(), // Prevent scrolling of inner list
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.parse(item.purchaseDate));

            return ListTile(
              leading: Icon(item.status == 'Done' ? Icons.broken_image : Icons.device_hub, size: 24), // Change icon based on status
              title: Text('${item.description}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Building: ${item.type}'),
                  Text('Date: $formattedDate'), // Display the date
                ],
              ),
              onTap: () {
                _showAssignBottomSheet(item, context); // Show bottom sheet for assignment
              },
            );
          },
        );
      },
    );
  }
  Future<List<Item>> _fetchItems() async {
    try {
      final brokenItemsQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'Done')
          .get();

      final storageItemsQuery = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'New')
          .get();

      final brokenItems = brokenItemsQuery.docs.map((doc) {
        return Item(
          id: doc.id,
          status: doc['status'],
          type: doc['address'] ?? 'Unknown',
          description: doc['description'] ?? 'No Description',
          purchaseDate: (doc['datetime'] as Timestamp).toDate().toString(), // Convert Timestamp to DateTime and then to String
        );
      }).toList();

      final storageItems = storageItemsQuery.docs.map((doc) {
        return Item(
          id: doc.id,
          status: doc['status'],
          type: doc['address'] ?? 'Unknown',
          description: doc['description'] ?? 'No ID',
          purchaseDate: (doc['datetime'] as Timestamp).toDate().toString(), // Same conversion here
        );
      }).toList();

      return [...brokenItems, ...storageItems];
    } catch (e) {
      print("Error fetching items: $e");
      return [];
    }
  }

  void _showAssignBottomSheet(Item item, BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Options', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('users').get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No users found.'));
                  }

                  // Build a list of users
                  return ListView(
                    shrinkWrap: true,
                    children: snapshot.data!.docs.map((userDoc) {
                      String userId = userDoc.id; // Get the user ID
                      String userName = userDoc['nickname']; // Assuming user documents have a 'nickname' field
                      return ListTile(
                        title: Center(child: Text('Assign to $userName')), // Center and add text
                        onTap: () {
                          _updateItemAssignment(item, userId, userName, 'Assigned'); // Assign to user
                          Navigator.of(context).pop();
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              SizedBox(height: 8),
              // Show buttons based on item status
              if (item.status == 'Done') ...[

                TextButton(
                  onPressed: () {
                    _updateItemStatus(item, 'New');
                    Navigator.of(context).pop();
                  },
                  child: Text('Assign to New'),
                ),
              ] else if (item.status == 'New') ...[

                SizedBox(height: 8),

              ],

              TextButton(
                child: Text('Edit Task'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditAppointmentScreen(appointmentId: item.id), // Pass appointment ID here
                    ),
                  );

                },
              ),
              SizedBox(height: 16),
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Method to update the item assignment in Firestore
  void _updateItemAssignment(Item item, String assignedUserId, String assignedUserName, String status) async {
    await FirebaseFirestore.instance.collection('orders').doc(item.id).update({
      'assignedTo': assignedUserId, // Update the item's assigned user ID
      'status': status, // Change the item's status to Assigned
    });
    // Optionally show a Snackbar or some feedback
  }

  // Method to update the item's status directly
  void _updateItemStatus(Item item, String newStatus) async {
    await FirebaseFirestore.instance.collection('orders').doc(item.id).update({
      'status': newStatus, // Update the item's status
    });
  }
}

// Screen to display items based on status
class ItemsByStatusScreen extends StatelessWidget {
  final String status;
  final IconData icon;

  ItemsByStatusScreen({required this.status, required this.icon});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: status)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No items found.'));
        }

        final items = snapshot.data!.docs.map((doc) {
          return Item(id: doc.id, status: doc['status'], purchaseDate: doc['datetime'],description: doc['description'], type: doc['address']);
        }).toList();

        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return ListTile(
              leading: Icon(icon),
              title: Text('Description: ${item.description}'),
              subtitle: Text('Status: ${item.status}, Building: ${item.type}'),
            );
          },
        );
      },
    );
  }
}
