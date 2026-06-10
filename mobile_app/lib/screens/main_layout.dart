import 'dart:ui';
import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const LogsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Stack is used so the navbar can float over the content
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: _buildGlassNavbar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassNavbar() {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 75,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E).withValues(alpha: 0.65), // Semi-transparent base
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0xFF3E484E).withValues(alpha: 0.5), // Subtle stroke
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildNavItem(icon: Icons.home_filled, label: 'Home', index: 0),
                const SizedBox(width: 8),
                _buildNavItem(icon: Icons.format_list_bulleted, label: 'Logs', index: 1),
                const SizedBox(width: 8),
                _buildNavItem(icon: Icons.settings, label: 'Settings', index: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isActive = _currentIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFF8EF) : Colors.transparent,
          borderRadius: BorderRadius.circular(27.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              key: ValueKey<bool>(isActive),
              color: isActive ? const Color(0xFF012D1D) : const Color(0xFFFFF8EF),
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                color: isActive ? const Color(0xFF012D1D) : const Color(0xFFFFF8EF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
