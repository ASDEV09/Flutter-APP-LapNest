import 'package:app/admin/admin_tabs.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/admin/app_drawer.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDeliveredOrdersPage extends StatefulWidget {
  const AdminDeliveredOrdersPage({Key? key}) : super(key: key);

  @override
  _AdminDeliveredOrdersPageState createState() =>
      _AdminDeliveredOrdersPageState();
}

class _AdminDeliveredOrdersPageState extends State<AdminDeliveredOrdersPage> {
  String? userRole;
  bool loadingRole = true;
  String searchQuery = "";
  @override
  void initState() {
    super.initState();
    fetchUserRole();
  }

  Future<void> fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        userRole = null;
        loadingRole = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          userRole = data?['role'];
          loadingRole = false;
        });
      } else {
        setState(() {
          userRole = null;
          loadingRole = false;
        });
      }
    } catch (e) {
      setState(() {
        userRole = null;
        loadingRole = false;
      });
    }
  }

  Future<bool?> showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1F36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Delete Order",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: Text(
          "Are you sure you want to delete this delivered order?",
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Delete', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Future<void> deleteDeliveredOrder(BuildContext context, String docId) async {
    final confirmed = await showDeleteConfirmationDialog(context);
    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(docId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order deleted successfully")),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error deleting order: $e")));
      }
    }
  }

  void showOrderDetailsDialog(BuildContext context, Map<String, dynamic> data) {
    final orderId = data['orderId'] ?? 'Unknown';
    final total = data['total'] ?? 0;
    final paymentMethod = data['paymentMethod'] ?? 'Unknown';
    final timestamp = data['timestamp'] != null
        ? (data['timestamp'] as Timestamp).toDate()
        : null;
    final deliveredAt = data['deliveredAt'] != null
        ? (data['deliveredAt'] as Timestamp).toDate()
        : null;
    final recipientName = data['name'] ?? 'Customer';
    final contact = data['contact'] ?? '';
    final address = data['address'] ?? '';
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1B1F36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Order #${orderId.toString()}",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              detailRow("Customer", recipientName),
              if (contact.isNotEmpty) detailRow("Contact", contact),
              if (address.isNotEmpty) detailRow("Address", address),
              detailRow("Total", "Rs. $total"),
              detailRow("Payment", paymentMethod),
              if (timestamp != null)
                detailRow("Ordered At", timestamp.toLocal().toString()),
              if (deliveredAt != null)
                detailRow("Delivered At", deliveredAt.toLocal().toString()),
              const SizedBox(height: 12),
              Text(
                "Items:",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              ...items.map(
                (item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: (item['image'] != null)
                            ? Image.asset(
                                item['image'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(
                                Icons.image,
                                color: Colors.grey,
                                size: 40,
                              ),
                      ),
                      const SizedBox(width: 10),

                      // Product Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] ?? "No Title",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (item['description'] != null)
                              Text(
                                item['description'],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            Text(
                              "x${item['quantity']}  •  Rs. ${item['price']}",
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Close", style: TextStyle(color: Colors.white70)),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userRole != 'admin') {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text("Access Denied"),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "You do not have permission to access this page.",
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2C),
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Delivered Orders',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      drawer: AppDrawer(user: currentUser),
      body: Column(
        children: [
          const AdminOrderTabsWidget(selectedIndex: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim();
                });
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by Order ID",
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1B1F36),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('status', isEqualTo: 'delivered')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No delivered orders yet.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                final deliveredOrders = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final orderId =
                      data['orderId']?.toString().toLowerCase() ?? "";
                  return orderId.contains(searchQuery.toLowerCase());
                }).toList();

                if (deliveredOrders.isEmpty) {
                  return const Center(
                    child: Text(
                      'No orders match your search.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: deliveredOrders.length,
                  itemBuilder: (context, index) {
                    final order = deliveredOrders[index];
                    final data = order.data() as Map<String, dynamic>;
                    final docId = order.id;

                    final orderId = data['orderId'] ?? 'Unknown';
                    final total = data['total'] ?? 0;
                    final recipientName = data['name'] ?? 'Customer';

                    return Card(
                      color: const Color(0xFF1B1F36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        // yahan icon ki jagah image lagani hai
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              (data['items'] != null &&
                                  data['items'].isNotEmpty)
                              ? Image.asset(
                                  data['items'][0]['image'], // items array ka pehla image
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                  size: 28,
                                ), // fallback agar image na ho
                        ),
                        title: Text(
                          "Order #${orderId.toString().substring(0, 8)}",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          "User: $recipientName\nTotal: Rs. $total", // 👈 \n se line break
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),

                        trailing: PopupMenuButton<String>(
                          color: Color(0xFF1E293B),
                          onSelected: (v) async {
                            if (v == 'delete') {
                              await deleteDeliveredOrder(context, docId);
                            }
                            if (v == 'view') {
                              showOrderDetailsDialog(context, data);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'view',
                              child: Text(
                                "View Details",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                "Delete",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
