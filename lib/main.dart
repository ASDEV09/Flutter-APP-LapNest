import 'package:app/admin/adminScreen.dart';
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
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(DevicePreview(enabled: true, builder: (context) => MyApp()));
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
      initialRoute: '/allproducts',
      routes: {
        '/cancle': (context) => MyCancelledOrders(),
        '/allproducts': (context) => AllProducts(),
        '/ProductsList': (context) => ProductsList(),
        '/admin': (context) => AdminPanelScreen(),
        '/filter': (context) => const SortFilterScreen(),
        '/addoffer': (context) => const AddOffer(),
      },
    );
  }
}
