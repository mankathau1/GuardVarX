import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/live_location_provider.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../contacts/providers/contacts_provider.dart';
import '../../sos/domain/emergency_model.dart';
import '../../sos/providers/sos_provider.dart';
import '../providers/safe_walk_provider.dart';

class SafeWalkScreen extends ConsumerStatefulWidget {
  const SafeWalkScreen({super.key});

  @override
  ConsumerState<SafeWalkScreen> createState() => _SafeWalkScreenState();
}

class _SafeWalkScreenState extends ConsumerState<SafeWalkScreen> {
  // Pre-Journey Setup State
  late final TextEditingController _destinationController;
  late final TextEditingController _fromController;
  int _expectedDurationMinutes = 30;
  int _checkinIntervalMinutes = 10;
  String _reminderMethod = 'Push Notification'; // Push, Vibration, Sound + Vibration
  final Set<String> _selectedContactNames = {'Aarav Sharma'};

  // Granular sharing toggles
  bool _shareLiveLocation = true;
  bool _shareETA = true;
  bool _notifyStart = true;
  bool _notifyComplete = true;

  // Saved Places
  final List<Map<String, dynamic>> _savedPlaces = [
    {'name': 'Home', 'icon': Icons.home_rounded, 'address': 'Anna Nagar, 3rd Avenue, Chennai'},
    {'name': 'College', 'icon': Icons.school_rounded, 'address': 'Anna University, Guindy, Chennai'},
    {'name': 'Office', 'icon': Icons.business_rounded, 'address': 'Tidel Park, Tharamani, Chennai'},
    {'name': 'Gym', 'icon': Icons.fitness_center_rounded, 'address': 'FitZone, Teynampet, Chennai'},
  ];

