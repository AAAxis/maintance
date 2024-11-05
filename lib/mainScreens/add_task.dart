import 'package:driver_app/mainScreens/share.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class AppointmentsPage extends StatefulWidget {
  final String serviceType;

  AppointmentsPage({required this.serviceType});

  @override
  _AppointmentsPageState createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  DateTime selectedDate = DateTime.now();
  String? selectedHour = '08:00';
  TextEditingController descriptionController = TextEditingController();
  File? _selectedImage;
  String? selectedTenant;
  String? selectedBuilding;
  String? selectedPhone;

  // Track current step
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    fetchStoredValues();
  }

  Future<void> fetchStoredValues() async {
    final prefs = await SharedPreferences.getInstance();
    selectedTenant = prefs.getString('nickname');
    selectedPhone = prefs.getString('phone');
    selectedBuilding = prefs.getString('building');
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

  Future<void> addAppointment() async {
    if (descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('fill_fields'.tr()), duration: Duration(seconds: 3)),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('tasks').add({
      'title': descriptionController.text,
      'serviceType': widget.serviceType,
      'building': selectedBuilding,
      'phone': selectedPhone,
      'created': selectedTenant,
      'nickname': selectedTenant,
      'date': selectedDate,
      'time': selectedHour,
      'imageUrl':  "https://firebasestorage.googleapis.com/v0/b/maintance-f744d.appspot.com/o/b.jpg?alt=media&token=8efeaa80-ae3c-4ac9-a9ed-6b7fc9d58ec3",
      'description': 'New',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('task_created'.tr()), duration: Duration(seconds: 3)),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SharePage()),
    );
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
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: selectedDate.day == day ? Colors.blue[200] : null,
            ),
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.all(4),
            child: Text(
              '$day',
              style: TextStyle(
                color: selectedDate.day == day ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        GridView.count(
          crossAxisCount: 7,
          children: dayWidgets,
          shrinkWrap: true,
        ),
      ],
    );
  }

  Widget buildStepIndicator(int step) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: step == _currentStep ? Colors.blue : Colors.grey[300],
      ),
      width: 20,
      height: 20,
      alignment: Alignment.center,
      child: step == _currentStep
          ? Icon(Icons.check, color: Colors.white, size: 14)
          : Container(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('MMMM yyyy').format(selectedDate),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                selectedDate = DateTime(selectedDate.year, selectedDate.month - 1);
              });
            },
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the calendar section if current step is 0
            if (_currentStep == 0) ...[
              Text('please_select_date'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              buildCalendar(),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'select_time'.tr(),
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 1; // Move to description/image step
                  });
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Colors.black,
                ),
                child: Text('next'.tr()), // Translated Next button
              ),
            ],
            // Display the description and image upload section if current step is 1
            if (_currentStep == 1) ...[
              Text('add_description'.tr(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'description'.tr(), // Translated description label
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              if (_selectedImage != null)
                SizedBox(
                  width: 100,
                  height: 100,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.file(
                      _selectedImage!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

              // Row for buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  ElevatedButton(
                    onPressed: pickImage,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.blue, backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.blue),
                    ),
                    child: Text('upload_image'.tr()), // Translated Upload Image button
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: addAppointment,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, backgroundColor: Colors.black,
                    ),
                    child: Text('create_task'.tr()), // Translated Create Task button
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ],
        ),
      ),
      // Positioned step indicators at the bottom
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildStepIndicator(0), // Step 1 Indicator
            buildStepIndicator(1), // Step 2 Indicator
          ],
        ),
      ),
    );
  }
}
