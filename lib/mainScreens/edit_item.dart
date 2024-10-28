import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditAppointmentScreen extends StatefulWidget {
  final String appointmentId;

  EditAppointmentScreen({required this.appointmentId});

  @override
  _EditAppointmentScreenState createState() => _EditAppointmentScreenState();
}

class _EditAppointmentScreenState extends State<EditAppointmentScreen> {
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController serviceController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  // Removed statusController since it's replaced by the dropdown
  DateTime? selectedDate;
  String? selectedTime;

  // New status options
  String? selectedStatus;
  List<String> statusOptions = ['New', 'Done'];

  List<String> timeOptions = [
    for (int hour = 8; hour <= 20; hour++)
      for (int minute = 0; minute <= 30; minute += 30)
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAppointmentDetails();
  }

  String? imageUrl;

  Future<void> _fetchAppointmentDetails() async {
    DocumentSnapshot appointmentDoc = await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.appointmentId)
        .get();

    if (appointmentDoc.exists) {
      Map<String, dynamic> data = appointmentDoc.data() as Map<String, dynamic>;
      descriptionController.text = data['description'] ?? '';
      serviceController.text = data['type'] ?? '';
      addressController.text = data['address'] ?? '';
      selectedStatus = data['status'] ?? statusOptions[0];
      imageUrl = data['imageUrl']; // Add this lin

      Timestamp timestamp = data['datetime'];
      DateTime appointmentDateTime = timestamp.toDate();
      selectedDate = appointmentDateTime;

      String formattedTime = DateFormat('HH:mm').format(appointmentDateTime);
      selectedTime = timeOptions.contains(formattedTime) ? formattedTime : timeOptions[0];

      setState(() {});
    }
  }

  Future<void> _updateAppointment() async {
    if (selectedDate == null || selectedTime == null || selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date, time, and status')),
      );
      return;
    }

    DateTime updatedDateTime = DateTime.parse(
      '${DateFormat('yyyy-MM-dd').format(selectedDate!)} $selectedTime:00',
    );

    await FirebaseFirestore.instance.collection('orders').doc(widget.appointmentId).update({
      'description': descriptionController.text,
      'type': serviceController.text,
      'address': addressController.text,
      'status': selectedStatus, // Update status
      'datetime': Timestamp.fromDate(updatedDateTime),
    });

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task updated successfully')),
    );
  }

  Future<void> _deleteAppointment() async {
    await FirebaseFirestore.instance.collection('orders').doc(widget.appointmentId).delete();
    Navigator.of(context).pop(); // Go back after deletion
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task deleted successfully')),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Task'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            if (imageUrl != null) // Display image if URL is available
              Image.network(
                imageUrl!,
                height: 150,
                width: 150,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            TextField(
              controller: serviceController,
              decoration: InputDecoration(
                labelText: 'Type',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            TextField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Status Dropdown
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.info),
                border: OutlineInputBorder(),
              ),
              items: statusOptions.map((status) {
                return DropdownMenuItem<String>(
                  value: status,
                  child: Text(status),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value;
                });
              },
            ),
            SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ListTile(
                    title: Text(
                      'Date: ${selectedDate != null ? DateFormat('yyyy-MM-dd').format(selectedDate!) : 'Select date'}',
                    ),
                    trailing: Icon(Icons.calendar_today),
                    onTap: () => _selectDate(context),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Time',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                    value: selectedTime,
                    items: timeOptions.map((time) {
                      return DropdownMenuItem<String>(
                        value: time,
                        child: Text(time),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedTime = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _updateAppointment,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text('Save'),
                ),
                ElevatedButton(
                  onPressed: _deleteAppointment,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.red,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

