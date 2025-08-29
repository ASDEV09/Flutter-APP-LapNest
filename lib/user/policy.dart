import 'package:app/user/ProfilePage.dart';
import 'package:flutter/material.dart';
import 'package:app/user/AllProducts.dart';
import 'package:app/user/cart_page.dart';
import 'package:app/user/wishlistPage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'custom_bottom_nav_bar.dart';

class PoliciesPage extends StatefulWidget {
  const PoliciesPage({super.key});

  @override
  State<PoliciesPage> createState() => _PoliciesPageState();
}

class _PoliciesPageState extends State<PoliciesPage> {
  int _selectedIndex = 3; // profile ki tarha index maintain karna

  void _onBottomNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const AllProducts()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const WishlistPage()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CartPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0F2C), // ✅ Dark background
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(), // Go back
        ),
        title: Text(
          'Our Policies',
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


      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPolicySection(
            "Purchase Policy",
            "All laptops and accessories sold on our platform are 100% genuine and sealed pack. "
            "Customers are advised to review specifications carefully before purchasing. "
            "Orders once confirmed cannot be modified.",
          ),
          _buildPolicySection(
            "Shipping & Delivery",
            "We provide secure and fast shipping across Pakistan. "
            "Estimated delivery time is 3–5 working days for major cities and 5–7 days for other areas. "
            "Tracking details will be shared once the order is dispatched.",
          ),
          _buildPolicySection(
            "7-Day Return & Refund Policy",
            "Customers can return products within 7 days of delivery if they are unused, "
            "sealed, and in original packaging. "
            "Refunds will be processed within 5–7 working days after quality inspection. "
            "Opened or physically damaged products will not be accepted.",
          ),
          _buildPolicySection(
            "Warranty Policy",
            "All laptops come with official 1-year manufacturer warranty unless mentioned otherwise. "
            "Warranty claims are handled by the respective brand service centers.",
          ),
          _buildPolicySection(
            "Privacy Policy",
            "We respect your privacy. Your personal information is kept secure "
            "and is never shared with third parties without consent. "
            "We only use your information to process orders and improve services.",
          ),
          _buildPolicySection(
            "Contact & Support",
            "For any issues or queries, please reach out to our support team:\n\n"
            "📧 Email: support@yourapp.com\n"
            "📞 Phone: +92 300 1234567\n"
            "🕒 Timings: 9 AM – 9 PM (Mon–Sat)",
          ),
        ],
      ),

      // ✅ Bottom nav bar same as ProfilePage
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onBottomNavTapped,
      ),
    );
  }

  // 🔹 Helper Widget for section box with border + background
  Widget _buildPolicySection(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // ✅ Inside background
        border: Border.all(color: Colors.grey, width: 1), // ✅ Grey border
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
