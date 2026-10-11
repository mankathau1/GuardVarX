import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/native/connectivity_channel.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../domain/emergency_model.dart';
import '../providers/sos_provider.dart';
import 'widgets/deliberate_hold_button.dart';
import 'widgets/delivery_tracker_widget.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  EmergencyType _selectedType = EmergencyType.personalThreat;
  final _messageController = TextEditingController();
  bool _sirenActive = false;

  void _triggerEmergency() {
    ref.read(sosProvider.notifier).triggerSOS(
          type: _selectedType,
          message: _messageController.text.trim().isNotEmpty ? _messageController.text.trim() : null,
        );
  }

  void _toggleSiren() {
    setState(() => _sirenActive = !_sirenActive);
    NativeConnectivityChannel.triggerLoudSiren(_sirenActive);
  }

  void _showCancelDialog() {
    final reasonController = TextEditingController(text: 'Accidental trigger');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primarySurface,
        title: const Text('Cancel Emergency', style: TextStyle(color: AppColors.primaryText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please provide a cancellation reason. Trusted contacts will be notified.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Back', style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(sosProvider.notifier).cancelSOS(reasonController.text.trim());
            },
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeIncident = ref.watch(sosProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Emergency Response'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              ref.read(mainNavigationProvider.notifier).handleBack();
            }
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              _sirenActive ? Icons.volume_up : Icons.volume_off,
              color: _sirenActive ? AppColors.emergencyRed : AppColors.secondaryText,
            ),
            onPressed: _toggleSiren,
            tooltip: 'Loud Emergency Siren',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (activeIncident != null &&
                  activeIncident.status != DeliveryStatus.resolved &&
                  activeIncident.status != DeliveryStatus.cancelled) ...[
                // ACTIVE EMERGENCY TRACKING VIEW
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.emergencyRed.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.emergencyRed, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EMERGENCY ALERT ACTIVE',
                              style: TextStyle(color: AppColors.emergencyRed, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              activeIncident.emergencyType.label,
                              style: const TextStyle(color: AppColors.primaryText, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Delivery state machine tracker
                DeliveryTrackerWidget(incident: activeIncident),

                const SizedBox(height: 20),

                // Action buttons (Cancel / Resolve)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.glassBorderElevated),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _showCancelDialog,
                        child: const Text('Cancel Alert', style: TextStyle(color: AppColors.secondaryText)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => ref.read(sosProvider.notifier).resolveSOS(),
                        child: const Text('I am Safe (Resolve)', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // INACTIVE STATE: TRIGGER SOS
                const SizedBox(height: 12),
                DeliberateHoldButton(onTrigger: _triggerEmergency),
                const SizedBox(height: 28),

                // Category Selector
                GlassContainer(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'SELECT INCIDENT TYPE',
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: EmergencyType.values.map((type) {
                          final isSelected = type == _selectedType;
                          return ChoiceChip(
                            label: Text(type.label),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _selectedType = type),
                            selectedColor: AppColors.primaryBlue.withOpacity(0.25),
                            backgroundColor: AppColors.background,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primaryBlue : AppColors.secondaryText,
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryBlue : AppColors.glassBorder,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _messageController,
                        style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Optional notes (e.g. Landmark, red jacket)',
                          hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.glassBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppColors.glassBorder),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // India 112 official emergency shortcut
              GlassContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderRadius: 16,
                borderColor: AppColors.glassBorder,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.call, color: AppColors.successGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Direct Emergency Call: 112', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('India National Emergency Helpline', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
