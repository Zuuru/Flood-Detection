import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/firebase_service.dart';
import '../models/flood_data.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  void dispose() {
    _firebaseService.dispose();
    super.dispose();
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
                  _buildStatusSection(floodData),
                  const SizedBox(height: 32),
                  _buildPrimaryMetricCard(floodData),
                  const SizedBox(height: 16),
                  StreamBuilder<List<FloodData>>(
                    stream: _firebaseService.historyStream,
                    builder: (context, historySnapshot) {
                      final history = historySnapshot.data ?? [];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStatsGrid(history),
                          const SizedBox(height: 16),
                          _buildAnalysisSection(history),
                        ],
                      );
                    }
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
          child: Icon(Icons.person, color: Colors.white),
        ),
        Row(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1C1C1E),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.auto_fix_high, color: Colors.white),
                onPressed: () {},
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
                    onPressed: () {},
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
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tank',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 24,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '--',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
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
          // Water tank with wave animation
          SizedBox(
            width: 80,
            height: 60,
            child: AnimatedWaterTank(
              fillPercentage: data?.dangerProgress ?? 0.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(List<FloodData> history) {
    String rateStr = '--';
    List<double> barHeights = List.filled(9, 4.0); // Default to empty lines

    if (history.length >= 2) {
      // Calculate average rate across the entire history range
      final latest = history.first;
      final oldest = history.last;
      final deltaDist = oldest.distanceCm - latest.distanceCm; // positive = water rising
      final deltaSec = latest.timestamp.difference(oldest.timestamp).inSeconds;
      
      if (deltaSec > 0) {
        final avgRatePerMin = (deltaDist / deltaSec) * 60;
        rateStr = avgRatePerMin.toStringAsFixed(1);
      } else {
        rateStr = '0.0';
      }

      // Generate 9 bars
      double maxRate = 1.0; // avoid division by zero
      List<double> recentRates = [];
      for (int i = 0; i < history.length - 1 && i < 9; i++) {
        final curr = history[i];
        final prev = history[i+1];
        final dDist = prev.distanceCm - curr.distanceCm;
        final dSec = curr.timestamp.difference(prev.timestamp).inSeconds;
        if (dSec > 0) {
          final rate = (dDist / dSec) * 60;
          recentRates.add(rate.abs());
          if (rate.abs() > maxRate) maxRate = rate.abs();
        } else {
          recentRates.add(0);
        }
      }
      
      recentRates = recentRates.reversed.toList(); // chronological
      for (int i = 0; i < recentRates.length; i++) {
        final scaled = (recentRates[i] / maxRate) * 40;
        barHeights[i] = scaled < 4 ? 4 : scaled;
      }
    }

    return Row(
      children: [
        // Water Rise Rate Card
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
                          'cm/min',
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
                      'Water Rise Rate',
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
      
      for (int i = 0; i < plotData.length; i++) {
        double scaled = (plotData[i].distanceCm / chartMax) * 120;
        barHeights[i] = scaled < 4 ? 4 : scaled;
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
          // Main Bar chart placeholder
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
                    color: const Color(0xFFFFD60A).withValues(alpha: index >= 20 - (history.isEmpty ? 0 : history.length) ? 1.0 : 0.3), 
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

class AnimatedWaterTank extends StatefulWidget {
  final double fillPercentage;

  const AnimatedWaterTank({
    super.key,
    this.fillPercentage = 0.0,
  });

  @override
  State<AnimatedWaterTank> createState() => _AnimatedWaterTankState();
}

class _AnimatedWaterTankState extends State<AnimatedWaterTank>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: WaterTankPainter(
            animationValue: _controller.value,
            fillPercentage: widget.fillPercentage,
          ),
        );
      },
    );
  }
}

class WaterTankPainter extends CustomPainter {
  final double animationValue;
  final double fillPercentage;

  WaterTankPainter({
    required this.animationValue,
    required this.fillPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = const Color(0xFF64D2FF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final paintFill = Paint()
      ..color = const Color(0xFF64D2FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final paintTick = Paint()
      ..color = const Color(0xFF73787B)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw scale
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), paintTick);
    for (int i = 0; i < 5; i++) {
      double y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(5, y), paintTick);
    }

    // Draw tank
    final tankRect = Rect.fromLTWH(15, 0, size.width - 15, size.height);
    final tankPath = Path()
      ..moveTo(tankRect.left, tankRect.top)
      ..lineTo(tankRect.left, tankRect.bottom - 5)
      ..arcToPoint(Offset(tankRect.left + 5, tankRect.bottom),
          radius: const Radius.circular(5), clockwise: false)
      ..lineTo(tankRect.right - 5, tankRect.bottom)
      ..arcToPoint(Offset(tankRect.right, tankRect.bottom - 5),
          radius: const Radius.circular(5), clockwise: false)
      ..lineTo(tankRect.right, tankRect.top);

    canvas.drawPath(tankPath, paintLine);

    // Draw animated water wave
    // Use fillPercentage to determine water level (0.0 = empty, 1.0 = full)
    // Map percentage to Y coordinate. 1.0 -> y=tankRect.top, 0.0 -> y=tankRect.bottom
    final fillClamped = fillPercentage.clamp(0.0, 1.0);
    final waterLevel = tankRect.bottom - (tankRect.height * fillClamped);
    final waveHeight = 4.0; // amplitude
    
    final waterPath = Path();
    waterPath.moveTo(tankRect.left, waterLevel);
    
    // Create wave using sine function
    for (double x = 0; x <= tankRect.width; x++) {
      // 2 * pi makes it a full wave. 
      // adding animationValue * 2 * pi shifts the wave over time
      final y = waterLevel + math.sin((x / tankRect.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * waveHeight;
      waterPath.lineTo(tankRect.left + x, y);
    }
    
    waterPath.lineTo(tankRect.right, tankRect.bottom - 5);
    waterPath.arcToPoint(Offset(tankRect.right - 5, tankRect.bottom),
        radius: const Radius.circular(5), clockwise: true);
    waterPath.lineTo(tankRect.left + 5, tankRect.bottom);
    waterPath.arcToPoint(Offset(tankRect.left, tankRect.bottom - 5),
        radius: const Radius.circular(5), clockwise: true);
    waterPath.close();

    canvas.drawPath(waterPath, paintFill);
  }

  @override
  bool shouldRepaint(covariant WaterTankPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || 
           oldDelegate.fillPercentage != fillPercentage;
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
