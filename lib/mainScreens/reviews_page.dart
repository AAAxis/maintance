import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';

class ReviewsPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _removeReview(String reviewId) async {
    // Remove the review from Firestore
    await _firestore.collection('reviews').doc(reviewId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tr("reviews"))),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('reviews').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("${tr('error')}: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text(tr("no_reviews_found")));
          }

          var reviews = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              var reviewData = reviews[index].data() as Map<String, dynamic>;
              var reviewId = reviews[index].id;
              var timestamp = (reviewData['timestamp'] as Timestamp).toDate();
              var formattedDate = "${timestamp.day}/${timestamp.month}/${timestamp.year}";

              return Dismissible(
                key: Key(reviewId),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  _removeReview(reviewId);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(tr("review_removed"))),
                  );
                },
                child: ListTile(
                  leading: Icon(Icons.star, color: Colors.amber),
                  title: Text(reviewData['review'] ?? tr("no_review")),
                  subtitle: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${tr('rating')}: ${reviewData['rating'] ?? 0}"),
                      Text(formattedDate),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
