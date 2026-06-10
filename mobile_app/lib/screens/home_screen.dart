import 'package:flutter/material.dart';
import 'dart:math' as math;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // From design
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 24.0, bottom: 120.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildStatusSection(),
              const SizedBox(height: 32),
              _buildPrimaryMetricCard(),
              const SizedBox(height: 16),
              _buildStatsGrid(),
              const SizedBox(height: 16),
              _buildAnalysisSection(),
              // Bottom Nav will be handled in a separate file/wrapper
            ],
          ),
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

  Widget _buildStatusSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            children: [
              TextSpan(text: 'Flood Level is '),
              TextSpan(
                text: 'Normal',
                style: TextStyle(color: Color(0xFF32D74B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            Text(
              'Battery..',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              '75%',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(6, (index) {
            // Colors for segmented battery bar
            List<Color> colors = [
              const Color(0xFF26B5A1),
              const Color(0xFF3CD1B9),
              const Color(0xFF48DF91),
              const Color(0xFF48DF91),
              const Color(0xFF1A3D24),
              const Color(0xFF1A3D24),
            ];
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index < 5 ? 6 : 0),
                height: 32,
                decoration: BoxDecoration(
                  color: colors[index],
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPrimaryMetricCard() {
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
                children: const [
                  Text(
                    '346',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    ' /2347 cm',
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
          const SizedBox(
            width: 80,
            height: 60,
            child: AnimatedWaterTank(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
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
                      children: const [
                        Text(
                          '+1.5',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Text(
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
                // Simple placeholder for bar chart
                SizedBox(
                  height: 40,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBar(15),
                      _buildBar(18),
                      _buildBar(22),
                      _buildBar(12),
                      _buildBar(16),
                      _buildBar(25),
                      _buildBar(20),
                      _buildBar(28),
                      _buildBar(35),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Signal Trend Card
        Expanded(
          child: Container(
            height: 160,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Signal Strength\n& Trend',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
                // Placeholder for line chart
                SizedBox(
                  height: 60,
                  child: CustomPaint(
                    painter: TrendLinePainter(),
                  ),
                ),
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
      color: Colors.white,
    );
  }

  Widget _buildAnalysisSection() {
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
            'Water Level Analysis',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _StatText(label: 'Min', value: '10cm'),
              _StatText(label: 'Avg', value: '35cm'),
              _StatText(label: 'Max', value: '80cm'),
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
                // Generate some random-looking heights
                final heights = [
                  15.0, 20.0, 40.0, 30.0, 15.0, 25.0, 35.0, 35.0, 50.0, 80.0,
                  30.0, 60.0, 20.0, 30.0, 25.0, 45.0, 70.0, 60.0, 65.0, 100.0
                ];
                return Container(
                  width: 8,
                  height: heights[index],
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD60A), // Yellow primary from design
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Jan', style: TextStyle(color: Color(0xFF73787B), fontSize: 12)),
              Text('Dec', style: TextStyle(color: Color(0xFF73787B), fontSize: 12)),
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
  const AnimatedWaterTank({super.key});

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
          painter: WaterTankPainter(animationValue: _controller.value),
        );
      },
    );
  }
}

class WaterTankPainter extends CustomPainter {
  final double animationValue;

  WaterTankPainter({required this.animationValue});

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
    final waterLevel = tankRect.height * 0.4; // 60% full (y goes down)
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
    return oldDelegate.animationValue != animationValue;
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
