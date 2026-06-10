import 'package:flutter/material.dart';

import 'screens/main_layout.dart'; // Import MainLayout

void main() {
  runApp(const FloodDashboardApp());
}

class FloodDashboardApp extends StatelessWidget {
  const FloodDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flood Detection Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MainLayout(), // Set the wrapper with Navbar as home
    );
  }
}

