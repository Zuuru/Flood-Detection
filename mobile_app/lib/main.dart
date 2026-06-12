import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/main_layout.dart'; // Import MainLayout
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().initialize();
  // Auto-subscribe to flood alerts topic so notifications work without opening Settings
  await NotificationService().subscribeToTopic('flood_alerts');
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

