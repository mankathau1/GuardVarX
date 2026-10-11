import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/native/connectivity_channel.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_card.dart';
import '../../home/presentation/widgets/central_sos_section.dart';
import '../domain/emergency_model.dart';
import '../providers/sos_provider.dart';
import 'widgets/delivery_tracker_widget.dart';

class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  String _selectedCategory = 'Personal Safety Threat';
  final _messageController = TextEditingController();
  bool _sirenActive = false;

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'Personal Safety Threat',
      'icon': Icons.shield_rounded,
      'color': AppColors.emergencyRed,
      'type': EmergencyType.personalThreat,
    },
    {
      'title': 'Medical Emergency',
      'icon': Icons.add_circle_outline_rounded,
      'color': AppColors.cyan,
      'type': EmergencyType.medical,
    },
    {
      'title': 'Road Accident',
      'icon': Icons.car_crash_rounded,
      'color': AppColors.cyan,
      'type': EmergencyType.roadAccident,
    },
    {
      'title': 'Fire',
      'icon': Icons.local_fire_department_rounded,
      'color': AppColors.warningAmber,
      'type': EmergencyType.fire,
    },
    {
      'title': 'Missing Person',
      'icon': Icons.person_search_rounded,
      'color': AppColors.purpleAccent,
      'type': EmergencyType.missingPerson,
    },
    {
      'title': 'Natural Disaster',
      'icon': Icons.tsunami_rounded,
      'color': AppColors.cyan,
      'type': EmergencyType.naturalDisaster,
    },
    {
      'title': 'Vehicle Breakdown',
      'icon': Icons.car_repair_rounded,
      'color': AppColors.primaryBlue,
      'type': EmergencyType.vehicleBreakdown,
    },
    {
      'title': 'Other',
      'icon': Icons.more_horiz_rounded,
      'color': AppColors.secondaryText,
      'type': EmergencyType.other,
    },
  ];

  void _triggerEmergency() {
    final catObj = _categories.firstWhere((c) => c['title'] == _selectedCategory, orElse: () => _categories.first);
    ref.read(sosProvider.notifier).triggerSOS(
          type: catObj['type'] as EmergencyType,
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text('Cancel Emergency', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please confirm cancellation. Your trusted contacts and responders will be updated.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: InputDecoration(
                labelText: 'Reason for cancellation',
                labelStyle: const TextStyle(color: AppColors.secondaryText),
                filled: true,
                fillColor: AppColors.secondaryBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emergencyRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(sosProvider.notifier).cancelSOS(reasonController.text.trim());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.surface,
                  content: Text('Emergency incident resolved and cancelled.', style: TextStyle(color: AppColors.cyan)),
                ),
              );
            },
            child: const Text('Confirm Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAddMessageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text('Add Emergency Note', style: TextStyle(color: AppColors.primaryText, fontSize: 16)),
        content: TextField(
          controller: _messageController,
          maxLines: 3,
          maxLength: 140,
          style: const TextStyle(color: AppColors.primaryText),
          decoration: InputDecoration(
            hintText: 'e.g. In auto registration TN-09-XX, driver heading wrong way...',
            hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 12),
            filled: true,
            fillColor: AppColors.secondaryBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(color: AppColors.primaryBlue)),
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
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 100.0), // Padding above floating bottom bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // A. Header (GuardVarX / Emergency SOS)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText, size: 18),
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          } else {
                            ref.read(mainNavigationProvider.notifier).handleBack();
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Guard',
                                  style: TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: 'VarX',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Text(
                            'Emergency SOS',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _sirenActive ? Icons.volume_up_rounded : Icons.notifications_outlined,
                          color: _sirenActive ? AppColors.emergencyRed : AppColors.primaryText,
                          size: 24,
                        ),
                        onPressed: _toggleSiren,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryBlue, width: 1.5),
                        ),
                        child: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF1E293B),
                          child: Icon(Icons.person, color: AppColors.primaryText, size: 18),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // B. Title Section with ambient red arc
              const Text(
                'EMERGENCY',
                style: TextStyle(
                  color: AppColors.emergencyRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 4),
              RichText(
                textAlign: TextAlign.center,
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'Need ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: 'Help?',
                      style: TextStyle(
                        color: AppColors.emergencyRed,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.0),
                child: Text(
                  'Select the type of emergency or hold the button for 3 seconds to send an SOS.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Active Emergency HUD banner (if active)
              if (activeIncident != null) ...[
                GlassCard(
                  borderColor: AppColors.emergencyRed,
                  glowColor: AppColors.emergencyRedGlow,
                  glowRadius: 18,
                  padding: const EdgeInsets.all(16),
                  borderRadius: AppSpacing.radiusLg,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.warning_amber_rounded, color: AppColors.emergencyRed, size: 22),
                              SizedBox(width: 8),
                              Text('EMERGENCY ACTIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          GestureDetector(
                            onTap: _showCancelDialog,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.emergencyRed.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.emergencyRed),
                              ),
                              child: const Text('Cancel SOS', style: TextStyle(color: AppColors.emergencyRed, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DeliveryTrackerWidget(incident: activeIncident),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // C. 2x4 Emergency Category Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: _categories.length,
                itemBuilder: (context, idx) {
                  final cat = _categories[idx];
                  final isSelected = _selectedCategory == cat['title'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['title']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.emergencyRed.withOpacity(0.2)
                            : AppColors.glassSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.emergencyRed : AppColors.glassBorder,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.emergencyRed.withOpacity(0.35),
                                  blurRadius: 10,
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            cat['icon'] as IconData,
                            size: 24,
                            color: isSelected ? Colors.white : (cat['color'] as Color),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat['title'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.secondaryText,
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Optional Message row
              GestureDetector(
                onTap: _showAddMessageDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.elevatedGlassSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.edit_note_rounded, size: 16, color: AppColors.cyan),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _messageController.text.isNotEmpty
                              ? 'Note: "${_messageController.text}"'
                              : 'Add optional note / situation details...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _messageController.text.isNotEmpty ? Colors.white : AppColors.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.secondaryText),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // D. Central SOS Section (Safe Walk | SOS 3s Hold | Nearby Help)
              CentralSosSection(
                onSosTriggered: _triggerEmergency,
                onSafeWalkTap: () => context.push('/safewalk'),
                onNearbyHelpTap: () => ref.read(mainNavigationProvider.notifier).setTab(1),
              ),
              const SizedBox(height: AppSpacing.lg),

              // E. Current Location Card with mini radar thumbnail
              GlassCard(
                borderRadius: AppSpacing.radiusLg,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.location_on_rounded, color: AppColors.primaryBlue, size: 18),
                              SizedBox(width: 6),
                              Text('Location', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Anna Salai, Teynampet',
                            style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                          const Text(
                            'Chennai, Tamil Nadu',
                            style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: const [
                              Icon(Icons.gps_fixed_rounded, size: 12, color: AppColors.secondaryText),
                              SizedBox(width: 4),
                              Text('Accuracy: 12 m', style: TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                              SizedBox(width: 8),
                              Icon(Icons.access_time_rounded, size: 12, color: AppColors.secondaryText),
                              SizedBox(width: 4),
                              Text('Updated: 2 min ago', style: TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Mini map thumbnail with "View on map >"
                    Expanded(
                      flex: 4,
                      child: GestureDetector(
                        onTap: () => context.push('/location-details'),
                        child: Container(
                          height: 75,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D1B2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 0.2,
                                  child: GridPaper(color: AppColors.cyan, divisions: 1),
                                ),
                              ),
                              Center(
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.primaryBlue,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 4,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('View on map >', style: TextStyle(color: AppColors.cyan, fontSize: 9, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // F. Status Card: Online & Battery
              GlassCard(
                borderRadius: AppSpacing.radiusLg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Left: Signal Status
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.signal_cellular_alt_rounded, color: AppColors.cyan, size: 24),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Status', style: TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.circle, color: AppColors.successGreen, size: 8),
                                  SizedBox(width: 4),
                                  Text('Online', style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Text('Network connected', style: TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Divider
                    Container(width: 1, height: 32, color: AppColors.glassBorder),
                    const SizedBox(width: 16),

                    // Right: Battery Status
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.battery_5_bar_rounded, color: AppColors.cyan, size: 24),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('72%', style: TextStyle(color: AppColors.primaryText, fontSize: 14, fontWeight: FontWeight.bold)),
                              Text('Battery level', style: TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                            ],
                          ),
                        ],
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
