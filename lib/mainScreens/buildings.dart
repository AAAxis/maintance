import 'package:driver_app/mainScreens/drawer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BuildingProgressScreen extends StatefulWidget {
  @override
  _BuildingProgressScreenState createState() => _BuildingProgressScreenState();
}

class _BuildingProgressScreenState extends State<BuildingProgressScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = ''; // To store the search query
  final TextEditingController _searchController = TextEditingController(); // Controller for the search field

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
          'documentId': documentId,
        };
      }

      yield buildingData;
      await Future.delayed(Duration(seconds: 5));
    }
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

  void _showAddBuildingDialog() {
    final _buildingNameController = TextEditingController();
    final _addressController = TextEditingController();
    final _capacityController = TextEditingController();
    final String? uid = FirebaseAuth.instance.currentUser?.uid;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Building'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _buildingNameController,
                  decoration: InputDecoration(labelText: 'Building'),
                ),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: _capacityController,
                  decoration: InputDecoration(labelText: 'Tenants'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () async {
                String buildingName = _buildingNameController.text.trim();
                String address = _addressController.text.trim();
                int capacity = int.tryParse(_capacityController.text.trim()) ?? 0;

                if (buildingName.isNotEmpty && address.isNotEmpty && capacity > 0 && uid != null) {
                  await FirebaseFirestore.instance.collection('markers').add({
                    'name': buildingName,
                    'address': address,
                    'capacity': capacity,
                    'created': uid, // Add auth UID here
                  });
                  Navigator.pop(context); // Close the dialog after adding
                } else {
                  // Optionally show an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in all fields correctly.')),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.black), // Black outline
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // Square corners
                ),
              ),
              child: Text(
                'Add',
                style: TextStyle(color: Colors.black, fontSize: 20), // Black text
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditBuildingDialog(String documentId, String currentName, String currentAddress, int currentCapacity) {
    final _buildingNameController = TextEditingController(text: currentName);
    final _addressController = TextEditingController(text: currentAddress);
    final _capacityController = TextEditingController(text: currentCapacity.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Building'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _buildingNameController,
                  decoration: InputDecoration(labelText: 'Building'),
                ),
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(labelText: 'Address'),
                ),
                TextField(
                  controller: _capacityController,
                  decoration: InputDecoration(labelText: 'Tenants'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            OutlinedButton(
              onPressed: () async {
                String buildingName = _buildingNameController.text.trim();
                String address = _addressController.text.trim();
                int capacity = int.tryParse(_capacityController.text.trim()) ?? 0;

                if (buildingName.isNotEmpty && address.isNotEmpty && capacity > 0) {
                  await _firestore.collection('markers').doc(documentId).update({
                    'name': buildingName,
                    'address': address,
                    'capacity': capacity,

                  });
                  Navigator.pop(context); // Close the dialog after editing
                } else {
                  // Optionally show an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please fill in all fields correctly.')),
                  );
                }
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.black), // Black outline
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero, // Square corners
                ),
              ),
              child: Text(
                'Save',
                style: TextStyle(color: Colors.black, fontSize: 20), // Black text
              ),
            ),
          ],
        );
      },
    );
  }

  void _clearSearch() {
    _searchController.clear(); // Clear the text in the search field
    setState(() {
      _searchQuery = ''; // Reset the search query
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Propertys'),
      ),
drawer: CustomDrawer(),
      body: Stack(
        children: [
          Column(
            children: [

              Expanded(
                child: StreamBuilder<Map<String, Map<String, dynamic>>>(
                  stream: _streamBuildingData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData) {
                      return Center(child: Text('No data available.'));
                    }

                    final buildingData = snapshot.data!;
                    // Filter buildings based on search query
                    final filteredBuildings = buildingData.keys
                        .where((key) => key.toLowerCase().contains(_searchQuery))
                        .toList();

                    // Display count of filtered records
                    return Column(
                      children: [

                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredBuildings.length,
                            itemBuilder: (context, index) {
                              String buildingName = filteredBuildings[index];
                              var data = buildingData[buildingName]!;

                              return Dismissible(
                                key: Key(data['documentId']),
                                background: Container(color: Colors.red),
                                confirmDismiss: (direction) async {
                                  bool confirmed = await _showConfirmationDialog(buildingName, data['documentId']);
                                  return confirmed;
                                },
                                onDismissed: (direction) {
                                  // Already handled in confirmDismiss
                                },
                                child: Card( // Using Card for elevation effect
                                  elevation: 4, // Elevation to elevate the card
                                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16), // Margins for spacing
                                  child: ListTile(
                                    leading: Icon(Icons.apartment), // Icon on the left
                                    title: Text(buildingName),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, // Align text to the start
                                      children: [
                                        Text(data['address']), // Address on the first line
                                        Text('Capacity: ${data['capacity']}'), // Capacity on the second line
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.edit, color: Colors.black), // Pen icon for edit
                                      onPressed: () {
                                        // Open edit dialog when tapping the pen icon
                                        _showEditBuildingDialog(data['documentId'], buildingName, data['address'], data['capacity']);
                                      },
                                    ),
                                    // Removed onTap to prevent opening edit dialog when tapping the ListTile
                                  )


                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          // Bottom Square Button
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
              width: MediaQuery.of(context).size.width - 32, // Full-width
              height: 50, // Square height
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, // Button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Set border radius to zero for square corners
                  ),
                  padding: EdgeInsets.zero, // No padding
                ),
                onPressed: _showAddBuildingDialog,
                child: Text(
                  'Add Building',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ),
        ],
      ),

    );
  }
}