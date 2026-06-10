import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../models/flood_data.dart';

class FirebaseService {
  final DatabaseReference _sensorRef = FirebaseDatabase.instance.ref('sensor');
  late StreamController<FloodData> _controller;

  double _warningThreshold = 150.0;
  double _emergencyThreshold = 80.0;
  
  // Cache the latest sensor data so we can re-emit when config changes
  double? _lastDistanceCm;
  DateTime? _lastTimestamp;

  FirebaseService() {
    _controller = StreamController<FloodData>.broadcast();

    _listenToSensorData();
  }

  Stream<FloodData> get floodDataStream => _controller.stream;

  void _listenToSensorData() {
    _sensorRef.onValue.listen((DatabaseEvent event) {
      if (event.snapshot.value != null) {
        try {
          final data = event.snapshot.value as Map<dynamic, dynamic>;
          _lastDistanceCm = (data['jarak_cm'] as num).toDouble();
          final timestampRaw = data['timestamp'];
          
          if (timestampRaw is int) {
            _lastTimestamp = DateTime.fromMillisecondsSinceEpoch(timestampRaw);
          } else {
            _lastTimestamp = DateTime.now();
          }

          final floodData = FloodData(
            distanceCm: _lastDistanceCm!,
            timestamp: _lastTimestamp!,
            warningThreshold: _warningThreshold,
            emergencyThreshold: _emergencyThreshold,
          );
          _controller.add(floodData);
        } catch (e) {
          print('Error parsing Firebase sensor data: $e');
        }
      }
    }, onError: (error) {
      print('Firebase listener error: $error');
    });
  }

  Future<List<FloodData>> getHistory({int limit = 50}) async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref('history')
          .orderByKey()
          .limitToLast(limit)
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final List<FloodData> historyList = [];
        data.forEach((key, value) {
          try {
            final entry = value as Map<dynamic, dynamic>;
            final distanceCm = (entry['jarak_cm'] as num).toDouble();
            final timestampRaw = entry['timestamp'];
            
            DateTime timestamp;
            if (timestampRaw is int) {
              timestamp = DateTime.fromMillisecondsSinceEpoch(timestampRaw);
            } else {
              timestamp = DateTime.now();
            }

            historyList.add(FloodData(
              distanceCm: distanceCm,
              timestamp: timestamp,
            ));
          } catch (e) {
            print('Error parsing history entry: $e');
          }
        });
        
        // Sort descending (newest first)
        historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return historyList;
      }
    } catch (e) {
      print('Error getting history: $e');
    }
    return [];
  }

  Stream<List<FloodData>> get historyStream {
    // Menghitung timestamp 6 bulan yang lalu (180 hari)
    final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180)).millisecondsSinceEpoch;
    
    return FirebaseDatabase.instance
        .ref('history')
        .orderByChild('timestamp')
        .startAt(sixMonthsAgo)
        .onValue
        .map((event) {
      if (event.snapshot.value == null) return [];
      
      final Map<dynamic, dynamic> values = event.snapshot.value as Map<dynamic, dynamic>;
      List<FloodData> historyList = [];
      
      values.forEach((key, value) {
        try {
          final entry = value as Map<dynamic, dynamic>;
          final distanceCm = (entry['jarak_cm'] as num).toDouble();
          final timestampRaw = entry['timestamp'];
          
          DateTime timestamp;
          if (timestampRaw is int) {
            timestamp = DateTime.fromMillisecondsSinceEpoch(timestampRaw);
          } else {
            timestamp = DateTime.now();
          }

          historyList.add(FloodData(
            distanceCm: distanceCm,
            timestamp: timestamp,
            warningThreshold: _warningThreshold,
            emergencyThreshold: _emergencyThreshold,
          ));
        } catch (e) {
          print('Error parsing history stream entry: $e');
        }
      });
      
      // Sort descending (newest first)
      historyList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return historyList;
    });
  }

  Future<Map<String, dynamic>> getConfig() async {
    try {
      final snapshot = await FirebaseDatabase.instance.ref('config').get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }
    } catch (e) {
      print('Error getting config: $e');
    }
    return {};
  }

  Future<void> updateConfig(Map<String, dynamic> newConfig) async {
    try {
      await FirebaseDatabase.instance.ref('config').update(newConfig);
    } catch (e) {
      print('Error updating config: $e');
    }
  }

  void dispose() {
    _controller.close();
  }
}
