import 'package:app/signInScreen.dart';
import 'package:app/user/AllProducts.dart';
import 'package:app/user/ProfilePage.dart';
import 'package:app/user/cart_page.dart';
import 'package:app/user/wishlistPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'my_tabs.dart';
import 'custom_bottom_nav_bar.dart'; // <-- apna nav bar ka path yahan lagao
import 'productDetailPageById.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart' as p;

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({Key? key}) : super(key: key);

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  int _selectedIndex = 0;

  Future<void> deleteOrder(String orderId) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .delete();
    } catch (e) {
      print('Error deleting order: $e');
    }
  }

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
      return Scaffold(
        backgroundColor: const Color(0xFF0A0F2C),

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
                'My Order',
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

        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Please log in to view your Orders.",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 20,
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignInScreen(),
                    ),
                  );
                },
                child: const Text("Login", style: TextStyle(fontSize: 14)),
              ),
            ],
          ),
        ),
      );
    }

    final String currentUserId = currentUser.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2C),

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
                'My Orders',
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
            const OrderTabsWidget(selectedIndex: 0), // tabs upar wale
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('userId', isEqualTo: currentUserId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('You have no orders yet.'));
                  }

                  final orders = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      final orderIdFromDoc = order.id;
                      final data = order.data() as Map<String, dynamic>;

                      final orderId = data['orderId'] ?? orderIdFromDoc;
                      final total = data['total'] ?? 0;
                      final paymentMethod = data['paymentMethod'] ?? 'Unknown';
                      final timestamp = (data['timestamp'] as Timestamp?)
                          ?.toDate();
                      final items = (data['items'] as List<dynamic>? ?? [])
                          .map((item) => Map<String, dynamic>.from(item))
                          .toList();
                      final recipientName = data['name'] ?? 'Customer';
                      final contactNumber = data['contact'] ?? 'Not provided';
                      final addressLine = data['address'] ?? 'Not provided';
                      final deliveryType =
                          data['deliveryType'] ?? 'Not provided';

                      return Card(
                        color: Color(0xFF1E293B),
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
                                  // 👇 Yahan Add kiya Download Invoice Button
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
                                                // Invoice Header
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
                                                pw.Divider(),
                                                pw.SizedBox(height: 10),

                                                // Order Info
                                                pw.Text(
                                                  "Order ID: $orderId",
                                                  style: pw.TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                pw.Text(
                                                  "Customer: $recipientName",
                                                  style: pw.TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                pw.Text(
                                                  "Address: $addressLine",
                                                  style: pw.TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                pw.Text(
                                                  "Contact: $contactNumber",
                                                  style: pw.TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                pw.Text(
                                                  "Delivery Type: $deliveryType",
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
                                                if (timestamp != null)
                                                  pw.Text(
                                                    "Order Date: ${timestamp.toLocal()}",
                                                    style: pw.TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                pw.SizedBox(height: 20),

                                                // Items Header
                                                pw.Text(
                                                  "Order Summary",
                                                  style: pw.TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        pw.FontWeight.bold,
                                                  ),
                                                ),
                                                pw.SizedBox(height: 10),

                                                // Items Table
                                                pw.Table(
                                                  border: pw.TableBorder.all(),
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
                                                      decoration: pw.BoxDecoration(
                                                        color:
                                                            p.PdfColor.fromHex(
                                                              '#eeeeee',
                                                            ),
                                                      ),

                                                      children: [
                                                        pw.Padding(
                                                          padding:
                                                              const pw.EdgeInsets.all(
                                                                8,
                                                              ),
                                                          child: pw.Text(
                                                            "Item",
                                                            style: pw.TextStyle(
                                                              fontWeight: pw
                                                                  .FontWeight
                                                                  .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        pw.Padding(
                                                          padding:
                                                              const pw.EdgeInsets.all(
                                                                8,
                                                              ),
                                                          child: pw.Text(
                                                            "Qty",
                                                            style: pw.TextStyle(
                                                              fontWeight: pw
                                                                  .FontWeight
                                                                  .bold,
                                                            ),
                                                          ),
                                                        ),
                                                        pw.Padding(
                                                          padding:
                                                              const pw.EdgeInsets.all(
                                                                8,
                                                              ),
                                                          child: pw.Text(
                                                            "Price",
                                                            style: pw.TextStyle(
                                                              fontWeight: pw
                                                                  .FontWeight
                                                                  .bold,
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
                                                          item['quantity'] ?? 1;
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
                                                  alignment:
                                                      pw.Alignment.centerRight,
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
                                        onLayout: (format) async => pdf.save(),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Recipient: $recipientName",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Address: $addressLine",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.phone, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Contact: $contactNumber",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.local_shipping,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Delivery Type: $deliveryType",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.payment, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Payment: $paymentMethod",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.wallet, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Total: Rs. $total",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                              if (timestamp != null)
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "Placed: ${timestamp.toLocal()}",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              const Divider(),
                              Row(
                                children: const [
                                  Icon(Icons.shopping_bag, color: Colors.grey),
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
                              const SizedBox(height: 6),
                              ...items.map((item) {
                                final imageUrl = item['image'] ?? '';
                                // Uint8List? imageBytes;
                                // try {
                                //   if (imageData.isNotEmpty) {
                                //     imageBytes = base64Decode(imageData);
                                //   }
                                // } catch (e) {
                                //   imageBytes = null;
                                // }

                                return ListTile(
                                  leading: GestureDetector(
                                    onTap: () {
                                      final productId = item['productId'] ?? '';
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
                                                (context, error, stackTrace) =>
                                                    const Icon(
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
                                    item['title'] ?? 'No Title',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    "Quantity: ${item['quantity'] ?? 1} • Rs. ${item['price'] ?? 0}",
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              }),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    String? selectedReason;
                                    TextEditingController reasonController =
                                        TextEditingController();

                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => StatefulBuilder(
                                        builder: (context, setState) => AlertDialog(
                                          title: const Text('Cancel Order'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              DropdownButtonFormField<String>(
                                                initialValue: selectedReason,
                                                decoration:
                                                    const InputDecoration(
                                                      border:
                                                          OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                          ),
                                                    ),
                                                hint: const Text(
                                                  "Choose a reason",
                                                ),
                                                isExpanded: true,
                                                items:
                                                    [
                                                      'Changed my mind',
                                                      'Found a better price elsewhere',
                                                      'Ordered by mistake',
                                                      'Other',
                                                    ].map((reason) {
                                                      return DropdownMenuItem(
                                                        value: reason,
                                                        child: Text(reason),
                                                      );
                                                    }).toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    selectedReason = value;
                                                  });
                                                },
                                              ),
                                              if (selectedReason ==
                                                  'Other') ...[
                                                const SizedBox(height: 10),
                                                TextField(
                                                  controller: reasonController,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Your reason',
                                                        border:
                                                            OutlineInputBorder(),
                                                      ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                if (selectedReason == null) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Please select a reason',
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                if (selectedReason == 'Other' &&
                                                    reasonController.text
                                                        .trim()
                                                        .isEmpty) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'Please enter a reason',
                                                      ),
                                                    ),
                                                  );
                                                  return;
                                                }
                                                Navigator.pop(context, true);
                                              },
                                              child: const Text('Submit'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );

                                    if (confirm == true) {
                                      String finalReason =
                                          selectedReason == 'Other'
                                          ? reasonController.text.trim()
                                          : selectedReason ??
                                                'No reason provided';

                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('orderCancelled')
                                            .add({
                                              ...data,
                                              'orderId': orderId,
                                              'cancelledAt': DateTime.now(),
                                              'cancelledBy': currentUserId,
                                              'cancellationReason': finalReason,
                                            });

                                        await deleteOrder(orderIdFromDoc);

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Order cancelled successfully',
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        print('Error cancelling order: $e');
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Failed to cancel order',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                  label: const Text('Cancel Order'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple,
                                    foregroundColor: Colors.white,
                                  ),
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
      ),
    );
  }
}
