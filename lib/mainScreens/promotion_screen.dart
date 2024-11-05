import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'promotion_registration.dart';

class Promotion {
  final String id;
  final String title;
  final String description;
  final DateTime date;

  Promotion({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
  });
}

class PromotionsScreen extends StatefulWidget {
  @override
  _PromotionsScreenState createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Promotion> _allPromotions = [];
  List<Promotion> _filteredPromotions = [];
  String _searchQuery = '';

  Future<void> _fetchPromotions() async {
    List<Promotion> promotionList = [];
    var promotionsSnapshot = await _firestore.collection('promotions').get();

    for (var promotionDoc in promotionsSnapshot.docs) {
      promotionList.add(Promotion(
        id: promotionDoc.id,
        title: promotionDoc['title'],
        description: promotionDoc['description'],
        date: (promotionDoc['date'] as Timestamp).toDate(),
      ));
    }
    setState(() {
      _allPromotions = promotionList;
      _filteredPromotions = promotionList;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchPromotions();
  }

  void _filterPromotions(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filteredPromotions = _allPromotions
          .where((promotion) => promotion.title.toLowerCase().contains(_searchQuery))
          .toList();
    });
  }

  Future<void> _editPromotion(Promotion promotion) async {
    final TextEditingController titleController = TextEditingController(text: promotion.title);
    final TextEditingController descriptionController = TextEditingController(text: promotion.description);
    DateTime selectedDate = promotion.date;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Promotion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.calendar_today),
                  SizedBox(width: 8),
                  Text('Date: ${selectedDate.toLocal().toString().split(' ')[0]}'),
                  Spacer(),
                  TextButton(
                    child: Text('Change Date'),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (pickedDate != null) {
                        setState(() {
                          selectedDate = pickedDate;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _firestore.collection('promotions').doc(promotion.id).update({
                  'title': titleController.text,
                  'description': descriptionController.text,
                  'date': Timestamp.fromDate(selectedDate),
                });
                Navigator.pop(context);
                _fetchPromotions();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePromotion(String promotionId) async {
    await _firestore.collection('promotions').doc(promotionId).delete();
  }

  Future<void> _addPromotion() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PromotionRegistrationScreen()),
    ).then((_) => _fetchPromotions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Promotions'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _filteredPromotions.length,
              itemBuilder: (context, index) {
                Promotion promotion = _filteredPromotions[index];
                return Dismissible(
                  key: Key(promotion.id),
                  background: Container(color: Colors.red),
                  confirmDismiss: (direction) async {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Confirm Deletion'),
                          content: Text('Are you sure you want to delete ${promotion.title}?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                _deletePromotion(promotion.id);
                                Navigator.of(context).pop(true);
                              },
                              child: Text('Delete', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${promotion.title} deleted')),
                    );
                  },
                  child: Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    elevation: 4,
                    child: ListTile(
                      leading: Icon(Icons.local_offer),
                      title: Text(promotion.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(promotion.description),
                          SizedBox(height: 4),
                          Row(
                            children: [

                              SizedBox(width: 4),
                              Text(
                                '${promotion.date.toLocal().toString().split(' ')[0]}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.edit, color: Colors.black),
                        onPressed: () => _editPromotion(promotion),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPromotion,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
