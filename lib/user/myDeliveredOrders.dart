import 'package:app/user/AllProducts.dart';
import 'package:app/user/ProfilePage.dart';
import 'package:app/user/cart_page.dart';
import 'package:app/user/productDetailPageById.dart';
import 'package:app/user/wishlistPage.dart';
import 'package:app/user/writeReviewPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'my_tabs.dart'; 
import 'custom_bottom_nav_bar.dart'; 
import 'package:pdf/pdf.dart' as p;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class DeliveredOrdersPendingReviews extends StatefulWidget {
  const DeliveredOrdersPendingReviews({Key? key}) : super(key: key);

  @override
  State<DeliveredOrdersPendingReviews> createState() =>
      _DeliveredOrdersPendingReviewsState();
}

class _DeliveredOrdersPendingReviewsState
    extends State<DeliveredOrdersPendingReviews> {
  final currentUser = FirebaseAuth.instance.currentUser;
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
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to see your orders')),
      );
    }

    final userId = currentUser!.uid;

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
            builder: (context) => AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Delivered Orders',
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
      body: Column(
        children: [
          const OrderTabsWidget(selectedIndex: 2),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: userId)
                  .where('status', isEqualTo: 'delivered')
                  .snapshots(),
              builder: (context, orderSnapshot) {
                if (orderSnapshot.hasError) {
                  return const Center(child: Text("Error loading orders"));
                }
                if (!orderSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = orderSnapshot.data!.docs;

                if (orders.isEmpty) {
                  return const Center(
                    child: Text("You have no delivered orders"),
                  );
                }

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reviews')
                      .where('userId', isEqualTo: userId)
                      .snapshots(),
                  builder: (context, reviewSnapshot) {
                    if (reviewSnapshot.hasError) {
                      return const Center(child: Text("Error loading reviews"));
                    }
                    if (!reviewSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final userReviews = reviewSnapshot.data!.docs;
                    final reviewedOrderProductPairs = userReviews.map((r) {
                      final data = r.data() as Map<String, dynamic>;
                      return "${data['orderId']}_${data['productId']}";
                    }).toSet();

                    return ListView.builder(
                      itemCount: orders.length,
                      itemBuilder: (context, index) {
                        final orderDoc = orders[index];
                        final orderData =
                            orderDoc.data() as Map<String, dynamic>;
                        final orderId = orderData['orderId'] ?? orderDoc.id;
                        final items =
                            (orderData['items'] as List<dynamic>?) ?? [];

                        final name = orderData['name'] ?? 'Unknown';
                        final address = orderData['address'] ?? 'No Address';
                        final contact = orderData['contact'] ?? 'No Contact';
                        final paymentMethod =
                            orderData['paymentMethod'] ?? 'Unknown';
                        final placedAt = (orderData['timestamp'] as Timestamp?)
                            ?.toDate();
                        final total = orderData['total'] ?? 0.0;

                        return Card(
                          color: const Color(0xFF1E293B),

                          margin: const EdgeInsets.all(10),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.inventory_2,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        "Order ID: $orderId",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.copy,
                                        size: 18,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        Clipboard.setData(
                                          ClipboardData(text: orderId),
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text("Order ID copied"),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.download,
                                        size: 20,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () async {
                                        final pdf = pw.Document();

                                        pdf.addPage(
                                          pw.Page(
                                            margin: const pw.EdgeInsets.all(24),
                                            build: (pw.Context context) {
                                              return pw.Column(
                                                crossAxisAlignment:
                                                    pw.CrossAxisAlignment.start,
                                                children: [
                                                  pw.Center(
                                                    child: pw.Text(
                                                      "INVOICE",
                                                      style: pw.TextStyle(
                                                        fontSize: 28,
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  pw.SizedBox(height: 10),
                                                  pw.Divider(),
                                                  pw.SizedBox(height: 10),
                                                  pw.Text(
                                                    "Order ID: $orderId",
                                                    style: pw.TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  pw.Text(
                                                    "Customer: $name",
                                                    style: pw.TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  pw.Text(
                                                    "Address: $address",
                                                    style: pw.TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  pw.Text(
                                                    "Contact: $contact",
                                                    style: pw.TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  pw.Text(
                                                    "Payment: $paymentMethod",
                                                    style: pw.TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  pw.SizedBox(height: 20),
                                                  pw.Text(
                                                    "Order Summary",
                                                    style: pw.TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          pw.FontWeight.bold,
                                                    ),
                                                  ),
                                                  pw.SizedBox(height: 10),
                                                  pw.Table(
                                                    border: pw.TableBorder.all(
                                                      width: 0.5,
                                                      color: p.PdfColors.grey,
                                                    ),
                                                    columnWidths: {
                                                      0: const pw.FlexColumnWidth(
                                                        3,
                                                      ),
                                                      1: const pw.FlexColumnWidth(
                                                        1,
                                                      ),
                                                      2: const pw.FlexColumnWidth(
                                                        2,
                                                      ),
                                                    },
                                                    children: [
                                                      pw.TableRow(
                                                        decoration:
                                                            const pw.BoxDecoration(
                                                              color: p
                                                                  .PdfColors
                                                                  .grey300,
                                                            ),
                                                        children: [
                                                          pw.Padding(
                                                            padding:
                                                                const pw.EdgeInsets.all(
                                                                  6,
                                                                ),
                                                            child: pw.Text(
                                                              "Item",
                                                              style: pw.TextStyle(
                                                                fontWeight: pw
                                                                    .FontWeight
                                                                    .bold,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                          pw.Padding(
                                                            padding:
                                                                const pw.EdgeInsets.all(
                                                                  6,
                                                                ),
                                                            child: pw.Text(
                                                              "Qty",
                                                              style: pw.TextStyle(
                                                                fontWeight: pw
                                                                    .FontWeight
                                                                    .bold,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                          pw.Padding(
                                                            padding:
                                                                const pw.EdgeInsets.all(
                                                                  6,
                                                                ),
                                                            child: pw.Text(
                                                              "Price",
                                                              style: pw.TextStyle(
                                                                fontWeight: pw
                                                                    .FontWeight
                                                                    .bold,
                                                                fontSize: 14,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      ...items.map((item) {
                                                        final title =
                                                            item['title'] ??
                                                            'No Title';
                                                        final quantity =
                                                            item['quantity'] ??
                                                            1;
                                                        final price =
                                                            item['price'] ?? 0;
                                                        return pw.TableRow(
                                                          children: [
                                                            pw.Padding(
                                                              padding:
                                                                  const pw.EdgeInsets.all(
                                                                    6,
                                                                  ),
                                                              child: pw.Text(
                                                                title,
                                                              ),
                                                            ),
                                                            pw.Padding(
                                                              padding:
                                                                  const pw.EdgeInsets.all(
                                                                    6,
                                                                  ),
                                                              child: pw.Text(
                                                                quantity
                                                                    .toString(),
                                                              ),
                                                            ),
                                                            pw.Padding(
                                                              padding:
                                                                  const pw.EdgeInsets.all(
                                                                    6,
                                                                  ),
                                                              child: pw.Text(
                                                                "Rs. $price",
                                                              ),
                                                            ),
                                                          ],
                                                        );
                                                      }),
                                                    ],
                                                  ),

                                                  pw.SizedBox(height: 20),
                                                  pw.Align(
                                                    alignment: pw
                                                        .Alignment
                                                        .centerRight,
                                                    child: pw.Text(
                                                      "Total: Rs. $total",
                                                      style: pw.TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),

                                                  pw.Divider(),
                                                  pw.SizedBox(height: 10),
                                                  pw.Center(
                                                    child: pw.Text(
                                                      "Thank you for shopping with us!",
                                                      style: pw.TextStyle(
                                                        fontSize: 12,
                                                        fontStyle:
                                                            pw.FontStyle.italic,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        );

                                        await Printing.layoutPdf(
                                          onLayout: (format) async =>
                                              pdf.save(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.person,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Name: $name",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.home,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Address: $address",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.phone,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Contact: $contact",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.payment,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Payment: $paymentMethod",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                if (placedAt != null)
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Colors.grey,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Placed At: ${placedAt.toLocal()}",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.wallet,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Total: Rs. $total",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  children: const [
                                    Icon(
                                      Icons.shopping_bag,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "Items:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                ...items.map((item) {
                                  final title = item['title'] ?? 'No Title';
                                  final quantity = item['quantity'] ?? 1;
                                  final price = item['price'] ?? 0;
                                  final productId = item['productId'] ?? '';
                                  final imageUrl = item['image'] ?? '';

                                  final key = "${orderId}_$productId";
                                  final isReviewed = reviewedOrderProductPairs
                                      .contains(key);
                                  final Timestamp? reviewAvailableAtTimestamp =
                                      item['reviewAvailableAt'];
                                  bool isReviewExpired = false;
                                  if (reviewAvailableAtTimestamp != null) {
                                    final reviewAvailableAt =
                                        reviewAvailableAtTimestamp.toDate();
                                    final now = DateTime.now();
                                    final difference = now.difference(
                                      reviewAvailableAt,
                                    );

                                    if (difference.inMinutes > 2) {
                                      isReviewExpired = true;
                                    }
                                  }

                                  final showWriteReviewButton =
                                      !isReviewed && !isReviewExpired;

                                  return ListTile(
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
                                      child: imageUrl.isNotEmpty
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
                                                    color: Colors.red,
                                                  ),
                                            )
                                          : const Icon(
                                              Icons.image,
                                              color: Colors.black54,
                                            ),
                                    ),
                                    title: Text(
                                      title,
                                      style: const TextStyle(
                                        color: Colors.white, 
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      "Quantity: $quantity • Rs. $price",
                                      style: const TextStyle(
                                        color: Colors.white, 
                                      ),
                                    ),

                                    trailing: showWriteReviewButton
                                        ? ElevatedButton(
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      WriteReviewPage(
                                                        orderId: orderId,
                                                        userName:
                                                            currentUser!
                                                                .displayName ??
                                                            'Anonymous',
                                                        productId: productId,
                                                        productTitle: title,
                                                        productImageBase64:
                                                            item['image'] ?? '',
                                                      ),
                                                ),
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.deepPurple,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text("Write Review"),
                                          )
                                        : null,
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      },
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
