import 'package:flutter/material.dart';
import 'profile_screen.dart'; // 👈 Make sure you import the correct file
// import 'fruit_predictor_page.dart'; // You can keep this for later navigation

void main() {
  runApp(const FruitApp());
}

class FruitApp extends StatelessWidget {
  const FruitApp({super.key}); // Add constructor

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Fruit Nutrition App',
      debugShowCheckedModeBanner: false,
      home: ProfileScreen(), // 👈 Start app with ProfileScreen
    );
  }
}
