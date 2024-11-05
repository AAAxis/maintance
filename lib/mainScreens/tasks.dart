import 'package:driver_app/mainScreens/add_item.dart';
import 'package:driver_app/mainScreens/drawer.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String name;
  final String documentId;
  final String createdBy; // This will hold the user's nickname
  final String building;
  final String status;
  final String phone; // Add phone field
  final String nickname; // Add nickname field

  Task({
    required this.name,
    required this.documentId,
    required this.createdBy,
    required this.building,
    required this.status,
    required this.phone,
    required this.nickname,
  });


}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  FullScreenImage({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop(); // Close the image on tap
              },
              child: Hero(
                tag: imageUrl, // Unique tag for Hero animation
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            top: 40, // Adjust the position as needed
            right: 20, // Adjust the position as needed
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () {
                Navigator.of(context).pop(); // Close the viewer
              },
            ),
          ),
        ],
      ),
    );
  }
}


class User {
  final String id;
  final String name;

  User({required this.id, required this.name});
}

class TasksScreen extends StatefulWidget {
  @override
  _TasksScreenState createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Future<User?> _fetchUserById(String userId) async {
    var userDoc = await _firestore.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return User(id: userId, name: userDoc['nickname']);
    }
    return null;
  }

  Future<void> _deleteTask(String taskId) async {
    await _firestore.collection('tasks').doc(taskId).delete();
  }

  Stream<List<Task>> _streamAllTasks() async* {
    while (true) {
      List<Task> tasksList = [];
      var tasksSnapshot = await _firestore.collection('tasks').get();

      for (var task in tasksSnapshot.docs) {
        String taskName = task['title'];
        String documentId = task.id;
        String building = task['building'];
        String phone = task['phone']; // Get phone directly from the task document
        String createdBy = task['created'];
        String status = task['description'];

        // Fetch the user to get nickname
        User? user = await _fetchUserById(createdBy);

        tasksList.add(Task(
          name: taskName,
          documentId: documentId,
          createdBy: user?.name ?? createdBy, // Fallback to createdBy if user is null
          building: building,
          status: status,
          phone: phone, // Set phone from task
          nickname: user?.name ?? '', // Set nickname from user or fallback to empty
        ));
      }

      yield tasksList;
      await Future.delayed(Duration(seconds: 5));
    }
  }

  Future<void> _editTask(Task task) async {
    final TextEditingController nameController = TextEditingController(text: task.name);
    final TextEditingController descriptionController = TextEditingController(text: task.status);
    final TextEditingController phoneController = TextEditingController(text: task.phone); // Set the phone from task
    String status = task.status;

    // Fetch the image URL from Firestore
    String? imageUrl;
    var taskDoc = await _firestore.collection('tasks').doc(task.documentId).get();
    if (taskDoc.exists && taskDoc.data() != null) {
      imageUrl = taskDoc['imageUrl']; // Assuming 'imageUrl' is the field name in Firestore
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Edit Task'),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: phoneController, // Populate phoneController with the phone value from task
                decoration: InputDecoration(labelText: 'Phone'),
              ),
              DropdownButtonFormField<String>(
                value: status,
                items: ['New', 'Completed']
                    .map((label) => DropdownMenuItem(
                  value: label,
                  child: Text(label),
                ))
                    .toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      status = newValue;
                    });
                  }
                },
                decoration: InputDecoration(labelText: 'Status'),
              ),
              SizedBox(height: 10),
              // Show "View Image" link if the image URL exists
              if (imageUrl != null && imageUrl.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    // Navigate to full-screen image viewer
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImage(imageUrl: imageUrl!),
                      ),
                    );
                  },
                  child: Text(
                    'View Image',  // Display the link
                    style: TextStyle(
                      color: Colors.blue,  // Style as a link
                      decoration: TextDecoration.underline,  // Optional underline style
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _firestore.collection('tasks').doc(task.documentId).update({
                  'title': nameController.text,
                  'description': status,
                  'phone': phoneController.text, // Update phone in Firestore
                });
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Tasks'),
      ),
      drawer: CustomDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _streamAllTasks().asBroadcastStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No tasks available.'));
                }

                final tasksList = snapshot.data!;
                final filteredTasks = tasksList
                    .where((task) => task.name.toLowerCase().contains(_searchQuery))
                    .toList();

                return ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    Task task = filteredTasks[index];

                    return Dismissible(
                      key: Key(task.documentId), // Use a unique key for the dismissible widget
                      direction: DismissDirection.endToStart, // Swipe from right to left
                      background: Container(
                        color: Colors.red, // Background color when swiped
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Icon(Icons.delete, color: Colors.white), // Icon shown when swiped
                      ),
                      onDismissed: (direction) async {
                        // Delete task on dismiss
                        await _deleteTask(task.documentId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Task deleted')),
                        );
                      },
                      child: Card(
                        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        elevation: 4,
                        child: ListTile(
                          leading: Icon(Icons.task_alt, color: Colors.black),
                          title: Text(
                            task.name,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'Created by: ${task.createdBy}\nBuilding: ${task.building}',
                            style: TextStyle(fontSize: 14),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editTask(task),
                          ),
                        ),
                      ),
                    );

                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TaskerPage()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
