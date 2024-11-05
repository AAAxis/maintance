import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';

class AllTasksScreen extends StatefulWidget {
  @override
  _AllTasksScreenState createState() => _AllTasksScreenState();
}


class _AllTasksScreenState extends State<AllTasksScreen> {
  late Future<List<Map<String, dynamic>>> _tasksFuture;

  @override
  void initState() {
    super.initState();
    _tasksFuture = _fetchAllTasks(); // Initialize tasks future
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("all_tasks".tr()), // Translated title
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("error".tr(args: [snapshot.error.toString()])));
          }

          final tasks = snapshot.data ?? [];
          if (tasks.isEmpty) {
            return Center(child: Text("no_tasks".tr())); // Translated no tasks message
          }

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];

              return Card(
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: Icon(Icons.task_alt, color: Colors.black),
                        title: Text(task['title'] ?? 'unnamed_task'.tr()), // Translated title
                        subtitle: Text(task['building'] ?? 'no_details'.tr()), // Translated building info
                        trailing: Text(task['description'] ?? 'status_unknown'.tr()), // Translated status
                        onTap: () => _showTaskDetails(context, task),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final nickname = prefs.getString('nickname'); // Get the stored nickname

    if (nickname == null) {
      return []; // Return an empty list if no nickname is found in prefs
    }

    // Fetch tasks where the nickname matches the stored nickname
    final tasksSnapshot = await FirebaseFirestore.instance
        .collection('tasks')
        .where('nickname', isEqualTo: nickname)
        .get();

    return tasksSnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return {
        ...data,
        'id': doc.id, // Store the document ID for deletion
      };
    }).toList();
  }

  void _showTaskDetails(BuildContext context, Map<String, dynamic> task) {
    final title = task['title'] ?? 'no_title'.tr();
    final building = task['building'] ?? 'no_building_info'.tr();
    final created = task['created'] ?? 'unknown'.tr();
    final datetime = task['datetime']?.toDate().toString() ?? 'no_date'.tr();
    final description = task['description'] ?? 'no_description'.tr();
    final email = task['email'] ?? 'no_email'.tr();
    final imageUrl = task['imageUrl'];
    final nickname = task['nickname'] ?? 'no_nickname'.tr();
    final phone = task['phone'] ?? 'no_phone'.tr();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Building: $building'),
                Text('Created by: $created'),
                Text('Status: $description'),
                Text('Phone: $phone'),
                if (imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: GestureDetector(
                      onTap: () => _openImageLink(imageUrl),
                      child: Row(
                        children: [
                          Icon(Icons.image, color: Colors.blue),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'view_image'.tr(), // Translated view image text
                              style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('close'.tr()), // Translated close button text
            ),
            TextButton(
              onPressed: () async {
                await _deleteTask(task['id']); // Delete task and update the UI
              },
              child: Text('delete_task'.tr()), // Translated delete task button text
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTask(String taskId) async {
    Navigator.pop(context); // Close the dialog after deletion

    try {
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).delete();
      setState(() {
        _tasksFuture = _fetchAllTasks(); // Refresh the task list
      });
      // Optionally show a success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('task_deleted'.tr()))); // Translated task deleted message
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting task: $e')));
    }
  }

  void _openImageLink(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not open image link: $url';
    }
  }
}
