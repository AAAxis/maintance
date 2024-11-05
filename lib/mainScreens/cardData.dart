import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _cvvController = TextEditingController();
  final _expiryDateController = TextEditingController();
  bool _isTermsAccepted = false;
  bool _paymentExists = false;
  String? _existingDocumentId;

  @override
  void initState() {
    super.initState();
    _checkExistingPayment();
  }

  Future<void> _checkExistingPayment() async {
    final prefs = await SharedPreferences.getInstance();
    final userPhone = prefs.getString('phone');

    if (userPhone != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('payments')
          .where('userPhone', isEqualTo: userPhone)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          _paymentExists = true;
          _existingDocumentId = querySnapshot.docs.first.id;
        });
      }
    }
  }

  Future<void> _deleteExistingPayment() async {
    if (_existingDocumentId != null) {
      await FirebaseFirestore.instance
          .collection('payments')
          .doc(_existingDocumentId)
          .delete();
      setState(() {
        _paymentExists = false;
        _existingDocumentId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr("existing_payment_deleted"))),
      );
    }
  }

  Future<void> _saveCardData() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      final building = prefs.getString('building');
      final userPhone = prefs.getString('phone');
      final userName = prefs.getString('nickname');

      if (building != null && userPhone != null && userName != null) {
        await FirebaseFirestore.instance.collection('cards').add({
          'building': building,
          'creditCardNumber': _cardNumberController.text,
          'cvv': _cvvController.text,
          'expDate': _expiryDateController.text,
          'userName': userName,
          'userPhone': userPhone,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr("payment_submitted"))),
        );

        _formKey.currentState!.reset();
        setState(() {
          _isTermsAccepted = false;
          _paymentExists = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr("missing_user_info"))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("add_payment_method")),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _paymentExists
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr("user_setup_warning"),
              style: TextStyle(color: Colors.red),
            ),
            TextButton(
              onPressed: _deleteExistingPayment,
              child: Text(tr("click_to_delete")),
            ),
          ],
        )
            : Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: tr("card_number"),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr("enter_card_number");
                  } else if (value.length != 16) {
                    return tr("card_number_16_digits");
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _expiryDateController,
                decoration: InputDecoration(
                  labelText: tr("expiry_date"),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.datetime,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr("enter_expiry_date");
                  } else if (!RegExp(r"^(0[1-9]|1[0-2])\/?([0-9]{2})$")
                      .hasMatch(value)) {
                    return tr("expiry_date_format");
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _cvvController,
                decoration: InputDecoration(
                  labelText: tr("cvv"),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return tr("enter_cvv");
                  } else if (value.length != 3) {
                    return tr("cvv_3_digits");
                  }
                  return null;
                },
              ),
              Row(
                children: [
                  Checkbox(
                    value: _isTermsAccepted,
                    onChanged: (value) {
                      setState(() {
                        _isTermsAccepted = value!;
                      });
                    },
                  ),
                  Expanded(
                    child: Text(tr("approve_terms")),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _isTermsAccepted ? _saveCardData : null,
                  child: Text(tr("submit")),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _cvvController.dispose();
    _expiryDateController.dispose();
    super.dispose();
  }
}
