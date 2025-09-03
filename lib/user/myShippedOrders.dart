import 'package:app/user/AllProducts.dart';
import 'package:app/user/ProfilePage.dart';
import 'package:app/user/cart_page.dart';
import 'package:app/user/productDetailPageById.dart';
import 'package:app/user/wishlistPage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'my_tabs.dart';
import 'custom_bottom_nav_bar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class MyShippedOrders extends StatefulWidget {
  const MyShippedOrders({Key? key}) : super(key: key);

  @override
  State<MyShippedOrders> createState() => _MyShippedOrdersState();
}

class _MyShippedOrdersState extends State<MyShippedOrders> {
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
        body: Center(child: Text('Please login to see your shipped orders.')),
      );
    }

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
            builder: (context) => AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Shipped Orders',
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
          const OrderTabsWidget(selectedIndex: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('userId', isEqualTo: currentUser.uid)
                  .where('status', isEqualTo: 'shipped')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text("Error loading shipped orders."),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final orders = snapshot.data!.docs;
                if (orders.isEmpty) {
                  return const Center(child: Text("No shipped orders found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final orderDoc = orders[index];
                    final data = orderDoc.data() as Map<String, dynamic>;

                    final orderId = data['orderId'] ?? orderDoc.id;
                    final name = data['name'] ?? 'Unknown';
                    final address = data['address'] ?? 'No Address';
                    final contact = data['contact'] ?? 'No Contact';
                    final deliveryType = data['deliveryType'] ?? 'Not Provided';
                    final paymentMethod = data['paymentMethod'] ?? 'Unknown';
                    final placedAt = (data['timestamp'] as Timestamp?)
                        ?.toDate();
                    final etd = data['etd'];
                    final shippedAt = (data['shippedAt'] as Timestamp?)
                        ?.toDate();
                    final total = data['total'] ?? 0.0;
                    final items = data['items'] as List<dynamic>? ?? [];

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
                                        .titleMedium!
                                        .copyWith(
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
                                          content: Text('Order ID copied'),
                                        ),
                                      );
                                    },
                                  ),
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
                                              pw.Divider(),
                                              pw.SizedBox(height: 10),
                                              pw.Text(
                                                "Order ID: $orderId",
                                                style: pw.TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                              pw.Text("Customer: $name"),
                                              pw.Text("Address: $address"),
                                              pw.Text("Contact: $contact"),
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
                                              if (placedAt != null)
                                                pw.Text(
                                                  "Order Date: ${placedAt.toLocal()}",
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
                                                    decoration:
                                                        pw.BoxDecoration(
                                                          color:
                                                              PdfColor.fromHex(
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
                                                          child: pw.Text(title),
                                                        ),
                                                        pw.Padding(
                                                          padding:
                                                              const pw.EdgeInsets.all(
                                                                6,
                                                              ),
                                                          child: pw.Text(
                                                            quantity.toString(),
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
                            const SizedBox(height: 4),
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
                            if (placedAt != null)
                              _buildDetailRow(
                                Icons.event,
                                "Placed At",
                                placedAt.toLocal().toString(),
                              ),
                            if (etd != null)
                              _buildDetailRow(
                                Icons.access_time,
                                "ETD",
                                etd.toString(),
                              ),
                            if (shippedAt != null)
                              _buildDetailRow(
                                Icons.local_shipping_rounded,
                                "Shipped At",
                                shippedAt.toLocal().toString(),
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
                                  color: Colors.grey,
                                  size: 18,
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
                            const SizedBox(height: 6),
                            ...items.map((item) {
                              final imageUrl = item['image'] ?? '';

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
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
                                    style: const TextStyle(
                                      color: Colors.white, 
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Quantity: ${item['quantity'] ?? 0} • Rs. ${item['price'] ?? 0}",
                                    style: const TextStyle(
                                      color: Colors.white, 
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
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey), 
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
