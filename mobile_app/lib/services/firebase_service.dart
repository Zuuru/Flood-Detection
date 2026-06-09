import 'dart:async';

import '../models/flood_data.dart';

class FirebaseService {
  final StreamController<FloodData> _controller = StreamController<FloodData>.broadcast();
  Timer? _timer;
  int _index = 0;

  FirebaseService() {
    _sendSampleData();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _sendSampleData();
    });
  }

  Stream<FloodData> get floodDataStream => _controller.stream;

  void _sendSampleData() {
    final samples = <FloodData>[
      FloodData(distanceCm: 180, timestamp: DateTime.now()),
      FloodData(distanceCm: 110, timestamp: DateTime.now()),
      FloodData(distanceCm: 55, timestamp: DateTime.now()),
      FloodData(distanceCm: 80, timestamp: DateTime.now()),
    ];

    _controller.add(samples[_index % samples.length]);
    _index += 1;
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
