import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'service_registration.dart';

class Service {
  final String id;
  final String name;
  final String description;

  Service({
    required this.id,
    required this.name,

    required this.description,
  });
}

class ServicesScreen extends StatefulWidget {
  @override
  _ServicesScreenState createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Service> _services = [];

  Future<void> _fetchServices() async {
    List<Service> serviceList = [];
    var servicesSnapshot = await _firestore.collection('services').get();

    for (var serviceDoc in servicesSnapshot.docs) {
      serviceList.add(Service(
        id: serviceDoc.id,
        name: serviceDoc['title'],
        description: serviceDoc['description'],
      ));
    }
    setState(() {
      _services = serviceList;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _editService(Service service) async {
    final TextEditingController nameController = TextEditingController(text: service.name);
     final TextEditingController descriptionController = TextEditingController(text: service.description);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Edit Service'),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Name', prefixIcon: Icon(Icons.label)),
              ),

              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Dewscription', prefixIcon: Icon(Icons.attach_money)),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _firestore.collection('services').doc(service.id).update({
                  'title': nameController.text,
                     'description': descriptionController.text,
                });
                Navigator.pop(context);
                _fetchServices();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).delete();
  }

  Future<void> _addService() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ServiceRegistrationScreen()),
    ).then((_) => _fetchServices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Services'),
      ),
      body: ListView.builder(
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          return Dismissible(
            key: Key(service.id),
            background: Container(color: Colors.red),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text('Confirm Deletion'),
                    content: Text('Are you sure you want to delete ${service.name}?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () async {
                          await _deleteService(service.id);
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
                SnackBar(content: Text('${service.name} deleted')),
              );
            },
            child: Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                leading: Icon(Icons.business_center, color: Colors.black),
                title: Text(service.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${service.description}', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.edit, color: Colors.black),
                  onPressed: () => _editService(service),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addService,
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
