import 'package:app/user/AllProducts.dart';
import 'package:app/user/ProfilePage.dart';
import 'package:app/user/cart_page.dart';
import 'package:app/user/custom_bottom_nav_bar.dart';
import 'package:app/user/productDetailPageById.dart';
import 'package:app/user/wishlistPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'my_tabs.dart';

class MyCancelledOrders extends StatefulWidget {
  const MyCancelledOrders({Key? key}) : super(key: key);

  @override
  State<MyCancelledOrders> createState() => _MyCancelledOrdersState();
}

class _MyCancelledOrdersState extends State<MyCancelledOrders> {
  int _selectedIndex = 0;

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AllProducts()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WishlistPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Please login to see your canceled orders.")),
      );
    }
    final userId = currentUser.uid;

    return Scaffold(
      backgroundColor: Color(0xFF0A0F2C),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
            border: Border(bottom: BorderSide(color: Colors.white, width: 1.0)),
          ),
          child: Builder(
            // Use Builder to get correct context for Scaffold
            builder: (context) => AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Canceled Orders',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OrderTabsWidget(selectedIndex: 4), // tabs upar wale
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orderCancelled')
                    .where('userId', isEqualTo: userId)
                    //.orderBy('cancelledAt', descending: true) // Enable if no errors
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    print('Firestore error: ${snapshot.error}');
                    return const Center(
                      child: Text("Error loading canceled orders."),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final cancelledOrders = snapshot.data!.docs;
                  if (cancelledOrders.isEmpty) {
                    return const Center(
                      child: Text("No canceled orders found."),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: cancelledOrders.length,
                    itemBuilder: (context, index) {
                      final doc = cancelledOrders[index];
                      final data = doc.data() as Map<String, dynamic>;

                      final orderId = data['orderId'] ?? doc.id;
                      final cancelledAt = (data['cancelledAt'] as Timestamp?)
                          ?.toDate();
                      final cancellationReason =
                          data['cancellationReason'] ?? 'No reason provided';
                      final cancelledBy =
                          data['cancelledBy'] ?? 'Admin'; // 👈 yaha fetch kia
                      final isSelfCancelled =
                          cancelledBy == userId; // 👈 check current user UID

                      final total = data['total'] ?? 0;
                      final items = data['items'] as List<dynamic>? ?? [];

                      final name = data['name'] ?? 'Unknown';
                      final address = data['address'] ?? 'No Address';
                      final contact = data['contact'] ?? 'No Contact';
                      final deliveryType =
                          data['deliveryType'] ?? 'Not Provided';
                      final paymentMethod = data['paymentMethod'] ?? 'Unknown';

                      return Card(
                        elevation: 3,
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Order ID: $orderId",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                    ),
                                  ),
                                  Tooltip(
                                    message: 'Copy Order ID',
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.copy_all_rounded,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: orderId),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Order ID copied'),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildDetailRow(Icons.person, "Name", name),
                              _buildDetailRow(
                                Icons.location_on,
                                "Address",
                                address,
                              ),
                              _buildDetailRow(Icons.phone, "Contact", contact),
                              _buildDetailRow(
                                Icons.local_shipping,
                                "Delivery Type",
                                deliveryType,
                              ),
                              _buildDetailRow(
                                Icons.payment,
                                "Payment",
                                paymentMethod,
                              ),
                              if (cancelledAt != null)
                                _buildDetailRow(
                                  Icons.cancel_schedule_send,
                                  "Cancelled At",
                                  cancelledAt.toLocal().toString(),
                                ),

                              _buildDetailRow(
                                Icons.person_off,
                                "Cancelled By",
                                isSelfCancelled
                                    ? "You cancelled this order"
                                    : cancelledBy,
                              ),

                              _buildDetailRow(
                                Icons.info,
                                "Reason",
                                cancellationReason,
                              ),

                              _buildDetailRow(
                                Icons.wallet,
                                "Total",
                                "Rs. $total",
                              ),
                              const Divider(height: 20),
                              Row(
                                children: const [
                                  Icon(
                                    Icons.shopping_bag,
                                    size: 18,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Order Items:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ...items.map((item) {
                                String? imageUrl = item['image'] as String?;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: GestureDetector(
                                      onTap: () {
                                        final productId =
                                            item['productId'] ?? '';
                                        if (productId.isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProductDetailPageById(
                                                    productId: productId,
                                                  ),
                                            ),
                                          );
                                        }
                                      },

                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: imageUrl != null
                                            ? Image.network(
                                                imageUrl,
                                                width: 50,
                                                height: 50,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => const Icon(
                                                      Icons.broken_image,
                                                      size: 40,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.image_not_supported,
                                                size: 40,
                                              ),
                                      ),
                                    ),
                                    title: Text(
                                      item['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        color: Colors.white, // 👈 title white
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Quantity: ${item['quantity'] ?? 0} • Rs. ${item['price'] ?? 0}",
                                      style: const TextStyle(
                                        color: Colors.white, // 👈 subtitle grey
                                      ),
                                    ),
                                  ),
                                );
                              }),
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
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey), // 👈 grey icon
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white, // 👈 white label text
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white, // 👈 white value text
              ),
            ),
          ),
        ],
      ),
    );
  }
}
