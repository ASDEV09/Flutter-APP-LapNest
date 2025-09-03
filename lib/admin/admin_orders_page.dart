import 'package:app/admin/admin_tabs.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app/admin/app_drawer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/email.dart';

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({Key? key}) : super(key: key);

  @override
  _AdminOrdersPageState createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
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

  Future<String> getUserEmail(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return userDoc['email'] ?? 'Unknown';
    } catch (e) {
      return 'Unknown';
    }
  }

  Future<void> markOrderAsShipped(
    BuildContext context,
    String docId,
    Map<String, dynamic> orderData,
  ) async {
    try {
      final List<dynamic> itemsWithProductId = orderData['items'] ?? [];

      // ---- Update order data (status + shippedAt) ----
      final updatedOrderData = {
        ...orderData,
        'status': 'shipped', // ✅ change status
        'shippedAt': Timestamp.now(), // ✅ add shipped time
        'orderId': docId,
        'items': itemsWithProductId,
      };

      // ✅ Update the order inside "orders" collection
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(docId)
          .update(updatedOrderData);

      // ---- Get Email from USERS collection ----
      String userId = orderData['userId'];
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      final userEmail = userDoc.data()?['email'] ?? "unknown@email.com";
      final customerName = userDoc.data()?['userName'] ?? "Customer";

      // ---- Items ko HTML table banado ----
      String itemsTable = itemsWithProductId.map((item) {
        final title = item['title'] ?? "Unknown Item";
        final quantity = item['quantity'] ?? 1; // default 1 agar null hai
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

      // ---- Send Email ----
      await EmailService.sendShippedConfirmationEmail(
        toEmail: userEmail,
        customerName: customerName,
        status: "Shipped",
        orderId: docId,
        items: List<Map<String, dynamic>>.from(itemsWithProductId),
        totalBill: totalBill,
        itemsTable: itemsTable,
        firstline: "🚚 On the Way!",
        secline:
            "Your package is now on the way and should arrive within 2–5 business days.",
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order marked as shipped & email sent")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error shipping order: $e")));
    }
  }

  Future<void> cancelOrder(DocumentSnapshot order, String reason) async {
    final data = order.data() as Map<String, dynamic>;
    try {
      await FirebaseFirestore.instance.collection('orderCancelled').add({
        ...data,
        'cancelledAt': Timestamp.now(),
        'cancelledBy': "Admin",
        'cancellationReason': reason,
        'orderId': order.id,
      });
      await order.reference.delete();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error cancelling order: $e")));
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

                // Items list
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
    final backgroundColor = const Color(0xFF0A0F2C);
    final cardColor = const Color(0xFF1E293B);
    final textColor = const Color(0xFFD3D3D3);
    final iconColor = Colors.grey;

    if (loadingRole) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (userRole != 'admin') {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text("Access Denied"),
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                'All Orders',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            ),
          ),
        ),
      ),
      drawer: AppDrawer(user: currentUser),
      body: Column(
        children: [
          const AdminOrderTabsWidget(selectedIndex: 0),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search by Order ID...",
                hintStyle: TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('orders')
                  .where(
                    'status',
                    isEqualTo: 'pending',
                  ) // ✅ sirf pending orders
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No orders found.',
                      style: TextStyle(color: textColor),
                    ),
                  );
                }

                // 🔎 Apply Order ID Search
                final orders = snapshot.data!.docs.where((doc) {
                  final orderId = doc.id.toLowerCase();
                  return searchQuery.isEmpty ||
                      orderId.contains(searchQuery); // partial match bhi
                }).toList();

                if (orders.isEmpty) {
                  return Center(
                    child: Text(
                      "No matching order found",
                      style: TextStyle(color: textColor),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final data = order.data() as Map<String, dynamic>? ?? {};
                    final orderId = order.id;
                    final recipientName = data['name'] ?? 'Unknown';

                    final userId = data['userId'] ?? '';
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
                          color: const Color(0xFF1B1F36), // tumhara card color
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 👇 Image section
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child:
                                          (data['items'] != null &&
                                              data['items'].isNotEmpty)
                                          ? Image.network(
                                              data['items'][0]['image'], // Firestore ka pehla image
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

                                    // 👇 Texts section
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
                                            "Date: ${timestamp?.toLocal().toString().split(' ')[0] ?? ''}",
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

                                          // ---------------- PAGE 1 : Invoice ----------------
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

                                          // ---------------- PAGE 2 : Shipping Label ----------------
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

                                          // Show PDF (download/print)
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
                                const SizedBox(height: 8),

                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IntrinsicWidth(
                                      child: SizedBox(
                                        height: 40,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final confirmed = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                backgroundColor: cardColor,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                title: Text(
                                                  "Confirm Shipping",
                                                  style: TextStyle(
                                                    color: textColor,
                                                  ),
                                                ),
                                                content: Text(
                                                  "Order marked as shipped",
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
                                                    child: Text(
                                                      "Cancel",
                                                      style: TextStyle(
                                                        color: iconColor,
                                                      ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    style: TextButton.styleFrom(
                                                      backgroundColor: Colors
                                                          .deepPurple, // 🔴 Button ka background
                                                      foregroundColor: Colors
                                                          .white, // ⚪ Text ka color
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
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );

                                            if (confirmed == true) {
                                              markOrderAsShipped(
                                                context,
                                                order.id,
                                                data,
                                              );
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.local_shipping_outlined,
                                            color: Colors.white,
                                          ),
                                          label: const Text(
                                            "Mark as Shipped",
                                            softWrap:
                                                false, // 👈 force single line
                                            overflow: TextOverflow
                                                .ellipsis, // 👈 agar text fit na ho to ...
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.deepPurple,
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
                                              backgroundColor: cardColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              title: Text(
                                                "Cancel Order",
                                                style: TextStyle(
                                                  color: textColor,
                                                ),
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
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
                                                      hintStyle: TextStyle(
                                                        color: iconColor,
                                                      ),
                                                      filled: true,
                                                      fillColor: Colors.white10,
                                                    ),
                                                    style: TextStyle(
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
                                                  child: Text(
                                                    "Back",
                                                    style: TextStyle(
                                                      color: iconColor,
                                                    ),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    if (reason.trim().isEmpty) {
                                                      ScaffoldMessenger.of(
                                                        context,
                                                      ).showSnackBar(
                                                        SnackBar(
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
                                                      color: Colors.redAccent,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                          if (confirm == true &&
                                              reason.trim().isNotEmpty) {
                                            await cancelOrder(order, reason);
                                            if (mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "Order cancelled successfully",
                                                    style: TextStyle(
                                                      color: textColor,
                                                    ),
                                                  ),
                                                  backgroundColor:
                                                      Colors.redAccent,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.cancel_outlined),
                                        label: const Text("Cancel Order"),
                                        style: OutlinedButton.styleFrom(
                                          // side: const BorderSide(color: Colors.red),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 6,
                                            horizontal: 10,
                                          ),
                                          textStyle: const TextStyle(
                                            fontSize: 14,
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
