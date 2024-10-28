import 'package:driver_app/mainScreens/drawer.dart';
import 'package:driver_app/mainScreens/payment.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

class MapView extends StatefulWidget {
  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  late GoogleMapController _controller;
  Set<Marker> _markers = {};
  final LatLng telAvivCoordinates = LatLng(
      32.0853, 34.7818); // Coordinates for Tel Aviv
  LatLng? _tappedPoint;
  final TextEditingController _capacityController = TextEditingController(); // Controller for capacity field
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isBottomSheetOpen = false; // Track if the bottom sheet is open

  @override
  void initState() {
    super.initState();
    _fetchMarkers();
    // Initialize capacity to 30 only once when the widget is created
    _capacityController.text = '30';
  }

  void _centerOnDefaultLocation() {
    // Coordinates for Israel
    _controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: telAvivCoordinates,
          zoom: 10,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Map Screen"),
      ),
      drawer: CustomDrawer(),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            onTap: (LatLng point) async {
              // Remove existing markers before adding a new one
              if (_markers.isNotEmpty) {
                _markers.clear();
              }

              _tappedPoint = point;
              String address = await _fetchAddress(point);
              _addressController.text = address;

              // Add a marker to the set
              _markers.add(Marker(
                markerId: MarkerId(point.toString()),
                position: point,
                infoWindow: InfoWindow(title: address),
              ));

              // Update the UI
              setState(() {});

              // Show the bottom sheet
              _showItemDetailSheet();
            },
            markers: _markers,
            initialCameraPosition: CameraPosition(
              target: LatLng(37.4276, -122.1697), // Example coordinates
              zoom: 10,
            ),
          ),
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Text(
              "Tap to Add Building",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => BuildingProgressScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.list, size: 20),
                    SizedBox(width: 8),
                    Text("List view"),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _fetchAddress(LatLng point) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          point.latitude, point.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return "${placemark.street}, ${placemark.locality}, ${placemark
            .country}";
      } else {
        return "No address available";
      }
    } catch (e) {
      print("Error getting address: $e");
      return "Address not found";
    }
  }

  void _fetchMarkers() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('markers')
        .get();
    Set<Marker> markers = {};
    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      final location = data['location'] as GeoPoint;

      markers.add(Marker(
        markerId: MarkerId(doc.id),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(title: data['name'], snippet: data['address']),
      ));
    }

    setState(() {
      _markers = markers; // Update the state with the fetched markers
    });
    _centerOnDefaultLocation(); // Center on default location
  }

  void _showItemDetailSheet() async {
    if (_isBottomSheetOpen) return;
    _isBottomSheetOpen = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SingleChildScrollView( // Wrap with SingleChildScrollView
          child: Container(
            padding: EdgeInsets.all(16.0),
            height: 500,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'Options',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),

                // Address Field
                TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: 'Address',
                    prefixIcon: Icon(Icons.location_on, color: Colors.black),
                    suffixIcon: _addressController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.black),
                      onPressed: () {
                        setState(() {
                          _addressController.clear();
                        });
                      },
                    )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                // Name Field
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Building Name',
                    prefixIcon: Icon(Icons.business_sharp, color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),

                SizedBox(height: 10),
                // Capacity Field
                TextField(
                  controller: _capacityController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Capacity',
                    prefixIcon: Icon(Icons.people, color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: BorderSide(color: Colors.black),
                    ),
                  ),
                ),
                SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        // Validate the name field
                        if (_nameController.text.isEmpty) {
                          _showNameEmptyAlert();
                          return; // Exit early if validation fails
                        }

                        // If all fields are filled, proceed to submit data
                        await _onSubmit();
                        _fetchMarkers();
                      },
                      child: Text("Submit"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      _isBottomSheetOpen = false; // Reset the flag when the bottom sheet is closed
      _nameController.clear(); // Clear the name controller
      _addressController.clear(); // Clear the address controller
      // Remove marker if the bottom sheet is closed without submitting
      if (_markers.isNotEmpty) {
        _markers.clear();
        setState(() {}); // Update the UI
      }
    });
  }

  void _showNameEmptyAlert() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Missing Input'),
          content: Text('Please fill in the building name.'),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _onSubmit() async {
    // Get the capacity, defaulting to 30 if the field is empty
    int capacity = int.tryParse(_capacityController.text) ?? 30;

    // Prepare the marker data to be saved
    final markerData = {
      'name': _nameController.text,
      'address': _addressController.text,
      'location': GeoPoint(_tappedPoint!.latitude, _tappedPoint!.longitude),
      'datetime': FieldValue.serverTimestamp(),
      'capacity': capacity,
    };

    // Add the marker data to Firestore
    try {
      await FirebaseFirestore.instance.collection('markers').add(markerData);
      print("Marker added successfully");

      // Optional: Show a confirmation message
      final snackBar = SnackBar(content: Text("Marker added successfully"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);

      // Close the bottom sheet
      Navigator.of(context).pop(); // Close the bottom sheet on successful submission

      // Refresh the markers on the map
      _fetchMarkers();
    } catch (e) {
      print("Error adding marker: $e");
      // Optional: Show an error message
      final snackBar = SnackBar(content: Text("Error adding marker: $e"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

}