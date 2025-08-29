import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:app/user/my_orders.dart';
import 'package:app/user/myShippedOrders.dart';
import 'package:app/user/myDeliveredOrders.dart';
import 'package:app/user/myReview.dart';
import 'package:app/user/myCancelledOrders.dart';  // <- Make sure you create this page

class OrderTabsWidget extends StatelessWidget {
  final int selectedIndex;

  const OrderTabsWidget({Key? key, required this.selectedIndex}) : super(key: key);

  void _navigateTo(BuildContext context, int index) {
    if (index == selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyOrdersPage()));
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyShippedOrders()));
        break;
      case 2:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DeliveredOrdersPendingReviews()));
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyReview()));
        break;
      case 4:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyCancelledOrders()));
        break;
    }
  }

  Stream<int> _getCountForUser(String collectionName) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(0);
    }
    return FirebaseFirestore.instance
        .collection(collectionName)
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  @override
  Widget build(BuildContext context) {
    List<String> tabs = ['Orders', 'Shipped', 'Delivered', 'Review', 'Canceled'];

    List<String> collections = [
      'orders',
      'shippedOrders',
      'deliveredOrders',
      'reviews',
      'orderCancelled',  // Added canceled orders collection here
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final bool isSelected = selectedIndex == index;

          return StreamBuilder<int>(
            stream: _getCountForUser(collections[index]),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: OutlinedButton(
                  onPressed: () => _navigateTo(context, index),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isSelected ? Colors.deepPurple : Color(0xFF1E293B),
                    foregroundColor: isSelected ? Colors.white : Colors.white,
                    side: const BorderSide(color: Colors.black),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  child: Text(
                    "${tabs[index]} ($count)",
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
