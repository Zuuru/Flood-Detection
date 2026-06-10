import 'package:flutter/material.dart';

enum FloodStatus { safe, warning, danger }

class FloodData {
  final double distanceCm;
  final DateTime timestamp;
  final double warningThreshold;
  final double emergencyThreshold;

  FloodData({
    required this.distanceCm,
    required this.timestamp,
    this.warningThreshold = 150.0,
    this.emergencyThreshold = 80.0,
  });

  FloodStatus get status {
    if (distanceCm <= emergencyThreshold) return FloodStatus.danger;
    if (distanceCm <= warningThreshold) return FloodStatus.warning;
    return FloodStatus.safe;
  }

  String get statusLabel {
    switch (status) {
      case FloodStatus.danger:
        return 'Evakuasi';
      case FloodStatus.warning:
        return 'Siaga';
      case FloodStatus.safe:
        return 'Aman';
    }
  }

  Color get statusColor {
    switch (status) {
      case FloodStatus.danger:
        return Colors.red;
      case FloodStatus.warning:
        return Colors.orange;
      case FloodStatus.safe:
        return Colors.green;
    }
  }

  String get buzzerState {
    switch (status) {
      case FloodStatus.danger:
        return 'Beep cepat / terus';
      case FloodStatus.warning:
        return 'Beep lambat';
      case FloodStatus.safe:
        return 'Off';
    }
  }

  String get ledState {
    switch (status) {
      case FloodStatus.danger:
        return 'Merah';
      case FloodStatus.warning:
        return 'Kuning';
      case FloodStatus.safe:
        return 'Hijau';
    }
  }

  String get levelLabel {
    switch (status) {
      case FloodStatus.danger:
        return 'Kritis';
      case FloodStatus.warning:
        return 'Mendekati Bahaya';
      case FloodStatus.safe:
        return 'Aman';
    }
  }

  double get dangerProgress {
    const maxDistance = 250.0;
    final value = (maxDistance - distanceCm).clamp(0, maxDistance);
    return value / maxDistance;
  }
}
