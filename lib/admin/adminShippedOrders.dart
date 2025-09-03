import 'package:app/admin/admin_tabs.dart';
import 'package:app/services/email.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/admin/app_drawer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminShippedOrders extends StatefulWidget {
  const AdminShippedOrders({Key? key}) : super(key: key);

  @override
  _AdminShippedOrdersState createState() => _AdminShippedOrdersState();
}

class _AdminShippedOrdersState extends State<AdminShippedOrders> {
  String? userRole;
  bool loadingRole = true;
  final TextEditingController _searchController = TextEditingController();
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

  Future<String> getUserEmail(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        return userDoc.data()?['email'] ?? 'No Email';
      }
    } catch (e) {
      // ignore
    }
    return 'Unknown';
  }

  Future<void> markAsDelivered(
    String docId,
    Map<String, dynamic> orderData,
    DocumentSnapshot orderDoc,
  ) async {
    try {
      await orderDoc.reference.update({
        'status': 'delivered',
        'deliveredAt': Timestamp.now(),
      });
      final List<dynamic> itemsWithProductId = orderData['items'] ?? [];

    final updatedOrderData = {
  ...orderData,
  'status': 'delivered',         
  'deliveredAt': Timestamp.now(), 
  'orderId': docId,
  'items': itemsWithProductId,
};
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(docId)
          .update(updatedOrderData);

      String userId = orderData['userId'];
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userEmail = userDoc.data()?['email'] ?? "unknown@email.com";
      final customerName = userDoc.data()?['userName'] ?? "Customer";

      String itemsTable = itemsWithProductId.map((item) {
        final title = item['title'] ?? "Unknown Item";
        final quantity = item['quantity'] ?? 1; 
        final price = item['price'] ?? 0;

        return """
        <tr style="border-bottom:1px solid #ddd;">
          <td style="padding:8px;">$title</td>
          <td style="padding:8px; text-align:center;">$quantity</td>
          <td style="padding:8px; text-align:right;">Rs. $price</td>
        </tr>
      """;
      }).join();

      double totalBill = (orderData['total'] ?? 0).toDouble();

      await EmailService.sendShippedConfirmationEmail(
        toEmail: userEmail,
        customerName: customerName,
        status: "Delivered",
        orderId: docId,
        items: List<Map<String, dynamic>>.from(itemsWithProductId),
        totalBill: totalBill,
        itemsTable: itemsTable,
        firstline:"😊 In Your Hands!",
        secline:"Your order is now in your hands.",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order marked as Delivered & email sent")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error shipping order: $e")));
    }
  }

  Future<void> cancelOrder(DocumentSnapshot shippedOrder, String reason) async {
    final data = shippedOrder.data() as Map<String, dynamic>;
    try {
      await FirebaseFirestore.instance.collection('orderCancelled').add({
        ...data,
        'cancelledAt': Timestamp.now(),
        'cancelledBy': "Admin",
        'cancellationReason': reason,
        'orderId': shippedOrder.id,
      });
      await shippedOrder.reference.delete();
    } catch (e) {
      // ignore
    }
  }

  void showOrderDetailsDialog(
    BuildContext context,
    String orderId,
    String userEmail,
    Map<String, dynamic> data,
    DateTime? timestamp,
  ) {
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            "Order Details",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                detailRow("Order ID", orderId),
                detailRow("User Email", userEmail),
                detailRow("Name", data['name']),
                detailRow("Contact", data['contact']),
                detailRow("Address", data['address']),
                detailRow("Payment Method", data['paymentMethod']),
                detailRow("Delivery Type", data['deliveryType']),
                detailRow("Total Bill", "Rs. ${data['total']}"),
                if (timestamp != null)
                  detailRow("Placed", timestamp.toLocal().toString()),
                const Divider(color: Colors.grey),
                const SizedBox(height: 8),
                const Text(
                  "Ordered Items",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                ...items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((item['image'] ?? '').isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              item['image'],
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.image_not_supported,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                            ),
                          )
                        else
                          const Icon(
                            Icons.image_not_supported,
                            size: 40,
                            color: Colors.grey,
                          ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${item['title']} (Qty: ${item['quantity']})",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Rs. ${item['price']}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
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
          const SizedBox(height: 2),
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
    const backgroundColor = Color(0xFF0A0F2C);
    const cardColor = Color(0xFF1E293B);
    const textColor = Color(0xFFD3D3D3);
    const accentColor = Colors.deepPurple;
    const iconColor = Colors.grey;

    if (loadingRole) {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(child: CircularProgressIndicator(color: accentColor)),
      );
    }

    if (userRole != 'admin') {
      return const Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "You do not have permission to access this page.",
              style: TextStyle(fontSize: 18, color: textColor),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Shipped Orders",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
            tooltip: 'Refresh Orders',
          ),
        ],
      ),
      drawer: AppDrawer(user: currentUser),
      body: Column(
        children: [
          const AdminOrderTabsWidget(selectedIndex: 1),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by Order ID...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: cardColor,
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = "";
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where('status', isEqualTo: 'shipped')
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text(
                      "Error loading shipped orders.",
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: accentColor),
                  );
                }

                final orders = snapshot.data!.docs.where((doc) {
                  final orderId = doc.id.toLowerCase();
                  return searchQuery.isEmpty ||
                      orderId.contains(searchQuery.toLowerCase());
                }).toList();

                if (orders.isEmpty) {
                  return const Center(
                    child: Text(
                      "No shipped orders found.",
                      style: TextStyle(color: textColor, fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final doc = orders[index];
                    final data = doc.data() as Map<String, dynamic>? ?? {};
                    final orderId = doc.id;
                    final userId = data['userId'] ?? '';
                    final recipientName = data['name'] ?? 'Unknown';

                    final shippedAt = data['shippedAt'] != null
                        ? (data['shippedAt'] as Timestamp).toDate()
                        : null;
                    final timestamp = data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp).toDate()
                        : null;
                    final total = data['total'] ?? 0;
                    final items = (data['items'] as List<dynamic>? ?? [])
                        .map((item) => Map<String, dynamic>.from(item))
                        .toList();

                    return FutureBuilder<String>(
                      future: getUserEmail(userId),
                      builder: (context, emailSnapshot) {
                        final userEmail = emailSnapshot.data ?? 'Loading...';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                          color: const Color(0xFF1B1F36),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child:
                                          (data['items'] != null &&
                                              data['items'].isNotEmpty)
                                          ? Image.network(
                                              data['items'][0]['image'],
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => Icon(
                                                    Icons.image,
                                                    size: 50,
                                                    color: Colors.grey,
                                                  ),
                                            )
                                          : Icon(
                                              Icons.image,
                                              size: 50,
                                              color: Colors.grey,
                                            ),
                                    ),
                                    const SizedBox(width: 10),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Order #${orderId.toString().substring(0, 8)}",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            "User: $recipientName",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            "Total: Rs. $total",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            "Date: ${shippedAt?.toLocal().toString().split(' ')[0] ?? ''}",
                                            style: GoogleFonts.poppins(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    PopupMenuButton<String>(
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: Colors.white,
                                      ),
                                      color: const Color(0xFF1B1F36),
                                      onSelected: (value) async {
                                        if (value == 'details') {
                                          showOrderDetailsDialog(
                                            context,
                                            orderId,
                                            userEmail,
                                            data,
                                            timestamp,
                                          );
                                        } else if (value == 'pdf') {
                                          final pdf = pw.Document();

                                          pdf.addPage(
                                            pw.Page(
                                              margin: const pw.EdgeInsets.all(
                                                24,
                                              ),
                                              build: (pw.Context context) {
                                                return pw.Column(
                                                  crossAxisAlignment: pw
                                                      .CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    pw.Center(
                                                      child: pw.Text(
                                                        "INVOICE",
                                                        style: pw.TextStyle(
                                                          fontSize: 28,
                                                          fontWeight: pw
                                                              .FontWeight
                                                              .bold,
                                                        ),
                                                      ),
                                                    ),
                                                    pw.Divider(),
                                                    pw.SizedBox(height: 10),
                                                    pw.Text(
                                                      "Order ID: $orderId",
                                                    ),
                                                    pw.Text(
                                                      "Customer: ${data['name']}",
                                                    ),
                                                    pw.Text(
                                                      "Email: $userEmail",
                                                    ),
                                                    pw.Text(
                                                      "Contact: ${data['contact']}",
                                                    ),
                                                    pw.Text(
                                                      "Address: ${data['address']}",
                                                    ),
                                                    if (timestamp != null)
                                                      pw.Text(
                                                        "Date: ${timestamp.toLocal().toString().split(' ')[0]}",
                                                      ),
                                                    pw.SizedBox(height: 20),
                                                    pw.Text(
                                                      "Items",
                                                      style: pw.TextStyle(
                                                        fontWeight:
                                                            pw.FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    pw.SizedBox(height: 10),
                                                    pw.Table(
                                                      border:
                                                          pw.TableBorder.all(),
                                                      children: [
                                                        pw.TableRow(
                                                          children: [
                                                            pw.Padding(
                                                              padding:
                                                                  const pw.EdgeInsets.all(
                                                                    6,
                                                                  ),
                                                              child: pw.Text(
                                                                "Item",
                                                              ),
                                                            ),
                                                            pw.Padding(
                                                              padding:
                                                                  const pw.EdgeInsets.all(
                                                                    6,
                                                                  ),
                                                              child: pw.Text(
                                                                "Qty",
                                                              ),
                                                            ),
                                                            pw.Padding(
                                                              padding:
                                                                  const pw.EdgeInsets.all(
                                                                    6,
                                                                  ),
                                                              child: pw.Text(
                                                                "Price",
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        ...items.map((item) {
                                                          return pw.TableRow(
                                                            children: [
                                                              pw.Padding(
                                                                padding:
                                                                    const pw.EdgeInsets.all(
                                                                      6,
                                                                    ),
                                                                child: pw.Text(
                                                                  item['title'] ??
                                                                      'No title',
                                                                ),
                                                              ),
                                                              pw.Padding(
                                                                padding:
                                                                    const pw.EdgeInsets.all(
                                                                      6,
                                                                    ),
                                                                child: pw.Text(
                                                                  "${item['quantity']}",
                                                                ),
                                                              ),
                                                              pw.Padding(
                                                                padding:
                                                                    const pw.EdgeInsets.all(
                                                                      6,
                                                                    ),
                                                                child: pw.Text(
                                                                  "Rs. ${item['price']}",
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
                                                        "Total: Rs. ${data['total']}",
                                                        style: pw.TextStyle(
                                                          fontWeight: pw
                                                              .FontWeight
                                                              .bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          );

                                          pdf.addPage(
                                            pw.Page(
                                              pageFormat: PdfPageFormat.a6,
                                              margin: const pw.EdgeInsets.all(
                                                10,
                                              ),
                                              build: (pw.Context context) {
                                                return pw.Container(
                                                  padding:
                                                      const pw.EdgeInsets.all(
                                                        8,
                                                      ),
                                                  decoration: pw.BoxDecoration(
                                                    border: pw.Border.all(),
                                                    borderRadius:
                                                        pw.BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: pw.Column(
                                                    crossAxisAlignment: pw
                                                        .CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      pw.Text(
                                                        "Shipping Label",
                                                        style: pw.TextStyle(
                                                          fontWeight: pw
                                                              .FontWeight
                                                              .bold,
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      pw.Divider(),
                                                      pw.Text(
                                                        "Order ID: $orderId",
                                                      ),
                                                      pw.Text(
                                                        "Name: ${data['name']}",
                                                      ),
                                                      pw.Text(
                                                        "Contact: ${data['contact']}",
                                                      ),
                                                      pw.Text(
                                                        "Address: ${data['address']}",
                                                      ),
                                                      pw.SizedBox(height: 10),
                                                      pw.Text(
                                                        "Amount: Rs. ${data['total']}",
                                                        style: pw.TextStyle(
                                                          fontWeight: pw
                                                              .FontWeight
                                                              .bold,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          );

                                          await Printing.layoutPdf(
                                            onLayout: (format) async =>
                                                pdf.save(),
                                          );
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'details',
                                          child: Text(
                                            "View Details",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'pdf',
                                          child: Text(
                                            "Download Invoice and Label",
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 140,
                                      height: 40,
                                      child: FittedBox(
                                        fit: BoxFit
                                            .scaleDown,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                backgroundColor: cardColor,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                title: const Text(
                                                  "Confirm Delivery",
                                                  style: TextStyle(
                                                    color: textColor,
                                                  ),
                                                ),
                                                content: const Text(
                                                  "Mark this order as delivered?",
                                                  style: TextStyle(
                                                    color: textColor,
                                                  ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          false,
                                                        ),
                                                    child: const Text(
                                                      "Cancel",
                                                      style: TextStyle(
                                                        color: iconColor,
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    style: TextButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.deepPurple,
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 10,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          context,
                                                          true,
                                                        ),
                                                    child: const Text(
                                                      "Confirm",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirm == true) {
                                              await markAsDelivered(
                                                doc.id,
                                                doc.data()
                                                    as Map<String, dynamic>,
                                                doc,
                                              );
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      "Order marked as Delivered",
                                                      style: TextStyle(
                                                        color: textColor,
                                                      ),
                                                    ),
                                                    backgroundColor:
                                                        accentColor,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            "Mark as Delivered",
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: accentColor,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6,
                                              horizontal: 12,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 13,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),
                                    SizedBox(
                                      width: 140,
                                      height: 40,
                                      child: OutlinedButton.icon(
                                        onPressed: () async {
                                          String reason = "";
                                          final confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              backgroundColor: Color(
                                                0xFF1E293B,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              title: const Text(
                                                "Cancel Order",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Text(
                                                    "Provide a reason for cancellation:",
                                                    style: TextStyle(
                                                      color: textColor,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 10),
                                                  TextField(
                                                    onChanged: (v) =>
                                                        reason = v,
                                                    decoration: InputDecoration(
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      hintText: "Enter reason",
                                                      hintStyle:
                                                          const TextStyle(
                                                            color: iconColor,
                                                          ),
                                                      filled: true,
                                                      fillColor: Colors.white10,
                                                    ),
                                                    style: const TextStyle(
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text(
                                                    "Cancel",
                                                    style: TextStyle(
                                                      color: iconColor,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                    backgroundColor: Colors
                                                        .deepPurple,  
                                                    foregroundColor: Colors
                                                        .white, 
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 16,
                                                          vertical: 10,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    if (reason.trim().isEmpty) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                            "Reason cannot be empty",
                                                            style: TextStyle(
                                                              color: textColor,
                                                            ),
                                                          ),
                                                          backgroundColor:
                                                              Colors.redAccent,
                                                        ),
                                                      );
                                                      return;
                                                    }
                                                    Navigator.pop(
                                                      context,
                                                      true,
                                                    );
                                                  },
                                                  child: const Text(
                                                    "Confirm",
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true &&
                                              reason.trim().isNotEmpty) {
                                            await cancelOrder(doc, reason);
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Order cancelled successfully",
                                                    style: TextStyle(
                                                      color: textColor,
                                                    ),
                                                  ),
                                                  backgroundColor: accentColor,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.cancel_outlined,
                                          color: Colors.white,
                                        ),
                                        label: const Text("Cancel Order"),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors
                                              .white, 

                                          side: const BorderSide(
                                            color: Colors.white,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 10,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
