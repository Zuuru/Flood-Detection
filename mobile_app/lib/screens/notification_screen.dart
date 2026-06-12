import 'package:flutter/material.dart';

import '../services/firebase_service.dart';
import '../models/notification_data.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static final FirebaseService _firebaseService = FirebaseService();

  // Colors from pubspec.yaml & design system
  static const Color colorBackground = Colors.black;
  static const Color colorCard = Color(0xFF1C1C1E);
  static const Color colorPrimary = Color(0xFF64D2FF);
  static const Color colorNeutral = Color(0xFF73787B);
  static const Color colorTextPrimary = Color(0xFFDFE3E7);
  static const Color colorAvatarBg = Color(0xFFFFB4AB); // Using the error/pink color to match the pink avatar in the image

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: StreamBuilder<List<NotificationData>>(
                stream: _firebaseService.notificationsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notifications = snapshot.data ?? [];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Previously',
                          style: TextStyle(
                            color: colorTextPrimary,
                            fontSize: 14,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (notifications.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'Belum ada notifikasi.',
                                style: TextStyle(
                                  color: colorNeutral,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                          )
                        else
                          ...notifications.map((notif) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: GestureDetector(
                                onTap: () => _showNotificationDetail(context, notif),
                                child: _buildNotificationCard(
                                  title: notif.title,
                                  date: _formatDate(notif.timestamp),
                                  body: notif.body,
                                  isUnread: notif.isUnread,
                                ),
                              ),
                            );
                          }),
                        const SizedBox(height: 32),
                        _buildFooter(),
                        const SizedBox(height: 32),
                      ],
                    ),
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  void _showNotificationDetail(BuildContext context, NotificationData notif) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorPrimary.withOpacity(0.3), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header icon + title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        notif.title,
                        style: const TextStyle(
                          color: colorTextPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Divider
                Divider(color: colorNeutral.withOpacity(0.3)),
                const SizedBox(height: 12),
                // Body
                Text(
                  notif.body,
                  style: const TextStyle(
                    color: colorTextPrimary,
                    fontSize: 14,
                    fontFamily: 'Inter',
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                // Timestamp
                Row(
                  children: [
                    const Icon(Icons.access_time, color: colorNeutral, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(notif.timestamp),
                      style: const TextStyle(
                        color: colorNeutral,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Close button
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: colorPrimary.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        color: colorPrimary,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: colorTextPrimary),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const Text(
            'Notifications',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorTextPrimary,
            ),
          ),
          const SizedBox(width: 48), // Spacer to keep title centered
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String title,
    required String date,
    required String body,
    required bool isUnread,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: colorAvatarBg,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'V.',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: colorTextPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Inter',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date,
                      style: const TextStyle(
                        color: colorNeutral,
                        fontSize: 12,
                        fontFamily: 'Inter',
                      ),
                    ),
                    if (isUnread) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: colorPrimary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: colorNeutral,
                    fontSize: 13,
                    fontFamily: 'Inter',
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text(
          'Missing notifications?',
          style: TextStyle(
            color: colorTextPrimary,
            fontSize: 13,
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {},
          child: const Text(
            'Go to historical notifications.',
            style: TextStyle(
              color: colorPrimary,
              fontSize: 13,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }
}
