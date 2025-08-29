import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

class AddressFormPage extends StatefulWidget {
  final String? initialName;
  final String? initialAddress;
  final String? initialContact;
  final String? initialDeliveryType;

  const AddressFormPage({
    Key? key,
    this.initialName,
    this.initialAddress,
    this.initialContact,
    this.initialDeliveryType,
  }) : super(key: key);

  @override
  State<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends State<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _addrCtrl;
  late TextEditingController _contactCtrl;
  String _deliveryType = 'Home';

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName ?? '');
    _addrCtrl = TextEditingController(text: widget.initialAddress ?? '');
    _contactCtrl = TextEditingController(text: widget.initialContact ?? '');
    _deliveryType = widget.initialDeliveryType ?? 'Home';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('addresses')
        .doc('default')
        .set({
          'recipientName': _nameCtrl.text,
          'address': _addrCtrl.text,
          'contactNumber': _contactCtrl.text,
          'deliveryType': _deliveryType,
        });

    Navigator.pop(context, true); // Return success
  }

  InputDecoration inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.grey),
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFF0A0F2C),
      hintStyle: TextStyle(color: Colors.grey.shade500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.initialName != null;

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
        onPressed: () => Navigator.of(context).pop(), // go back
      ),
      title: Text(
        isEdit ? 'Edit Address' : 'Add Address',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
    ),
  ),
),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(
                      color: Colors.white, // ✅ text ka color white
                    ),
                    decoration: inputDecoration(
                      'Recipient Name',
                      Icons.person_outline,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _addrCtrl,
                    style: const TextStyle(
                      color: Colors.white, // ✅ text ka color white
                    ),
                    decoration: inputDecoration(
                      'Address',
                      Icons.location_on_outlined,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _contactCtrl,
                    style: const TextStyle(
                      color: Colors.white, // ✅ text ka color white
                    ),
                    keyboardType: TextInputType.phone,
                    decoration: inputDecoration(
                      'Contact Number',
                      Icons.phone_outlined,
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _deliveryType,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.delivery_dining,
                        color: Colors.grey, // icon bhi yellow kar diya
                      ),
                      filled: true,
                      fillColor: const Color(0xFF0A0F2C), // ✅ background red
                      hintText: 'Delivery Type',
                      hintStyle: const TextStyle(
                        color: Colors.white,
                      ), // ✅ hint yellow
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                    ),
                    dropdownColor: Color(
                      0xFF0A0F2C,
                    ), // ✅ dropdown ka background bhi red
                    items: ['Home', 'Office'].map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: Colors.white,
                          ), // ✅ text yellow
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _deliveryType = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Save Address',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
