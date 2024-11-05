import 'package:driver_app/mainScreens/All Services.dart';
import 'package:driver_app/mainScreens/add_task.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:driver_app/mainScreens/AllNotifications.dart';
import 'package:driver_app/mainScreens/AllPromotions.dart';
import 'package:driver_app/mainScreens/AllTask.dart';
import 'package:driver_app/mainScreens/menu.dart';
import 'package:easy_localization/easy_localization.dart';

class HomeTenantScreen extends StatefulWidget {
  @override
  _HomeTenantScreenState createState() => _HomeTenantScreenState();
}

extension StringCapitalization on String {
  String capitalize() {
    if (this == null || this.isEmpty) return '';
    return '${this[0].toUpperCase()}${this.substring(1)}';
  }
}

class _HomeTenantScreenState extends State<HomeTenantScreen> {
  late Future<Map<String, dynamic>> _data;
  bool isListView = false; // Variable to track the current view mode
  String _nickname = '';
  String phone = '';
  String building = '';
  List<String> sectionOrder = ['promotions', 'tasks', 'notifications', 'services']; // Order of sections

  @override
  void initState() {
    super.initState();
    _data = _fetchData();
    _fetchUserDetails();

  }

  Future<Map<String, dynamic>> _fetchData() async {
    try {
      final promotionsSnapshot = await FirebaseFirestore.instance.collection('promotions').limit(1).get(); // Limit to 1
      final servicesSnapshot = await FirebaseFirestore.instance.collection('services').limit(1).get(); // Limit to 1
      final notificationsSnapshot = await FirebaseFirestore.instance.collection('notifications').limit(1).get(); // Limit to 1
      final tasksSnapshot = await FirebaseFirestore.instance
          .collection('tasks')
          .where('nickname', isEqualTo: _nickname)
          .limit(1) // Limit to 1 task
          .get();

      return {
        'promotions': promotionsSnapshot.docs.map((doc) => doc.data()).toList(),
        'services': servicesSnapshot.docs.map((doc) => doc.data()).toList(),
        'notifications': notificationsSnapshot.docs.map((doc) => doc.data()).toList(),
        'tasks': tasksSnapshot.docs.map((doc) => doc.data()).toList(),
      };
    } catch (e) {
      print('Error fetching data: $e');
      return {
        'promotions': [],
        'services': [],
        'notifications': [],
        'tasks': [],
      };
    }
  }

  Future<void> _fetchUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? phoneNumber = prefs.getString('phone');

