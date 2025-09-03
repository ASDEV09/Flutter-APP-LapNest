// import 'dart:async';
// import 'package:app/signUpScreen.dart';
// import 'package:flutter/material.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);

//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     Timer(const Duration(seconds: 3), () {
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const SignUpScreen()),
//       );
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Color(0xFF101010),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Container(
//               width: 200,
//               height: 200,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(
//                   color: Colors.black,
//                   width: 2,
//                 ), // Optional: border color & width
//               ),
//               child: ClipOval(
//                 child: Image.asset(
//                   'assets/images/lapnest-logo1.png',
//                   fit: BoxFit.cover,
//                 ),
//               ),
//             ),

//             const SizedBox(height: 20),

//             /// Tagline
//             const Text(
//               'Your Laptop, Your Nest',
//               style: TextStyle(
//                 fontSize: 22,
//                 fontWeight: FontWeight.w900,
//                 color: Color.fromARGB(255, 255, 255, 255),
//                 fontFamily: 'Roboto',
//               ),
//             ),

//             const SizedBox(height: 40),

//             /// Welcome Text
//             const Text(
//               'Welcome to Lapnest',
//               style: TextStyle(
//                 fontSize: 26,
//                 fontWeight: FontWeight.bold,
//                 color: Colors.white,
//                 fontFamily: 'Roboto',
//               ),
//             ),

//             const SizedBox(height: 15),

//             /// Subtitle
//             const Text(
//               'The best E-commerce app of the century\nfor your tech needs!',
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 fontSize: 18,
//                 fontStyle: FontStyle.italic,
//                 color: Colors.white,
//                 fontFamily: 'Roboto',
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
