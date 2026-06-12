import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = true;
  // State variables for toggles
  bool _pushNotification = true;
  bool _soundSiren = false;

  // Colors based on spec
  static const Color colorBackground = Color(0xFF1C1C1E);
  static const Color colorCard = Color(0xFF1B2023);
  static const Color colorTextPrimary = Color(0xFFDFE3E7);
  static const Color colorTextNeutral = Color(0xFF8A9398);
  static const Color colorSecondary = Color(0xFF4AEB75); // Active Green
  static const Color colorInactive = Color(0xFF303538);
  static const Color colorTertiary = Color(0xFFFFD54F); // Yellow
  static const Color colorError = Color(0xFFFFB4AB); // Pink/Red

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    setState(() => _isLoading = true);
    final config = await _firebaseService.getConfig();
    if (mounted) {
      setState(() {
        _pushNotification = config['push_notification'] ?? true;
        _soundSiren = config['sound_siren'] ?? false;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveConfig() async {
    await _firebaseService.updateConfig({
      'push_notification': _pushNotification,
      'sound_siren': _soundSiren,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: colorSecondary))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildDeliveryMethodsCard(),
                    // Add bottom padding to avoid overlap with bottom navigation bar
                    const SizedBox(height: 100),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: colorTextPrimary),
          onPressed: () {
            // Handle back if necessary, but this is a bottom nav tab
          },
        ),
        const SizedBox(width: 8),
        const Text(
          'Alert Settings',
          style: TextStyle(
            color: colorTextPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryMethodsCard() {
    return Container(
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Methods',
            style: TextStyle(
              color: colorTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),
          _buildMethodToggle('Push Notification', Icons.notifications_none, _pushNotification, (val) async {
            setState(() {
              _pushNotification = val;
            });
            await _saveConfig();
            if (val) {
              await NotificationService().subscribeToTopic('flood_alerts');
            } else {
              await NotificationService().unsubscribeFromTopic('flood_alerts');
            }
          }),
          const SizedBox(height: 16),
          _buildMethodToggle('Sound Siren', Icons.volume_up_outlined, _soundSiren, (val) {
            setState(() {
              _soundSiren = val;
            });
            _saveConfig();
          }),
        ],
      ),
    );
  }

  Widget _buildMethodToggle(String title, IconData icon, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorInactive,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: colorTextPrimary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: colorTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Inter',
            ),
          ),
        ),
        CupertinoSwitch(
          value: value,
          activeColor: colorSecondary,
          trackColor: colorInactive,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
