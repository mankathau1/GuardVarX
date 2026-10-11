import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';

class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  bool _isAvailableAsHelper = false;

  final List<Map<String, dynamic>> _mockVolunteers = [
    {
      'name': 'Rohan Das',
      'role': 'Verified Community Volunteer',
      'distance': '350m away',
      'eta': '3 mins',
      'skills': ['Basic First Aid', 'Two-Wheeler'],
      'verified': true,
    },
    {
      'name': 'Dr. Sunita (Civilian)',
      'role': 'Civilian Medical Volunteer',
      'distance': '800m away',
      'eta': '7 mins',
      'skills': ['BLS Certified', 'Medical Assistance'],
      'verified': true,
    },
    {
      'name': 'Vikram Mehra',
      'role': 'Registered Citizen Responder',
      'distance': '1.2 km away',
      'eta': '10 mins',
      'skills': ['Automobile Transport'],
      'verified': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Nearby Assistance')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            // Helper Mode Toggle Card
            GlassContainer(
              padding: const EdgeInsets.all(18),
              borderRadius: 20,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isAvailableAsHelper
                          ? AppColors.successGreen.withOpacity(0.15)
                          : AppColors.elevatedGlassSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.volunteer_activism_rounded,
                      color: _isAvailableAsHelper ? AppColors.successGreen : AppColors.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Volunteer Mode',
                          style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          _isAvailableAsHelper
                              ? 'Active: Ready to receive nearby alerts within 1.5 km'
                              : 'Inactive: You are not broadcasting availability',
                          style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAvailableAsHelper,
                    activeColor: AppColors.successGreen,
                    onChanged: (val) {
                      setState(() => _isAvailableAsHelper = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Available Community Responders',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Nearby civilian volunteers within your safety radius. Responders receive approximate quadrant location only until SOS is accepted.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 16),

            ..._mockVolunteers.map((vol) {
              final isVerified = vol['verified'] as bool;
              final skills = vol['skills'] as List<String>;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                vol['name'] as String,
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified_rounded, size: 16, color: AppColors.primaryBlue),
                              ],
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.elevatedGlassSurface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              vol['distance'] as String,
                              style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vol['role'] as String,
                        style: const TextStyle(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        children: skills.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primarySurface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: Text(s, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.elevatedGlassSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: AppColors.warningAmber, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Civilian responders are community volunteers and do not replace official Indian police (100) or medical services (108).',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 11, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
