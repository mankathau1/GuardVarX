import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../providers/safe_walk_provider.dart';

class SafeWalkScreen extends ConsumerStatefulWidget {
  const SafeWalkScreen({super.key});

  @override
  ConsumerState<SafeWalkScreen> createState() => _SafeWalkScreenState();
}

class _SafeWalkScreenState extends ConsumerState<SafeWalkScreen> {
  final _destinationController = TextEditingController(text: 'Home, Sector 62');
  int _durationMinutes = 25;
  int _intervalMinutes = 10;

  @override
  Widget build(BuildContext context) {
    final safeWalk = ref.watch(safeWalkProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Safe Walk')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (safeWalk.isActive) ...[
                // ACTIVE JOURNEY VIEW
                GlassContainer(
                  padding: const EdgeInsets.all(24),
                  borderRadius: 24,
                  borderColor: safeWalk.status == 'WARNING'
                      ? AppColors.warningAmber
                      : AppColors.primaryBlue.withOpacity(0.5),
                  child: Column(
                    children: [
                      Icon(
                        safeWalk.status == 'WARNING' ? Icons.warning_rounded : Icons.directions_walk_rounded,
                        size: 48,
                        color: safeWalk.status == 'WARNING' ? AppColors.warningAmber : AppColors.primaryBlue,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        safeWalk.destinationName,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        safeWalk.status == 'WARNING' ? 'CHECK-IN OVERDUE' : 'JOURNEY MONITORED',
                        style: TextStyle(
                          color: safeWalk.status == 'WARNING' ? AppColors.warningAmber : AppColors.successGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${(safeWalk.remainingCheckinSeconds ~/ 60).toString().padLeft(2, '0')}:${(safeWalk.remainingCheckinSeconds % 60).toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Time until next safety check-in prompt',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => ref.read(safeWalkProvider.notifier).checkin(),
                          child: const Text('I am Safe (Reset Timer)', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.glassBorderElevated),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => ref.read(safeWalkProvider.notifier).complete(),
                          child: const Text('Reached Destination (End)', style: TextStyle(color: AppColors.secondaryText)),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // SETUP NEW SAFE WALK
                const Text(
                  'Start Monitored Journey',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Set your destination and check-in intervals. If you miss a check-in, your trusted contacts will be escalated automatically.',
                  style: TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 24),

                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Destination',
                        style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _destinationController,
                        style: const TextStyle(color: AppColors.primaryText),
                        decoration: InputDecoration(
                          hintText: 'e.g. Home, Metro Station',
                          hintStyle: const TextStyle(color: AppColors.mutedText),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Expected Duration',
                        style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [15, 25, 45, 60].map((mins) {
                          final isSelected = mins == _durationMinutes;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text('${mins}m'),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _durationMinutes = mins),
                              selectedColor: AppColors.primaryBlue.withOpacity(0.25),
                              backgroundColor: AppColors.background,
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.primaryBlue : AppColors.secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Check-in Interval',
                        style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [5, 10, 15].map((mins) {
                          final isSelected = mins == _intervalMinutes;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text('Every ${mins}m'),
                              selected: isSelected,
                              onSelected: (_) => setState(() => _intervalMinutes = mins),
                              selectedColor: AppColors.primaryBlue.withOpacity(0.25),
                              backgroundColor: AppColors.background,
                              labelStyle: TextStyle(
                                color: isSelected ? AppColors.primaryBlue : AppColors.secondaryText,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(safeWalkProvider.notifier).startSafeWalk(
                            destination: _destinationController.text.trim(),
                            durationMinutes: _durationMinutes,
                            checkinIntervalMinutes: _intervalMinutes,
                          );
                    },
                    child: const Text('Start Safe Walk', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Privacy Notice
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.elevatedGlassSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.privacy_tip_outlined, color: AppColors.cyan, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Zero continuous tracking: Location updates occur only while Safe Walk is active, and coordinates are automatically purged after arrival.',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 12, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
