import 'package:flutter/material.dart';
import 'package:mina_app/screen/Counsult_page.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const ConsultPage(), // <-- Use const now
    );
  }
}
