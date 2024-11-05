import 'package:driver_app/mainScreens/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // For Clipboard functionality
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import 'reviews_page.dart'; // Import the reviews page

class SharePage extends StatefulWidget {
  @override
  _SharePageState createState() => _SharePageState();
}

class _SharePageState extends State<SharePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _reviewController = TextEditingController();
  double _rating = 0;

  String sharableLink = ""; // Variable to hold the sharable link
  String imageUrl = ""; // Variable to hold the image URL
  String? currentUserUid;

  // Fetch UID from local storage
  Future<void> getCurrentUserUid() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      currentUserUid =
      'Xe1PPmiwsHdPFN2VCVjd7boKBmQ2'; // Replace 'uid' with your key
    });
  }

  Future<Map<String, dynamic>?> _fetchUserInfo() async {
    if (currentUserUid!.isEmpty) return null; // No user logged in

    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(
          currentUserUid).get();
      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>?;

        sharableLink =
            userData?['sharableLink'] ?? ""; // Fetch the sharable link
        imageUrl = userData?['image'] ?? ""; // Fetch the image URL
        return userData;
      } else {
        return null; // Document does not exist
      }
    } catch (e) {
      print("Error fetching user info: $e");
      return null;
    }
  }

  void _submitReview() {
    String review = _reviewController.text;
    if (review.isNotEmpty && _rating > 0) {
      _firestore.collection('reviews').add({
        'review': review,
        'rating': _rating,
        'name': "Anonim",
        'timestamp': FieldValue.serverTimestamp(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('review_submitted'))));
      _reviewController.clear();
      setState(() {
        _rating = 0; // Reset rating
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('provide_review_and_rating'))));
    }
  }

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: sharableLink));
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('link_copied'))));
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            index < _rating ? Icons.star : Icons.star_border,
            color: index < _rating ? Colors.amber : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _rating = index + 1.0;
            });
          },
        );
      }),
    );
  }

  Widget _buildUserInfoAndReviewInput(BuildContext context,
      Map<String, dynamic> userInfo) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        final email = userInfo['email'] ?? 'N/A';
                        if (email != 'N/A') {
                          launch('mailto:$email');
                        }
                      },
                      child: Text(
                        "${userInfo['nickname'] ?? tr('not_available')}",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final phone = userInfo['phone'] ?? 'N/A';
                        if (phone != 'N/A') {
                          launch('tel:$phone');
                        }
                      },
                      child: Text(
                        "${userInfo['phone'] ?? tr('not_available')}",
                        style: TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        final email = userInfo['email'] ?? 'N/A';
                        if (email != 'N/A') {
                          launch('mailto:$email');
                        }
                      },
                      child: Text(
                        "${userInfo['email'] ?? tr('not_available')}",
                        style: TextStyle(fontSize: 16, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(tr("rating"), style: TextStyle(fontSize: 18)),
          _buildStarRating(),
          SizedBox(height: 20),
          Text(tr("write_review"), style: TextStyle(fontSize: 18)),
          TextField(
            controller: _reviewController,
            maxLines: 5,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: tr("enter_review"),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: _submitReview,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.black,
                ),
                child: Text(tr("submit_review")),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ReviewsPage()),
                  );
                },
                child: Text(tr("view_reviews")),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: BorderSide(color: Colors.blue),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Text(tr("share_link"), style: TextStyle(fontSize: 18)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  sharableLink.isNotEmpty ? sharableLink : tr("no_link"),
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.copy),
                onPressed: _copyLink,
                tooltip: tr("copy_link"),
              ),
            ],
          ),
          SizedBox(height: 20),
          if (imageUrl.isNotEmpty)
            Column(
              children: [
                Image.network(
                  imageUrl,
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    getCurrentUserUid();
    _fetchUserInfo();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr("share_review")),
        automaticallyImplyLeading: false, // Remove the default back button
        actions: [
          IconButton(
            icon: Icon(Icons.close), // X icon
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) =>
                    HomeTenantScreen()), // Replace with your home screen widget
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchUserInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("${tr('error')}: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text(tr("no_user_found")));
          }

          var userInfo = snapshot.data!;
          return _buildUserInfoAndReviewInput(context, userInfo);
        },
      ),
    );
  }
}