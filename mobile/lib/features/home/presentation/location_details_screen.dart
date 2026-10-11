import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_card.dart';

class LocationDetailsScreen extends StatelessWidget {
  const LocationDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Location Diagnostics')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            const Text(
              'Current GPS Fix & Telemetry',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coordinates are retrieved on demand and are never broadcast without explicit user consent.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),

            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: const [
                  _DiagnosticRow(label: 'Latitude', value: '28.535517 N'),
                  Divider(color: AppColors.glassBorder, height: 20),
                  _DiagnosticRow(label: 'Longitude', value: '77.391028 E'),
                  Divider(color: AppColors.glassBorder, height: 20),
                  _DiagnosticRow(label: 'Horizontal Accuracy', value: '± 8.2 meters (High)'),
                  Divider(color: AppColors.glassBorder, height: 20),
                  _DiagnosticRow(label: 'Provider', value: 'Fused GPS + Network'),
                  Divider(color: AppColors.glassBorder, height: 20),
                  _DiagnosticRow(label: 'Freshness', value: 'Synchronized 30s ago'),
                  Divider(color: AppColors.glassBorder, height: 20),
                  _DiagnosticRow(label: 'Background Tracking', value: 'Inactive (Idle Safe Walk)'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;

  const _DiagnosticRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13)),
      ],
    );
  }
}