    if (phoneNumber != null) {
      var userQuery = await FirebaseFirestore.instance
          .collection('phone')
          .where('phone', isEqualTo: phoneNumber)
          .get();

      if (userQuery.docs.isNotEmpty) {
        setState(() {
          _nickname = userQuery.docs.first['nickname'] ?? '';
          phone = userQuery.docs.first['phone'] ?? '';
          building = userQuery.docs.first['building'] ?? '';
        });

        _data = _fetchData();
      } else {
        print('No user found for phone number: $phoneNumber');
      }
    }
  }

  void _showServiceSelectionSheet() async {
    final servicesSnapshot = await FirebaseFirestore.instance.collection('services').get();
    List<dynamic> services = servicesSnapshot.docs.map((doc) {
      // Include the document ID in the data structure
      var data = doc.data();
      data['docId'] = doc.id; // Add the document ID to the service data
      return data;
    }).toList();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('select_service'.tr(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), // Translated
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    var service = services[index];
                    String serviceTitle = (service['title'] is String)
                        ? service['title']
                        : 'unnamed_service'.tr(); // Fallback if title is not a String

                    return ListTile(
                      leading: Icon(Icons.cleaning_services),
                      title: Text(serviceTitle), // Display title
                      onTap: () {
                        // Return the document ID instead of the entire service or index
                        Navigator.pop(context, service['docId']); // Return the selected document ID
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    ).then((selectedDocId) {
      if (selectedDocId != null) {
        // Use the selected document ID to navigate
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AppointmentsPage(serviceType: selectedDocId),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:    Text(
          '${'hello'.tr()} $_nickname', // Localized "Hello" + unlocalized nickname
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.grid_view), // Change icon based on the view mode
            onPressed: () {
              setState(() {
                isListView = !isListView; // Toggle the view mode
              });
            },
          ),
        ],
      ),
      drawer: MenuDrawer(),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("error".tr(args: [snapshot.error.toString()])));
          }

          final data = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Localizing only the "Hello" part

                  SizedBox(height: 10),
                  // Conditional rendering for GridView or ListView
                  isListView
                      ? ListView.builder(
                    itemCount: sectionOrder.length,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemBuilder: (context, index) {
                      String section = sectionOrder[index];
                      return _buildSectionWidget(section, data);
                    },
                  )
                      : DragTarget<String>(
                    onAccept: (String section) {
                      setState(() {
                        sectionOrder.remove(section);
                        sectionOrder.add(section); // Move to the end
                      });
                    },
                    builder: (context, candidateData, rejectedData) {
                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, // Number of columns
                          childAspectRatio: 1.5, // Aspect ratio for the cards
                        ),
                        itemCount: sectionOrder.length,
                        shrinkWrap: true, // Important for scrollable content
                        physics: NeverScrollableScrollPhysics(), // Disable GridView scrolling
                        itemBuilder: (context, index) {
                          String section = sectionOrder[index];
                          return Draggable<String>(
                            data: section,
                            feedback: Material(
                              child: Container(
                                padding: EdgeInsets.all(8.0),
                                color: Colors.blueAccent,
                                child: Text(
                                  section.capitalize(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            childWhenDragging: Container(),
                            child: _buildSectionWidget(section, data),
                          );
                        },
                      );
                    },
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _showServiceSelectionSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero,
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: Text('add_task'.tr(), style: TextStyle(color: Colors.white)), // Translated
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionWidget(String section, Map<String, dynamic> data) {
    switch (section) {
      case 'promotions':
        return _buildPromotionsSection(data['promotions']);
      case 'tasks':
        return _buildTasksSection(data['tasks']);
      case 'notifications':
        return _buildNotificationsSection(data['notifications']);
      case 'services':
        return _buildServicesSection(data['services']);
      default:
        return Container();
    }
  }

  Widget _buildPromotionsSection(List items) {
    return _buildSection(
      "promotions_title".tr(), // Translated
      items,
      Icons.local_offer,
          (item) => _buildListItem(item, 'title', 'description', null),
      AllPromotionsScreen(),
    );
  }

  Widget _buildTasksSection(List items) {
    return _buildSection(
      "tasks_title".tr(), // Translated
      items,
      Icons.assignment,
          (item) => _buildListItem(item, 'title', 'description', null),
      AllTasksScreen(),
      noItemsMessage: "no_tasks_message".tr(), // Translated
    );
  }

  Widget _buildServicesSection(List items) {
    return _buildSection(
      "services_title".tr(), // Translated
      items,
      Icons.cleaning_services_outlined,
          (item) => _buildListItem(item, 'title', 'description', null, isService: true),
      AllServicesScreen(),
    );
  }

  Widget _buildNotificationsSection(List items) {
    return _buildSection(
      "notifications_title".tr(), // Translated
      items,
      Icons.notifications_none_rounded,
          (item) => _buildListItem(item, 'title', 'description', null),
      AllNotificationsScreen(),
    );
  }

  Widget _buildSection(String title, List items, IconData icon, Widget Function(dynamic item) itemBuilder, Widget nextScreen, {String? noItemsMessage}) {
    return Card(
      elevation: 4, // Set elevation to create a shadow effect for the section
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(3), // Optional: Round the corners of the card
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0), // Add padding inside the card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: Colors.black), // Icon next to the title
                SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), // Title with bold text
              ],
            ),
            SizedBox(height: 5),
            items.isEmpty
                ? Center(child: Text(noItemsMessage ?? 'no_items'.tr())) // Translated message if no items
                : ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(), // Disable scrolling in the ListView
              itemCount: items.length,
              itemBuilder: (context, index) {
                var item = items[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => nextScreen)); // Navigate to next screen on tap
                  },
                  child: itemBuilder(item), // Call the item builder to display the item
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(dynamic item, String titleKey, String descriptionKey, String? icon, {bool isService = false}) {
    return ListTile(
        title: Text(item[titleKey]),
      subtitle: Text(item[descriptionKey]),
    );
  }
}
