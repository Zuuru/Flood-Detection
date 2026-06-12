import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../services/firebase_service.dart';
import '../models/flood_data.dart';
import 'notification_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final List<double> _liveDistances = [];
  late final StreamSubscription<FloodData> _subscription;

  bool _isEditMode = false;
  List<String> _widgetOrder = ['status', 'primary', 'stats', 'analysis'];

  @override
  void initState() {
    super.initState();
    _loadLayoutOrder();
    _subscription = _firebaseService.floodDataStream.listen((data) {
      if (mounted) {
        setState(() {
          _liveDistances.add(data.distanceCm);
          if (_liveDistances.length > 20) {
            _liveDistances.removeAt(0);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _firebaseService.dispose();
    super.dispose();
  }

  Future<void> _loadLayoutOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrder = prefs.getStringList('dashboard_layout');
    if (savedOrder != null && savedOrder.length == 4) {
      setState(() {
        _widgetOrder = savedOrder;
      });
    }
  }

  Future<void> _saveLayoutOrder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dashboard_layout', _widgetOrder);
  }

  Widget _buildWidgetForKey(String key, FloodData? floodData) {
    switch (key) {
      case 'status':
        return _buildStatusSection(floodData);
      case 'primary':
        return _buildPrimaryMetricCard(floodData);
      case 'stats':
        return _buildStatsGrid();
      case 'analysis':
        return StreamBuilder<List<FloodData>>(
          stream: _firebaseService.historyStream,
          builder: (context, historySnapshot) {
            final history = historySnapshot.data ?? [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnalysisSection(history),
              ],
            );
          }
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // From design
      body: SafeArea(
        child: StreamBuilder<FloodData>(
          stream: _firebaseService.floodDataStream,
          builder: (context, snapshot) {
            final floodData = snapshot.data;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 120.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  if (_isEditMode)
                    Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: Colors.transparent,
                      ),
                      child: ReorderableListView(
                        buildDefaultDragHandles: false,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex -= 1;
                          setState(() {
                            final item = _widgetOrder.removeAt(oldIndex);
                            _widgetOrder.insert(newIndex, item);
                          });
                          _saveLayoutOrder();
                        },
                        children: _widgetOrder.asMap().entries.map((entry) {
                          final index = entry.key;
                          final key = entry.value;
                          return Container(
                            key: ValueKey(key),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Expanded(child: _buildWidgetForKey(key, floodData)),
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: Icon(Icons.drag_handle, color: Colors.white, size: 32),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _widgetOrder.map((key) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _buildWidgetForKey(key, floodData),
                        );
                      }).toList(),
                    ),
                  // Bottom Nav will be handled in a separate file/wrapper
                ],
              ),
            );
          }
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const CircleAvatar(
          radius: 24,
          backgroundColor: Color(0xFF1C1C1E),
          child: Text(
            '1',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ),
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: _isEditMode ? const Color(0xFF32D74B).withValues(alpha: 0.2) : const Color(0xFF1C1C1E),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  _isEditMode ? Icons.check : Icons.dashboard_customize,
                  color: _isEditMode ? const Color(0xFF32D74B) : Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _isEditMode = !_isEditMode;
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF1C1C1E),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      '3',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection(FloodData? data) {
    final statusText = data?.statusLabel ?? 'Loading...';
    final statusColor = data?.statusColor ?? Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            children: [
              const TextSpan(text: 'Flood Level is '),
              TextSpan(
                text: statusText,
                style: TextStyle(color: statusColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryMetricCard(FloodData? data) {
    final distanceStr = data != null ? data.distanceCm.toStringAsFixed(1) : '--';
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    distanceStr,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Text(
                    ' cm',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      color: Color(0xFF73787B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Distance to Water',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF73787B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    String rateStr = '--';
    List<double> barHeights = List.filled(9, 4.0); // Default to empty lines

    if (_liveDistances.isNotEmpty) {
      double sum = 0;
      for (var d in _liveDistances) {
        sum += d;
      }
      double avg = sum / _liveDistances.length;
      rateStr = avg.toStringAsFixed(1);

      double maxVal = 1.0;
      for (var d in _liveDistances) {
        if (d > maxVal) maxVal = d;
      }

      var recent = _liveDistances.length > 9 
          ? _liveDistances.sublist(_liveDistances.length - 9)
          : _liveDistances;
          
      for (int i = 0; i < recent.length; i++) {
        final scaled = (recent[i] / maxVal) * 40;
        barHeights[i] = scaled < 4 ? 4 : scaled;
      }
    }

    return Row(
      children: [
        // Average Distance Card (formerly Water Rise Rate)
        Expanded(
          child: Container(
            height: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F9D8F), // Approximate primary from image
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          rateStr,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'cm',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Average Distance',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
                // Simple bar chart
                SizedBox(
                  height: 40,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: barHeights.map((h) => _buildBar(h)).toList(),
                  ),
                )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 8,
      height: height,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }

  Widget _buildAnalysisSection(List<FloodData> history) {
    String minStr = '-- cm';
    String avgStr = '-- cm';
    String maxStr = '-- cm';
    String startLabel = 'Old';
    String endLabel = 'New';
    List<double> barHeights = List.filled(20, 4.0);
    List<Color> barColors = List.filled(20, const Color(0xFF2C2C2E)); // default gray for empty bars
    
    if (history.isNotEmpty) {
      double min = history[0].distanceCm;
      double max = history[0].distanceCm;
      double sum = 0;
      
      for (var d in history) {
        if (d.distanceCm < min) min = d.distanceCm;
        if (d.distanceCm > max) max = d.distanceCm;
        sum += d.distanceCm;
      }
      
      minStr = '${min.toStringAsFixed(1)} cm';
      maxStr = '${max.toStringAsFixed(1)} cm';
      avgStr = '${(sum / history.length).toStringAsFixed(1)} cm';
      
      final plotData = history.take(20).toList().reversed.toList();
      double chartMax = max > 0 ? max : 1.0;
      
      int offset = 20 - plotData.length;
      for (int i = 0; i < plotData.length; i++) {
        double scaled = (plotData[i].distanceCm / chartMax) * 120;
        barHeights[offset + i] = scaled < 4 ? 4 : scaled;
        barColors[offset + i] = plotData[i].statusColor;
      }
      
      String formatTime(DateTime dt) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
      startLabel = formatTime(plotData.first.timestamp);
      endLabel = formatTime(plotData.last.timestamp);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distance Analysis',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _StatText(label: 'Min', value: minStr),
              _StatText(label: 'Avg', value: avgStr),
              _StatText(label: 'Max', value: maxStr),
            ],
          ),
          const SizedBox(height: 24),
          // Main Bar chart
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(20, (index) {
                return Container(
                  width: 8,
                  height: barHeights[index],
                  decoration: BoxDecoration(
                    color: barColors[index], 
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(startLabel, style: const TextStyle(color: Color(0xFF73787B), fontSize: 12)),
              Text(endLabel, style: const TextStyle(color: Color(0xFF73787B), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatText extends StatelessWidget {
  final String label;
  final String value;

  const _StatText({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label ',
          style: const TextStyle(
            color: Color(0xFF73787B),
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}



class TrendLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintLine1 = Paint()
      ..color = const Color(0xFF64D2FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintLine2 = Paint()
      ..color = const Color(0xFFFFD60A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path1 = Path()
      ..moveTo(0, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.8,
          size.width * 0.4, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.3,
          size.width * 0.6, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.9,
          size.width, size.height * 0.4);

    final path2 = Path()
      ..moveTo(0, size.height * 0.95)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.9,
          size.width * 0.4, size.height * 0.4)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.1,
          size.width * 0.8, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.9,
          size.width, size.height * 0.1);

    canvas.drawPath(path1, paintLine1);
    canvas.drawPath(path2, paintLine2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
