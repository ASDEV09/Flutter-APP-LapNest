// lib/adminTabs.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app/admin/admin_orders_page.dart';
import 'package:app/admin/adminShippedOrders.dart';
import 'package:app/admin/adminDeliveredOrders.dart';
import 'package:app/admin/adminOrderCancle.dart';

class AdminOrderTabsWidget extends StatelessWidget {
  final int selectedIndex;

  const AdminOrderTabsWidget({
    Key? key,
    required this.selectedIndex,
  }) : super(key: key);

  void _navigateTo(BuildContext context, int index) {
    if (index == selectedIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminOrdersPage()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminShippedOrders()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDeliveredOrdersPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminCancelledOrdersPage()),
        );
        break;
    }
  }

  /// Firestore se count fetch karne ka function
  Stream<int> _getCount(String collectionName) {
    return FirebaseFirestore.instance
        .collection(collectionName)
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  @override
  Widget build(BuildContext context) {
    List<String> tabs = ['All', 'Shipping', 'Delivered', 'Cancel'];
    List<String> collections = [
      'orders',
      'shippedOrders',
      'deliveredOrders',
      'orderCancelled'
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final bool isSelected = selectedIndex == index;

            return StreamBuilder<int>(
              stream: _getCount(collections[index]),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.deepPurple : Color(0xFF1E293B),
                      foregroundColor:
                          isSelected ? Colors.white : Colors.white,
                      side: const BorderSide(color: Colors.black),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onPressed: () => _navigateTo(context, index),
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
      ),
    );
  }
}
