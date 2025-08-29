// import 'package:app/admin/addproduct.dart';
// import 'package:app/admin/adminDeliveredOrders.dart';
// import 'package:app/admin/activeproduct.dart';
// import 'package:app/admin/admin_conversations.dart';
// import 'package:app/signInScreen.dart';
// import 'package:app/signUpScreen.dart';
// import 'package:app/user/AllProducts.dart';
// import 'package:app/user/ProfilePage.dart';
// import 'package:app/user/chat_screen.dart';
// // import 'package:app/user/homepageScreen.dart';
// import 'package:app/user/myDeliveredOrders.dart';
// import 'package:app/user/myReview.dart';
// // import 'package:app/signup.dart';
// import 'package:app/splashScreen.dart';
// import 'package:app/user/cart_page.dart';
// // import 'package:app/home.dart';
// // import 'package:app/login.dart';
// // import 'package:app/user/EditProfilePage.dart';
// import 'package:app/admin/adminOrderCancle.dart';
// import 'package:app/user/my_orders.dart';
// import 'package:app/admin/adminShippedOrders.dart';
// import 'package:app/user/myShippedOrders.dart';
// // import 'package:app/my_reviews_page.dart';
// import 'package:app/admin/admin_orders_page.dart';
// import 'package:app/user/wishlistPage.dart';
// import 'package:app/admin/adminScreen.dart';
// import 'package:app/signUpScreen.dart';
import 'package:app/admin/adminScreen.dart';
// import 'package:app/splashScreen.dart';
import 'package:app/user/AllProducts.dart';
import 'package:app/admin/addoffer.dart';
import 'package:app/user/myCancelledOrders.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:app/firebase_options.dart';
import 'package:app/user/sort_filter_screen.dart';
import 'package:app/admin/allproducts.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    DevicePreview(
      enabled: true, // false in production
      builder: (context) => MyApp(),
    ),
  );
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      useInheritedMediaQuery: true,
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      initialRoute: '/allproducts', // Use this instead of `home`
      routes: {
        // '/splash': (context) => SplashScreen(),
        '/cancle': (context) => MyCancelledOrders(),
        
        // '/signup': (context) => SignUpScreen(),
        // '/login': (context) => SignInScreen(),
        // '/adminpage': (context) => AdminOrdersPage(),
        // // '/homepage' : (context)=> Homepagescreen(),
        // '/products': (context) => Addproduct(),
        '/allproducts': (context) => AllProducts(),
        '/ProductsList': (context) => ProductsList(),
        '/admin': (context) => AdminPanelScreen(),
        '/filter': (context) => const SortFilterScreen(),
        '/addoffer': (context) => const AddOffer(),
        // // '/home': (context) => HomePage(),
        // '/cart': (context) => const CartPage(),
        // '/wishlist': (context) => WishlistPage(),
        // '/profile': (context) => const ProfilePage(),
        // '/myorders': (context) => const MyOrdersPage(), // <-- Ye line add karo
        // '/ordercancle': (context) => const AdminCancelledOrdersPage(), // <-- Ye line add karo
        // '/myShippedOrders': (context) => const MyShippedOrders(), // <-- Ye line add karo
        // '/adminShippedOrders': (context) => const AdminShippedOrders(), // <-- Ye line add karo
        // '/adminDeliveredOrders': (context) => const AdminDeliveredOrdersPage(), // <-- Ye line add karo
        // '/myDeliveredOrders': (context) => const DeliveredOrdersPendingReviews(), // <-- Ye line add karo
        // '/myre': (context) => const MyReview(), // <-- Ye line add karo
        // '/adminscreen': (context) => const AdminPanelScreen(), // <-- Ye line add karo
        // '/productlist': (context) => const ProductsList(), // <-- Ye line add karo
        // '/chat': (context) => ChatScreen(), // <-- Ye line add karo
        // '/adminchat': (context) =>  AdminConversations(), // <-- Ye line add karo
      },
    );
  }
}
