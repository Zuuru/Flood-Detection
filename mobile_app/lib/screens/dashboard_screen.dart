import 'package:flutter/material.dart';

import '../models/flood_data.dart';
import '../services/firebase_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirebaseService _service = FirebaseService();

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flood Detection Dashboard'),
        centerTitle: false,
      ),
      body: StreamBuilder<FloodData>(
        stream: _service.floodDataStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatusHeader(data),
                const SizedBox(height: 16),
                _buildSummaryCards(data),
                const SizedBox(height: 20),
                _buildDetailPanel(data),
                const SizedBox(height: 20),
                _buildLevelLegend(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusHeader(FloodData data) {
    return Container(
      decoration: BoxDecoration(
        color: data.statusColor.withAlpha(31),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: data.statusColor,
            child: Icon(
              Icons.water_drop,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.statusLabel,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: data.statusColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Jarak air: ${data.distanceCm.toStringAsFixed(0)} cm',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  'Terakhir diperbarui: ${_formatTime(data.timestamp)}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(FloodData data) {
    return Row(
      children: [
        Expanded(
          child: _buildInfoCard(
            label: 'Status',
            value: data.statusLabel,
            icon: Icons.warning_amber_rounded,
            color: data.statusColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildInfoCard(
            label: 'Buzzer',
            value: data.buzzerState,
            icon: Icons.volume_up,
            color: Colors.blueGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(color: color.withAlpha(204)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(FloodData data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Pemantauan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.thermostat_outlined,
            label: 'Ketinggian Air',
            value: '${data.distanceCm.toStringAsFixed(0)} cm',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.timeline,
            label: 'Evaluasi Level',
            value: data.levelLabel,
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.lightbulb,
            label: 'LED Indikator',
            value: data.ledState,
          ),
          const SizedBox(height: 24),
          Text(
            'Progres Ketinggian',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: data.dangerProgress,
              minHeight: 12,
              color: data.statusColor,
              backgroundColor: data.statusColor.withAlpha(46),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, color: Colors.black87),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildLevelLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Level Banjir',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        _buildLegendRow('Aman', Colors.green, 'Jarak air > 120 cm'),
        const SizedBox(height: 8),
        _buildLegendRow('Siaga', Colors.orange, 'Jarak air 60 - 120 cm'),
        const SizedBox(height: 8),
        _buildLegendRow('Evakuasi', Colors.red, 'Jarak air <= 60 cm'),
      ],
    );
  }

  Widget _buildLegendRow(String label, Color color, String description) {
    return Row(
      children: [
        CircleAvatar(radius: 8, backgroundColor: color),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color))),
        Text(description, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