  // Map state for active journey
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _destinationController = TextEditingController(text: 'Home, Anna Nagar');
    _fromController = TextEditingController();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    _fromController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSavedPlaceSelected(Map<String, dynamic> place) {
    setState(() {
      _destinationController.text = '${place['name']} - ${place['address']}';
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleanNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: Text('Cannot launch phone dialer for $phoneNumber'),
          ),
        );
      }
    }
  }

  Future<void> _callEmergencyServices() async {
    final uri = Uri.parse('tel:112');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _shareSafeWalkDetails({
    required String from,
    required String to,
    required double lat,
    required double lng,
  }) async {
    final msg =
        '🛡️ GuardVarX Safe Walk Alert 🛡️\n\n'
        'I am on a monitored Safe Walk journey.\n'
        '📍 From: $from\n'
        '🎯 Destination: $to\n'
        '🗺️ Live Google Maps: https://www.google.com/maps/search/?api=1&query=$lat,$lng\n\n'
        'GuardVarX Safety App is actively tracking check-ins.';
    await Share.share(msg, subject: 'GuardVarX - Safe Walk Live Alert');
  }

  void _showExtendModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.glassBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Extend Safe Walk Time',
                  style: TextStyle(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.secondaryText),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Running late or stopped by a shop? Add extra time so check-in reminders do not escalate needlessly.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
            ),
            const SizedBox(height: 20),
            Row(
              children: [5, 10, 15, 30].map((mins) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.elevatedGlassSurface,
                        foregroundColor: AppColors.cyan,
                        side: const BorderSide(color: AppColors.glassBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        ref.read(safeWalkProvider.notifier).extendTime(mins);
                        Navigator.pop(ctx);
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surface,
                            content: Text(
                              'Added +$mins minutes to your Safe Walk.',
                              style: const TextStyle(color: AppColors.successGreen),
                            ),
                          ),
                        );
                      },
                      child: Text('+$mins m', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showArrivalSummaryDialog() {
    final safeWalk = ref.read(safeWalkProvider);
    String selectedFeedback = 'Good';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Journey Completed!',
                  style: TextStyle(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You have safely reached your destination. All location sharing has been cleanly terminated.',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.elevatedGlassSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      Icons.flag_rounded,
                      'Destination',
                      safeWalk.destinationName.isNotEmpty ? safeWalk.destinationName : 'Home',
                    ),
                    const Divider(color: AppColors.glassBorder, height: 16),
                    _buildSummaryRow(
                      Icons.timer_rounded,
                      'Total Duration',
                      '${(safeWalk.elapsedSeconds / 60).ceil().clamp(1, 999)} mins',
                    ),
                    const Divider(color: AppColors.glassBorder, height: 16),
                    _buildSummaryRow(
                      Icons.route_rounded,
                      'Distance Covered',
                      '${safeWalk.estimatedDistanceKm.toStringAsFixed(1)} km',
                    ),
                    const Divider(color: AppColors.glassBorder, height: 16),
                    _buildSummaryRow(
                      Icons.people_outline_rounded,
                      'Notified Contacts',
                      safeWalk.trustedContactNames.isNotEmpty
                          ? safeWalk.trustedContactNames.join(', ')
                          : 'Aarav Sharma',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'How was your journey experience?',
                style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFeedbackChip('Good 😊', selectedFeedback == 'Good', () {
                    setModalState(() => selectedFeedback = 'Good');
                  }),
                  _buildFeedbackChip('Okay 😐', selectedFeedback == 'Okay', () {
                    setModalState(() => selectedFeedback = 'Okay');
                  }),
                  _buildFeedbackChip('Need Help ⚠️', selectedFeedback == 'Need Improvement', () {
                    setModalState(() => selectedFeedback = 'Need Improvement');
                  }),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ref.read(safeWalkProvider.notifier).complete(feedback: selectedFeedback);
                Navigator.pop(ctx);
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text(
                      'Safe Walk saved to history. Contacts notified of your safe arrival.',
                      style: TextStyle(color: AppColors.successGreen),
                    ),
                  ),
                );
              },
              child: const Text('Save & Finish', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.cyan),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.primaryText, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withValues(alpha: 0.25) : AppColors.elevatedGlassSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primaryBlue : AppColors.glassBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryBlue : AppColors.secondaryText,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _showEndJourneyConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text('Arrived at Destination?', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
        content: const Text(
          'Confirm that you have safely arrived. This will conclude the Safe Walk session, stop live broadcasting, and send an arrival notification to your trusted contacts.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.successGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showArrivalSummaryDialog();
            },
            child: const Text("I've Arrived", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final safeWalk = ref.watch(safeWalkProvider);
    final liveLoc = ref.watch(liveLocationProvider);
    final user = ref.watch(authProvider);
    final contacts = ref.watch(contactsProvider);

    // Initialize start address text if empty
    if (_fromController.text.isEmpty && liveLoc.address.isNotEmpty) {
      _fromController.text = '${liveLoc.address}, ${liveLoc.cityState}';
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: safeWalk.isActive
              ? _buildActiveJourneyView(safeWalk, liveLoc)
              : _buildSetupJourneyView(safeWalk, liveLoc, user, contacts),
        ),
      ),
    );
  }

  // =========================================================================
  // 1. PRE-JOURNEY SETUP VIEW (பயணத்தைத் தொடங்குவதற்கு முன்)
  // =========================================================================
  Widget _buildSetupJourneyView(
    SafeWalkSessionState safeWalk,
    dynamic liveLoc,
    dynamic user,
    List<ContactItem> contacts,
  ) {
    final startAddressDisplay = _fromController.text.isNotEmpty
        ? _fromController.text
        : (liveLoc.address.isNotEmpty ? '${liveLoc.address}, ${liveLoc.cityState}' : 'Anna Salai, Teynampet, Chennai');

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText, size: 18),
                    onPressed: () => context.pop(),
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
                        'Safe Walk • Monitored Journey',
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
                    icon: const Icon(Icons.notifications_none_rounded, color: AppColors.secondaryText),
                    onPressed: () => context.push('/notifications'),
                  ),
                  GestureDetector(
                    onTap: () => ref.read(mainNavigationProvider.notifier).setTab(4),
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.25),
                      child: Text(
                        user.isAuthenticated ? user.displayName[0].toUpperCase() : 'P',
                        style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // B. Introduction Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.elevatedGlassSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.cyan, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Walking alone or travelling late? Safe Walk tracks your route, sends automated check-ins, and alerts trusted contacts if overdue.',
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 12, height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // C. 1. Journey Setup (From / To)
          const Text(
            '1. JOURNEY SETUP',
            style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),

          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: AppSpacing.radiusLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // From (Current GPS Location)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location_rounded, color: AppColors.primaryBlue, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Starting Point (From)', style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.w600)),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  liveLoc.isGpsLive ? 'Live GPS' : 'GPS Active',
                                  style: const TextStyle(color: AppColors.successGreen, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            startAddressDisplay,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_location_alt_outlined, color: AppColors.cyan, size: 20),
                      tooltip: 'Change Starting Point',
                      onPressed: () {
                        _showEditStartDialog(startAddressDisplay);
                      },
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.0),
                  child: Divider(color: AppColors.glassBorder, height: 1),
                ),

                // Destination (To)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.emergencyRed, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Destination (To)', style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _destinationController,
                            style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              hintText: 'Enter home, college, or destination...',
                              hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                              filled: true,
                              fillColor: AppColors.secondaryBackground,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                // Saved Places Chips
                const Text('Saved Places:', style: TextStyle(color: AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _savedPlaces.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          avatar: Icon(p['icon'] as IconData, size: 14, color: AppColors.cyan),
                          label: Text(p['name'] as String, style: const TextStyle(color: AppColors.primaryText, fontSize: 11)),
                          backgroundColor: AppColors.elevatedGlassSurface,
                          side: const BorderSide(color: AppColors.glassBorder),
                          onPressed: () => _onSavedPlaceSelected(p),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // D. Route & Navigation Preview Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.route_rounded, color: AppColors.primaryBlue, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('Est. Distance: ', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                          Text('2.8 km', style: TextStyle(color: AppColors.primaryText, fontSize: 12, fontWeight: FontWeight.bold)),
                          SizedBox(width: 12),
                          Text('ETA: ', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                          Text('~24 min walk', style: TextStyle(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Route deviation detection enabled. Minor drift is normal.',
                        style: TextStyle(color: AppColors.mutedText, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // E. Expected Journey Duration
          const Text(
            'EXPECTED JOURNEY TIME',
            style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Row(
            children: [15, 30, 45, 60].map((mins) {
              final isSel = mins == _expectedDurationMinutes;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Center(
                      child: Text('${mins}m', style: TextStyle(color: isSel ? Colors.white : AppColors.secondaryText, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    selected: isSel,
                    selectedColor: AppColors.primaryBlue,
                    backgroundColor: AppColors.elevatedGlassSurface,
                    side: BorderSide(color: isSel ? AppColors.primaryBlue : AppColors.glassBorder),
                    onSelected: (_) => setState(() => _expectedDurationMinutes = mins),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),

          // F. 2. Trusted Contacts Selection
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '2. TRUSTED CONTACTS TO SHARE WITH',
                style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
              ),
              GestureDetector(
                onTap: () => context.push('/contacts'),
                child: const Text('+ Add New', style: TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          GlassCard(
            padding: const EdgeInsets.all(14),
            borderRadius: AppSpacing.radiusLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (contacts.isEmpty)
                  const Text('No contacts found. Please add in Contacts tab.', style: TextStyle(color: AppColors.secondaryText, fontSize: 12))
                else
                  ...contacts.take(4).map((c) {
                    final isChecked = _selectedContactNames.contains(c.name);
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: isChecked,
                      activeColor: AppColors.primaryBlue,
                      title: Text(c.name, style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold)),
                      subtitle: Text('${c.relationship} • ${c.phone}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                      secondary: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.2),
                        child: Text(c.name[0], style: const TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedContactNames.add(c.name);
                          } else {
                            _selectedContactNames.remove(c.name);
                          }
                        });
                      },
                    );
                  }),
                const Divider(color: AppColors.glassBorder, height: 16),
                // Granular Sharing toggles
                _buildSwitchTile('Share Live Location Updates', _shareLiveLocation, (v) => setState(() => _shareLiveLocation = v)),
                _buildSwitchTile('Share Estimated Arrival Time (ETA)', _shareETA, (v) => setState(() => _shareETA = v)),
                _buildSwitchTile('Send Journey Started Alert', _notifyStart, (v) => setState(() => _notifyStart = v)),
                _buildSwitchTile('Send Journey Completed Alert', _notifyComplete, (v) => setState(() => _notifyComplete = v)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // G. 3. Safety Check-in (முக்கியமான Feature)
          const Text(
            '3. SAFETY CHECK-IN INTERVAL',
            style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),

          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: AppSpacing.radiusLg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Check-in Interval',
                  style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [5, 10, 15, 30].map((mins) {
                    final isSel = mins == _checkinIntervalMinutes;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: ChoiceChip(
                          label: Center(
                            child: Text('Every ${mins}m', style: TextStyle(color: isSel ? Colors.white : AppColors.secondaryText, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          selected: isSel,
                          selectedColor: AppColors.cyan,
                          backgroundColor: AppColors.elevatedGlassSurface,
                          side: BorderSide(color: isSel ? AppColors.cyan : AppColors.glassBorder),
                          onSelected: (_) => setState(() => _checkinIntervalMinutes = mins),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                const Text(
                  'Reminder Method',
                  style: TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Push Notification', 'Vibration + Notification', 'Sound + Vibration + Notification'].map((m) {
                    final isSel = m == _reminderMethod;
                    return ChoiceChip(
                      label: Text(m, style: TextStyle(color: isSel ? Colors.white : AppColors.secondaryText, fontSize: 11)),
                      selected: isSel,
                      selectedColor: AppColors.primaryBlue,
                      backgroundColor: AppColors.elevatedGlassSurface,
                      side: BorderSide(color: isSel ? AppColors.primaryBlue : AppColors.glassBorder),
                      onSelected: (_) => setState(() => _reminderMethod = m),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.warningAmber, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'If you miss a check-in, we send a re-prompt. If still unresponsive, contacts are alerted that check-in was missed (not confirmed as danger).',
                          style: TextStyle(color: AppColors.secondaryText.withValues(alpha: 0.9), fontSize: 11, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // H. Main Start Safe Walk CTA Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.directions_walk_rounded, color: Colors.white, size: 22),
              label: const Text(
                'Start Safe Walk (பயணத்தைத் தொடங்கு)',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () {
                final dest = _destinationController.text.trim().isNotEmpty
                    ? _destinationController.text.trim()
                    : 'Home, Anna Nagar';

                ref.read(safeWalkProvider.notifier).startSafeWalk(
                      destination: dest,
                      startAddress: startAddressDisplay,
                      durationMinutes: _expectedDurationMinutes,
                      checkinIntervalMinutes: _checkinIntervalMinutes,
                      trustedContactNames: _selectedContactNames.toList(),
                      isSharingLiveLocation: _shareLiveLocation,
                      isSharingETA: _shareETA,
                      notifyStart: _notifyStart,
                      notifyComplete: _notifyComplete,
                      reminderMethod: _reminderMethod,
                      startLat: liveLoc.latitude,
                      startLng: liveLoc.longitude,
                      destLat: liveLoc.latitude + 0.02,
                      destLng: liveLoc.longitude + 0.015,
                    );
                HapticFeedback.heavyImpact();
              },
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // I. Previous Journey History
          if (safeWalk.history.isNotEmpty) ...[
            const Text(
              'RECENT COMPLETED TRIPS',
              style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),
            ...safeWalk.history.take(3).map((item) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: AppSpacing.radiusMd,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.toAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.primaryText, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${item.distanceKm.toStringAsFixed(1)} km • ${item.durationMinutes} min • ${DateFormat('d MMM, h:mm a').format(item.completedAt)}',
                              style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.elevatedGlassSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Text(
                          item.feedback,
                          style: const TextStyle(color: AppColors.cyan, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool val, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(title, style: const TextStyle(color: AppColors.secondaryText, fontSize: 12))),
          Switch(
            value: val,
            activeColor: AppColors.primaryBlue,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  void _showEditStartDialog(String currentAddress) {
    final editController = TextEditingController(text: currentAddress);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Starting Location', style: TextStyle(color: AppColors.primaryText, fontSize: 16)),
        content: TextField(
          controller: editController,
          style: const TextStyle(color: AppColors.primaryText),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.secondaryBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () {
              setState(() => _fromController.text = editController.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 2. ACTIVE SAFE WALK VIEW (பயணத்தின் போது)
  // =========================================================================
  Widget _buildActiveJourneyView(SafeWalkSessionState safeWalk, dynamic liveLoc) {
    final minutesLeft = safeWalk.remainingCheckinSeconds ~/ 60;
    final secondsLeft = safeWalk.remainingCheckinSeconds % 60;
    final isWarning = safeWalk.status == 'WARNING';
    final elapsedMin = safeWalk.elapsedSeconds ~/ 60;
    final elapsedSec = safeWalk.elapsedSeconds % 60;

    // Build map markers
    final userPos = LatLng(liveLoc.latitude, liveLoc.longitude);
    final destPos = LatLng(safeWalk.destLatitude, safeWalk.destLongitude);

    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('user_current'),
        position: userPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You (Live Location)'),
      ),
    );
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: 'Destination: ${safeWalk.destinationName}'),
      ),
    );

    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('safe_route'),
        points: [userPos, destPos],
        color: AppColors.primaryBlue,
        width: 4,
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A. Active Top Navigation Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.primaryText, size: 18),
                onPressed: () => context.pop(),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: isWarning
                      ? AppColors.warningAmber.withValues(alpha: 0.2)
                      : AppColors.successGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isWarning ? AppColors.warningAmber : AppColors.successGreen,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isWarning ? AppColors.warningAmber : AppColors.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isWarning ? 'CHECK-IN DUE' : 'LIVE SAFE WALK ACTIVE',
                      style: TextStyle(
                        color: isWarning ? AppColors.warningAmber : AppColors.successGreen,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.battery_5_bar_rounded, size: 16, color: AppColors.cyan),
                  const SizedBox(width: 4),
                  const Text('84%', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                  const SizedBox(width: 8),
                  const Icon(Icons.wifi, size: 14, color: AppColors.successGreen),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // B. Live Map (Google Maps integration)
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.glassBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(target: userPos, zoom: 14.5),
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                  onMapCreated: (ctrl) => _mapController = ctrl,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: FloatingActionButton.small(
                    heroTag: 'recenter_gps_safewalk',
                    backgroundColor: AppColors.surface,
                    child: const Icon(Icons.my_location_rounded, color: AppColors.cyan, size: 18),
                    onPressed: () {
                      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userPos, 15.0));
                    },
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.navigation_rounded, color: AppColors.primaryBlue, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'To: ${safeWalk.destinationName}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.primaryText, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          '${safeWalk.estimatedDistanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // C. Safety Check-in Timer Card (Hero element)
          GlassCard(
            padding: const EdgeInsets.all(20),
            borderRadius: AppSpacing.radiusLg,
            borderColor: isWarning ? AppColors.warningAmber : AppColors.primaryBlue.withValues(alpha: 0.4),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'NEXT SAFETY CHECK-IN',
                          style: TextStyle(color: AppColors.mutedText, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isWarning ? 'Response Needed Now' : 'Check-in Countdown',
                          style: TextStyle(
                            color: isWarning ? AppColors.warningAmber : AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.elevatedGlassSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Every ${safeWalk.checkinIntervalMinutes}m',
                        style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Digital Timer
                Text(
                  '${minutesLeft.toString().padLeft(2, '0')}:${secondsLeft.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: isWarning ? AppColors.warningAmber : AppColors.primaryText,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.0,
                  ),
                ),
                Text(
                  isWarning
                      ? '⚠️ Please confirm you are safe or trusted contacts will be escalated'
                      : 'Tap "I\'m Safe" to verify and reset check-in clock',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isWarning ? AppColors.warningAmber : AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 18),

                // 4 Action Buttons
                Row(
                  children: [
                    // Button 1: I'm Safe
                    Expanded(
                      flex: 3,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
                        label: const Text("I'm Safe (நான் ஓகே)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.successGreen,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ref.read(safeWalkProvider.notifier).checkin();
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              backgroundColor: AppColors.surface,
                              content: Text('Safety confirmed! Check-in timer reset.', style: TextStyle(color: AppColors.successGreen)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Button 2: Extend Time
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.more_time_rounded, color: AppColors.cyan, size: 16),
                        label: const Text('Extend', style: TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold, fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.cyan),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _showExtendModal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // D. Journey Progress & Sharing Status Card
          GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: AppSpacing.radiusLg,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('JOURNEY DURATION', style: TextStyle(color: AppColors.mutedText, fontSize: 10, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Text(
                          '${elapsedMin.toString().padLeft(2, '0')}:${elapsedSec.toString().padLeft(2, '0')} elapsed',
                          style: const TextStyle(color: AppColors.primaryText, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('BROADCAST STATUS', style: TextStyle(color: AppColors.mutedText, fontSize: 10, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: safeWalk.isSharingLiveLocation ? AppColors.successGreen : AppColors.mutedText,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              safeWalk.isSharingLiveLocation ? 'Sharing Live GPS' : 'Sharing Paused',
                              style: TextStyle(
                                color: safeWalk.isSharingLiveLocation ? AppColors.successGreen : AppColors.mutedText,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(color: AppColors.glassBorder, height: 20),
                Row(
                  children: [
                    const Icon(Icons.people_outline_rounded, color: AppColors.primaryBlue, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Shared with: ${safeWalk.trustedContactNames.isNotEmpty ? safeWalk.trustedContactNames.join(', ') : 'Aarav Sharma'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                      onPressed: () {
                        ref.read(safeWalkProvider.notifier).toggleLiveSharing(!safeWalk.isSharingLiveLocation);
                      },
                      child: Text(
                        safeWalk.isSharingLiveLocation ? 'Stop Sharing' : 'Resume Sharing',
                        style: TextStyle(
                          color: safeWalk.isSharingLiveLocation ? AppColors.warningAmber : AppColors.primaryBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // E. Route Deviation & Device Status Alerts
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppColors.successGreen, size: 18),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Route & Network Integrity Normal', style: TextStyle(color: AppColors.primaryText, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('Following expected path • GPS accuracy ±6m', style: TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // F. Emergency Options (உதவி தேவைப்பட்டால்)
          const Text(
            'EMERGENCY & QUICK ASSISTANCE (உதவி தேவைப்பட்டால்)',
            style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // SOS Button
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
                  label: const Text('Send SOS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emergencyRed,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ref.read(sosProvider.notifier).triggerSOS(type: EmergencyType.personalThreat);
                    ref.read(mainNavigationProvider.notifier).setTab(2);
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Call Contact
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
                  label: const Text('Call Contact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purpleAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _makePhoneCall('+919812345678'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              // Share GPS Link
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.share_location_rounded, color: AppColors.cyan, size: 16),
                  label: const Text('Share GPS', style: TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.glassBorder),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    _shareSafeWalkDetails(
                      from: safeWalk.startAddress,
                      to: safeWalk.destinationName,
                      lat: liveLoc.latitude,
                      lng: liveLoc.longitude,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),

              // Call 112 (Police)
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.local_police_rounded, color: AppColors.primaryBlue, size: 16),
                  label: const Text('Call 112 (Police)', style: TextStyle(color: AppColors.primaryBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.glassBorder),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _callEmergencyServices,
                ),
              ),
              const SizedBox(width: 8),

              // Report
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.glassBorder),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => context.push('/report'),
                child: const Icon(Icons.campaign_outlined, color: AppColors.secondaryText, size: 18),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // G. Journey Completion (I've Arrived)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
              label: const Text(
                "I've Arrived (பயணத்தை முடிக்க)",
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _showEndJourneyConfirmation,
            ),
          ),
        ],
      ),
    );
  }
}
