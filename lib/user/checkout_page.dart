import 'package:app/services/email.dart';
import 'package:app/user/place_order_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'address_form_page.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckoutPage extends StatefulWidget {
  final List<QueryDocumentSnapshot> items;
  final double total;

  const CheckoutPage({Key? key, required this.items, required this.total})
    : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String? _name, _addr, _contact, _deliveryType;
  final String _selectedPayment = 'Cash on Delivery';

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .doc('default')
        .get();

    if (!mounted) return;
    setState(() {
      final d = snap.data();
      _name = d?['recipientName'];
      _addr = d?['address'];
      _contact = d?['contactNumber'];
      _deliveryType = d?['deliveryType'];
    });
  }

  Future<void> _openForm({bool edit = false}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddressFormPage(
          initialName: edit ? _name : null,
          initialAddress: edit ? _addr : null,
          initialContact: edit ? _contact : null,
          initialDeliveryType: edit ? _deliveryType : null,
        ),
      ),
    );
    _fetchAddress();
  }

Future<void> _placeOrder() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  // ✅ Cart items fetch karo
  final cartItems = await FirebaseFirestore.instance
      .collection('carts')
      .doc(user.uid)
      .collection('items')
      .get();

  // ✅ Har item ka asli productId use karo (jo cart me already save hona chahiye)
  final items = cartItems.docs.map((doc) {
    final data = doc.data();
    return {
      ...data,
      'cartItemId': doc.id, // 👈 Ab sirf reference ke liye
    };
  }).toList();

  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  final userEmail = userDoc.data()?['email'] ?? "unknown@email.com";
  final customerName = userDoc.data()?['userName'] ?? "Customer";

  final orderData = {
    'userId': user.uid,
    'name': _name,
    'address': _addr,
    'contact': _contact,
    'status': "pending",
    'deliveryType': _deliveryType,
    'paymentMethod': _selectedPayment,
    'total': widget.total,
    'timestamp': FieldValue.serverTimestamp(),
    'items': items,
  };

  final orderRef =
      await FirebaseFirestore.instance.collection('orders').add(orderData);
  final orderId = orderRef.id;

  // --- 📉 Reduce stock from products collection
  for (var item in items) {
    final productId = item['productId']; // 👈 ab asli products doc.id use ho raha
    final orderedQty = item['quantity'] ?? 1;

    final productRef =
        FirebaseFirestore.instance.collection('products').doc(productId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final productSnap = await transaction.get(productRef);

      if (productSnap.exists) {
        final currentStock = (productSnap['quantity'] ?? 0) as int;
        final newStock = currentStock - orderedQty;

        if (newStock >= 0) {
          transaction.update(productRef, {'quantity': newStock});
        } else {
          throw Exception("Not enough stock for ${item['title']}");
        }
      }
    });
  }

  // --- 📧 Email
  String itemsTable = items.map((item) {
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

  double totalBill = (orderData['total'] as num).toDouble();
  await EmailService.sendShippedConfirmationEmail(
    toEmail: userEmail,
    customerName: customerName,
    status: "Pending",
    orderId: orderId,
    items: items,
    totalBill: totalBill,
    itemsTable: itemsTable,
    firstline: "🎉 Order Placed Successfully!",
    secline:
        "Your order has been placed successfully. We'll keep you updated on the status.",
  );

  // --- 🗑️ Empty Cart
  for (var doc in cartItems.docs) {
    await doc.reference.delete();
  }

  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Order placed successfully!')),
  );

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => const PlaceOrderPage()),
  );
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final buttonBgColor = isDark ? Colors.white : Colors.black;
    final buttonTextColor = isDark
        ? const Color.fromARGB(255, 167, 24, 24)
        : Colors.white;

    final hasAddress =
        _name != null &&
        _addr != null &&
        _contact != null &&
        _deliveryType != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2C),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.transparent,
            border: Border(bottom: BorderSide(color: Colors.white, width: 1.0)),
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              'Checkout',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.location_on_outlined, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: hasAddress
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$_name',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$_addr',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Contact: $_contact',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'No address added',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                  ),
                  TextButton(
                    onPressed: () => _openForm(edit: hasAddress),
                    child: Text(
                      hasAddress ? 'Edit' : 'Add',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: widget.items.length,
              itemBuilder: (_, i) {
                final m = widget.items[i].data() as Map<String, dynamic>;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0F2C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child:
                            (m['image'] != null &&
                                m['image'].toString().isNotEmpty)
                            ? Image.network(
                                m['image'], 
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Image.asset(
                                      'assets/placeholder.png',
                                      width: 60,
                                      height: 60,
                                    ),
                              )
                            : Image.asset(
                                'assets/placeholder.png',
                                width: 60,
                                height: 60,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              m['title'] ?? '',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rs ${m['price']}  •  Qty: ${m['quantity'] ?? 1}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0F2C),
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Method: $_selectedPayment',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total: Rs ${widget.total.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'All taxes included',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        side: BorderSide(color: buttonBgColor),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                      ),
                      onPressed: () {
                        if (hasAddress) {
                          _placeOrder();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Please add address before placing order",
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        'Place Order',
                        style: GoogleFonts.poppins(
                          color: buttonTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
