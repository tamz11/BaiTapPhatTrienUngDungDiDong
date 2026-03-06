import 'package:flutter/material.dart';

import 'screens/product_list_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TH3 - API Product App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B7F8B)),
        scaffoldBackgroundColor: const Color(0xFFF7F9FB),
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      home: const ProductListScreen(),
    );
  }
}
