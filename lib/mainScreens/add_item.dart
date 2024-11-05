import 'dart:io';
import 'package:driver_app/mainScreens/navigation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class TaskerPage extends StatefulWidget {
  @override
  _TaskerPageState createState() => _TaskerPageState();
}

class _TaskerPageState extends State<TaskerPage> {
  List<String> userList = [];
  String? selectedUser;
  String? userBuilding;
  String? userEmail;
  String? userNickname;
  String? userPhone;

  final String uid = FirebaseAuth.instance.currentUser!.uid;
  DateTime selectedDate = DateTime.now();
  String? selectedHour = '08:00';
  TextEditingController descriptionController = TextEditingController();
  TextEditingController serviceController = TextEditingController(text: 'Repair');
  File? _selectedImage;
  String? _uploadedImageUrl;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    selectedDate = DateTime.now(); // Set today's date as default

  }

  Future<void> _fetchUsers() async {
    QuerySnapshot usersSnapshot = await FirebaseFirestore.instance.collection('phone').get();
    setState(() {
      userList = usersSnapshot.docs.map((doc) => doc['nickname'] as String).toList();

      if (userList.isNotEmpty) {
        selectedUser = userList.first;
        _fetchUserDetails(selectedUser!); // Fetch details for the first user
      }
    });
  }

  Future<void> _fetchUserDetails(String nickname) async {
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('phone')
        .where('nickname', isEqualTo: nickname)
        .get();

    if (userSnapshot.docs.isNotEmpty) {
      DocumentSnapshot userDoc = userSnapshot.docs.first;
      setState(() {
        userBuilding = userDoc['building'];
        userEmail = userDoc['email'];
        userNickname = userDoc['nickname'];
        userPhone = userDoc['phone'];
      });
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> uploadImage() async {
    if (_selectedImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('documents/${DateTime.now().millisecondsSinceEpoch}');
      final uploadTask = storageRef.putFile(_selectedImage!);

      uploadTask.snapshotEvents.listen((event) {
        setState(() {
          _uploadProgress = event.bytesTransferred / event.totalBytes;
        });
      });

      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();
      _uploadedImageUrl = imageUrl;

      return imageUrl;
    }
    return null;
  }

  Future<void> addAppointment() async {
    final imageUrl = await uploadImage();

    if (descriptionController.text.isEmpty || selectedUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields!'), duration: Duration(seconds: 3)),
      );
      return;
    }

    DateTime appointmentDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(selectedHour!.split(":")[0]),
      int.parse(selectedHour!.split(":")[1]),
    );

    Timestamp appointmentTimestamp = Timestamp.fromDate(appointmentDateTime);

    await FirebaseFirestore.instance.collection('tasks').add({
      'datetime': appointmentTimestamp,
      'title': descriptionController.text,
      'type': serviceController.text,
      'description': 'New',
      'created': 'Admin',
      'building': userBuilding,
      'phone': userPhone,
      'nickname': userNickname,
      'email': userEmail,
      'imageUrl': imageUrl ?? 'https://firebasestorage.googleapis.com/v0/b/maintance-f744d.appspot.com/o/b.jpg?alt=media&token=8efeaa80-ae3c-4ac9-a9ed-6b7fc9d58ec3', // Save fake link if imageUrl is null
    });

    clearFields();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task successfully created!'), duration: Duration(seconds: 3)),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NavigationScreen()),
    );
  }

  void clearFields() {
    descriptionController.clear();
    serviceController.text = 'Repair';
    selectedHour = '08:00';
    _selectedImage = null;
    _uploadedImageUrl = null;
    userBuilding = null;
    userEmail = null;
    userNickname = null;
    userPhone = null;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate, // Preselect today's date
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Select Date',
                    prefixIcon: Icon(Icons.calendar_today),
                    hintText: DateFormat('yyyy-MM-dd').format(selectedDate),
                  ),
                ),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
              ),
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(labelText: 'Select User', prefixIcon: Icon(Icons.person)),
              value: selectedUser,
              items: userList.map((String user) {
                return DropdownMenuItem<String>(
                  value: user,
                  child: Text(user),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedUser = value;
                  _fetchUserDetails(value!);
                });
              },
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Hour',
                prefixIcon: Icon(Icons.access_time),
              ),
              value: selectedHour,
              items: List.generate(13, (index) {
                int hour = 8 + index;
                String time = '${hour.toString().padLeft(2, '0')}:00';
                return DropdownMenuItem<String>(
                  value: time,
                  child: Text(time),
                );
              }),
              onChanged: (value) {
                setState(() {
                  selectedHour = value;
                });
              },
            ),
            SizedBox(height: 10),
            // Image upload icon
            GestureDetector(
              onTap: pickImage,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0), // Add padding around the text
                    child: Text(
                      'Image Upload', // Display "IMAGE UPLOAD" instead of an icon
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue, // Text color for better visibility
                        fontWeight: FontWeight.bold, // Optional: makes the text bold
                      ),
                    ),
                  ),
                ],
              ),
            ),


            if (_selectedImage != null) ...[
              SizedBox(height: 10),
              Image.file(_selectedImage!, height: 100, width: 100, fit: BoxFit.cover),
              LinearProgressIndicator(value: _uploadProgress),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ElevatedButton(
          onPressed: addAppointment,
          child: Text('Add Task', style: TextStyle(fontSize: 18)),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ),
    );
  }
}
