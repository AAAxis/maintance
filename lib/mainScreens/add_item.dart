import 'dart:io';
import 'package:driver_app/mainScreens/navigation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class AppointmentsPage extends StatefulWidget {
  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  List<DocumentSnapshot> orders = [];
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  DateTime selectedDate = DateTime.now();
  String? selectedHour = '08:00';
  TextEditingController descriptionController = TextEditingController();
  TextEditingController serviceController = TextEditingController(text: 'Repair');
  TextEditingController addressController = TextEditingController();
  File? _selectedImage;
  String? _uploadedImageUrl;
  double _uploadProgress = 0.0;
  String? userAddress;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
    _fetchUserAddress();
  }

  Future<void> _fetchUserAddress() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (userDoc.exists) {
      setState(() {
        userAddress = userDoc['address'];
        addressController.text = userAddress ?? '';
      });
    }
  }

  Future<void> _checkEmailVerification() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.emailVerified) {
      Future.delayed(Duration.zero, () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email is not verified.'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Send Email',
              onPressed: () {
                user.sendEmailVerification().then((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Verification email sent!'), duration: Duration(seconds: 3)),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error sending email: $error'), duration: Duration(seconds: 3)),
                  );
                });
              },
            ),
          ),
        );
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

      return imageUrl; // Return the URL
    }
    return null; // Return null if no image was selected
  }
  Future<void> addAppointment() async {
    // Call uploadImage and wait for the URL
    final imageUrl = await uploadImage();

    if (descriptionController.text.isEmpty) {
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

    // Store the appointment with the uploaded image URL if available
    await FirebaseFirestore.instance.collection('orders').add({
      'datetime': appointmentTimestamp,
      'description': descriptionController.text,
      'type': serviceController.text,
      'status': 'New',
      'created': uid,
      'address': addressController.text,
      'imageUrl': imageUrl, // Add image URL to the order
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
  }

  Widget buildCalendar() {
    int daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    DateTime firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);

    List<Widget> dayWidgets = [];
    for (int i = 0; i < firstDayOfMonth.weekday - 1; i++) {
      dayWidgets.add(SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      dayWidgets.add(
        GestureDetector(
          onTap: () {
            setState(() {
              selectedDate = DateTime(selectedDate.year, selectedDate.month, day);
            });
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: selectedDate.day == day ? Colors.blue : null,
            ),
            child: Text('$day'),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(Icons.chevron_left),
              onPressed: () {
                setState(() {
                  selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
                });
              },
            ),
            Text(
              DateFormat('MMMM yyyy').format(selectedDate),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: Icon(Icons.chevron_right),
              onPressed: () {
                setState(() {
                  selectedDate = DateTime(selectedDate.year, selectedDate.month + 1);
                });
              },
            ),
          ],
        ),
        GridView.count(
          crossAxisCount: 7,
          children: dayWidgets,
          shrinkWrap: true,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Task'),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: pickImage,
          ),
        ],
      ),
      body: Column(
        children: [
          buildCalendar(),

          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
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
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Service',
                    prefixIcon: Icon(Icons.build),
                  ),
                  value: serviceController.text,
                  items: ['Repair', 'Cleaning', 'Paint'].map((String service) {
                    return DropdownMenuItem<String>(
                      value: service,
                      child: Text(service),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      serviceController.text = value!;
                    });
                  },
                ),
                TextField(
                  controller: addressController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: 'Building',
                    prefixIcon: Icon(Icons.business_sharp),

                  ),
                ),


                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_selectedImage != null)
                        SizedBox(
                          width: 50,
                          height: 50,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        ),
                        onPressed: addAppointment,
                        icon: Icon(Icons.add),
                        label: Text('Add Task'),
                      ),
                    ],
                  ),
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
