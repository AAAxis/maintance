import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddPaymentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> users;

  const AddPaymentScreen({Key? key, required this.users}) : super(key: key);

  @override
  _AddPaymentScreenState createState() => _AddPaymentScreenState();
}

class _AddPaymentScreenState extends State<AddPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _creditCardController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _expDateController = TextEditingController();

  String? selectedUserId;
  String? selectedUserName;
  String? selectedUserPhone;
  String? selectedUserBuilding; // This can still be used in your logic

  Future<void> _addPaymentRecord() async {
    if (_formKey.currentState!.validate() && selectedUserId != null) {
      await FirebaseFirestore.instance.collection('payments').add({
        'userName': selectedUserName,
        'userPhone': selectedUserPhone,
        'building': selectedUserBuilding,
        'creditCardNumber': _creditCardController.text,
        'cvv': _cvvController.text,
        'expDate': _expDateController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment record added successfully.")),
      );

      // Clear the text fields
      _creditCardController.clear();
      _cvvController.clear();
      _expDateController.clear();
      setState(() {
        selectedUserId = null;
        selectedUserName = null;
        selectedUserPhone = null;
        selectedUserBuilding = null; // Clear the building field, if needed
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Payment Record"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  SizedBox(width: 10),
                  Icon(Icons.person, size: 24), // Tenant icon
                  SizedBox(width: 8), // Spacing between icon and dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(labelText: "Select Tenant"),
                      value: selectedUserId,
                      items: widget.users.map((user) {
                        return DropdownMenuItem<String>(
                          value: user['id'],
                          child: Text(user['name']),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedUserId = value;
                          final selectedUser = widget.users.firstWhere((user) => user['id'] == value);
                          selectedUserName = selectedUser['name'];
                          selectedUserPhone = selectedUser['phone'];
                          selectedUserBuilding = selectedUser['building']; // Keep for internal logic, if needed
                        });
                      },
                      validator: (value) => value == null ? "Please select a user" : null,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _creditCardController,
                decoration: InputDecoration(
                  labelText: "Credit Card Number",
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Please enter a credit card number" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _expDateController,
                decoration: InputDecoration(
                  labelText: "Expiration Date (MM/YY)",
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                validator: (value) => value!.isEmpty ? "Please enter an expiration date" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _cvvController,
                decoration: InputDecoration(
                  labelText: "CVV",
                  prefixIcon: Icon(Icons.lock),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? "Please enter a CVV" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _addPaymentRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                ),
                child: Text("Add Record", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
