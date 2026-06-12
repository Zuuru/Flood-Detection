class NotificationData {
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isUnread;

  NotificationData({
    required this.title,
    required this.body,
    required this.timestamp,
    this.isUnread = true,
  });

  factory NotificationData.fromMap(Map<dynamic, dynamic> map) {
    final timestampRaw = map['timestamp'];
    DateTime parsedTimestamp;
    
    if (timestampRaw is int) {
      parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampRaw);
    } else {
      parsedTimestamp = DateTime.now();
    }

    return NotificationData(
      title: map['title'] ?? 'Notification',
      body: map['body'] ?? '',
      timestamp: parsedTimestamp,
      isUnread: map['isUnread'] ?? true,
    );
  }
}
