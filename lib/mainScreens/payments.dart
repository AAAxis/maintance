import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_payment_screen.dart'; // Import the AddPaymentScreen

class PaymentRecordsScreen extends StatefulWidget {
  const PaymentRecordsScreen({Key? key}) : super(key: key);

  @override
  _PaymentRecordsScreenState createState() => _PaymentRecordsScreenState();
}

class _PaymentRecordsScreenState extends State<PaymentRecordsScreen> {
  List<Map<String, dynamic>> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('phone').get();
    setState(() {
      users = snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['nickname'], // Assuming nickname is the user's name
        'phone': doc['phone'], // Assuming phone is stored in user data
        'building': doc['building'], // Fetching building info from the user document
      }).toList();
    });
  }

  void _showCreditCardDialog(Map<String, dynamic> paymentData) {
    final creditCardNumber = paymentData['creditCardNumber'] ?? 'N/A';
    final cvv = paymentData['cvv'] ?? 'N/A';
    final expDate = paymentData['expDate'] ?? 'N/A';
    final building = paymentData['building'] ?? 'N/A'; // Add building info

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Biling Information"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Card Number: $creditCardNumber"),
              Text("CVV: $cvv"),
              Text("Expiration Date: $expDate"),
              Text("Building: $building"), // Display building info
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePaymentRecord(String paymentId) async {
    await FirebaseFirestore.instance.collection('payments').doc(paymentId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment record deleted successfully.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Payment Records"),

      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('payments').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No payment records found."));
          }

          final paymentRecords = snapshot.data!.docs;

          return ListView.builder(
            itemCount: paymentRecords.length,
            itemBuilder: (context, index) {
              final paymentData = paymentRecords[index].data() as Map<String, dynamic>;
              final paymentId = paymentRecords[index].id; // Get the document ID for deletion

              return Dismissible(
                key: Key(paymentId),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _deletePaymentRecord(paymentId);
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                child: ListTile(
                  leading: Icon(Icons.payment), // Add an icon for each record
                  title: Text(paymentData['userName'] ?? 'Unknown User'), // Assuming userName is saved
                  subtitle: Text("Phone: ${paymentData['userPhone'] ?? 'N/A'}, Building: ${paymentData['building'] ?? 'N/A'}"), // Include building info here
                  onTap: () => _showCreditCardDialog(paymentData),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the Add Payment screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddPaymentScreen(users: users)),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
