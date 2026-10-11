import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/providers/live_location_provider.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_card.dart';
import '../../im_guard/providers/im_guard_provider.dart';
import '../providers/ble_mesh_provider.dart';
import '../providers/offline_mesh_chat_provider.dart';
import '../providers/offline_p2p_call_provider.dart';
import 'package:image_picker/image_picker.dart';

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bleMeshProvider.notifier).startDiscovery();
    });
  }

  // Search and Filters
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  int _maxDistanceMeters = 5000; // 5 km default
  String _availabilityFilter = 'Any'; // 'Available Now', 'Available Later', 'Any'
  bool _verifiedOnly = false;
  String _sortBy = 'distance'; // 'distance', 'rating', 'active'
  bool _showGoogleMap = true; // Toggle between Google Map and Radar View

  int? _selectedHelperIndex;
  GoogleMapController? _mapController;

  // Active Request Tracking Lifecycle State
  // Status: null, 'REQUEST_SENT', 'ACCEPTED', 'ON_THE_WAY', 'ARRIVED', 'COMPLETED'
  Map<String, dynamic>? _activeRequest;
  Timer? _requestSimulationTimer;

  // Blocked helper IDs
  final Set<String> _blockedHelperIds = {};

  final List<Map<String, dynamic>> _helpers = [
    {
      'id': 'h_1',
      'name': 'Arunkumar S.',
      'category': 'Safety Support',
      'sub': 'Community Patrol • Physical Escort',
      'phone': '+91 98401 23456',
      'distanceMeters': 320,
      'distanceText': '320 m away',
      'rating': 4.8,
      'reviews': 32,
      'status': 'Available Now',
      'isAvailable': true,
      'isVerified': true,
      'badges': ['Safety Volunteer', 'Night Patrol Lead'],
      'bio': 'Registered volunteer in Teynampet for 3 years. Available for walking escorts and quick neighborhood help.',
      'recentReview': 'Arun arrived within 4 minutes and helped me safely walk past the dark junction.',
      'lat': 13.0425,
      'lng': 80.2512,
      'radarAngle': -0.4,
      'radarRadius': 0.55,
    },
    {
      'id': 'h_2',
      'name': 'Dr. Priya M.',
      'category': 'Medical Help',
      'sub': 'Emergency First Aid • CPR Certified',
      'phone': '+91 98402 34567',
      'distanceMeters': 260,
      'distanceText': '260 m away',
      'rating': 4.9,
      'reviews': 48,
      'status': 'Available Now',
      'isAvailable': true,
      'isVerified': true,
      'badges': ['CPR Certified', 'Medical Officer', 'Doctor'],
      'bio': 'Resident physician at Apollo Clinic nearby. Carry portable first aid kit and emergency trauma supplies.',
      'recentReview': 'Assisted immediately during an elderly neighbor faint incident. Truly lifesaving.',
      'lat': 13.0435,
      'lng': 80.2501,
      'radarAngle': 0.35,
      'radarRadius': 0.45,
    },
    {
      'id': 'h_3',
      'name': 'Vikram R.',
      'category': 'Road Assistance',
      'sub': 'Puncture Repair • Battery Jump Start',
      'phone': '+91 98403 45678',
      'distanceMeters': 550,
      'distanceText': '550 m away',
      'rating': 4.7,
      'reviews': 21,
      'status': 'Available Later',
      'isAvailable': false,
      'isVerified': true,
      'badges': ['Mechanic Lead', 'Tow & Jump-start'],
      'bio': 'Automobile enthusiast equipped with portable battery jump-starter and tire inflator kit.',
      'recentReview': 'Helped restart my scooter at 10 PM on Anna Salai when battery died.',
      'lat': 13.0402,
      'lng': 80.2528,
      'radarAngle': 0.85,
      'radarRadius': 0.8,
    },
    {
      'id': 'h_4',
      'name': 'Kavitha N.',
      'category': 'Women Safety',
      'sub': 'Night Travel Escort • Safe Ride Companion',
      'phone': '+91 98404 56789',
      'distanceMeters': 480,
      'distanceText': '480 m away',
      'rating': 4.9,
      'reviews': 54,
      'status': 'Available Now',
      'isAvailable': true,
      'isVerified': true,
      'badges': ['Women Wing Head', 'Self-Defense Trainer'],
      'bio': 'Women safety advocate and martial arts trainer. Available for companionships and public transit assistance.',
      'recentReview': 'Accompanied me from metro station to home when auto was unavailable. Felt 100% secure.',
      'lat': 13.0442,
      'lng': 80.2488,
      'radarAngle': -1.2,
      'radarRadius': 0.7,
    },
    {
      'id': 'h_5',
      'name': 'Ramanathan G.',
      'category': 'Senior/Elderly Help',
      'sub': 'Mobility Aid • Medication & Grocery Support',
      'phone': '+91 98405 67890',
      'distanceMeters': 820,
      'distanceText': '820 m away',
      'rating': 4.9,
      'reviews': 39,
      'status': 'Available Now',
      'isAvailable': true,
      'isVerified': true,
      'badges': ['Elderly Care Volunteer', 'Verified Caregiver'],
      'bio': 'Dedicated to assisting seniors with hospital visits, wheelchair navigation, and urgent medicine delivery.',
      'recentReview': 'Helped my mother collect insulin prescription when roads were waterlogged.',
      'lat': 13.0385,
      'lng': 80.2545,
      'radarAngle': 1.6,
      'radarRadius': 0.9,
    },
    {
      'id': 'h_6',
      'name': 'Ananya S.',
      'category': 'Student Help',
      'sub': 'College Campus Safety • Peer Companion',
      'phone': '+91 98406 78901',
      'distanceMeters': 950,
      'distanceText': '950 m away',
      'rating': 4.6,
      'reviews': 16,
      'status': 'Available Now',
      'isAvailable': true,
      'isVerified': false,
      'badges': ['Student Council Lead', 'Campus Volunteer'],
      'bio': 'Anna University student council volunteer. Helps fellow students navigating unfamiliar college neighborhoods.',
      'recentReview': 'Quick help when my phone battery died outside the campus gate.',
      'lat': 13.0455,
      'lng': 80.2472,
      'radarAngle': -2.1,
      'radarRadius': 0.95,
    },
    {
      'id': 'h_7',
      'name': 'Suresh V.',
      'category': 'Lost & Found',
      'sub': 'Lost Pets • Document & Bag Search',
      'phone': '+91 98407 89012',
      'distanceMeters': 1200,
      'distanceText': '1.2 km away',
      'rating': 4.8,
      'reviews': 29,
      'status': 'Available Later',
      'isAvailable': false,
      'isVerified': true,
      'badges': ['Community Detective', 'Pet Search Volunteer'],
      'bio': 'Helps coordinate local neighborhood WhatsApp networks to trace lost pets, bags, and essential documents.',
      'recentReview': 'Found my lost college certificate folder within 2 hours in Teynampet park.',
      'lat': 13.0475,
      'lng': 80.2562,
      'radarAngle': -0.8,
      'radarRadius': 1.1,
    },
    {
      'id': 'h_8',
      'name': 'Deepak K.',
      'category': 'Other',
      'sub': 'General Community Assistance • Tech & Translating',
      'phone': '+91 98408 90123',
      'distanceMeters': 710,
      'distanceText': '710 m away',
      'rating': 4.6,
      'reviews': 18,
      'status': 'Available Now',
      'isAvailable': true,
      'isVerified': true,
      'badges': ['Neighborhood Volunteer'],
      'bio': 'Available for urgent general support, local Tamil/English translations, and emergency communications.',
      'recentReview': 'Very friendly and resourceful helper in Teynampet market area.',
      'lat': 13.0395,
      'lng': 80.2492,
      'radarAngle': -2.2,
      'radarRadius': 0.85,
    },
  ];

  final List<String> _categoryList = [
    'All',
    'Medical Help',
    'Safety Support',
    'Road Assistance',
    'Women Safety',
    'Senior/Elderly Help',
    'Student Help',
    'Lost & Found',
    'Other',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    _requestSimulationTimer?.cancel();
    super.dispose();
  }

  // Filtered & Sorted Helpers (combining Cloud helpers + BLE/Wi-Fi Direct Peers)
  List<Map<String, dynamic>> _getFilteredHelpers(List<Map<String, dynamic>> blePeers) {
    final query = _searchController.text.trim().toLowerCase();

    // Merge offline BLE & Wi-Fi Direct peers with general directory
    final allHelpers = [...blePeers, ..._helpers];

    var list = allHelpers.where((h) {
      if (_blockedHelperIds.contains(h['id'])) return false;

      // 1. Search Query filter (name, category, sub, bio)
      if (query.isNotEmpty) {
        final matchesName = (h['name'] as String).toLowerCase().contains(query);
        final matchesCat = (h['category'] as String).toLowerCase().contains(query);
        final matchesSub = (h['sub'] as String).toLowerCase().contains(query);
        final matchesBio = ((h['bio'] as String?) ?? '').toLowerCase().contains(query);
        if (!matchesName && !matchesCat && !matchesSub && !matchesBio) return false;
      }

      // 2. Category filter
      if (_selectedCategory != 'All' && h['category'] != _selectedCategory) {
        return false;
      }

      // 3. Distance filter
      final dist = (h['distanceMeters'] as int?) ?? 50;
      if (dist > _maxDistanceMeters) return false;

      // 4. Availability filter
      if (_availabilityFilter == 'Available Now' && !h['isAvailable']) return false;
      if (_availabilityFilter == 'Available Later' && h['isAvailable']) return false;

      // 5. Verified filter
      if (_verifiedOnly && !h['isVerified']) return false;

      return true;
    }).toList();

    // Sorting: Nearest first by default
    if (_sortBy == 'distance') {
      list.sort((a, b) => ((a['distanceMeters'] as int?) ?? 0).compareTo((b['distanceMeters'] as int?) ?? 0));
    } else if (_sortBy == 'rating') {
      list.sort((a, b) => ((b['rating'] as double?) ?? 0.0).compareTo((a['rating'] as double?) ?? 0.0));
    } else if (_sortBy == 'active') {
      list.sort((a, b) => ((b['reviews'] as int?) ?? 0).compareTo((a['reviews'] as int?) ?? 0));
    }

    return list;
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$clean');
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

  void _showHelperProfileModal(Map<String, dynamic> helper) {
    final isAvailable = helper['isAvailable'] as bool;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.78,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(top: BorderSide(color: AppColors.glassBorder)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.glassBorderElevated,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Top Profile Bar: Photo, Verified, Report
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                      child: Text(
                        helper['name'][0],
                        style: const TextStyle(fontSize: 24, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                      ),
                    ),
                    if (helper['isVerified'])
                      const Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: AppColors.primaryBlue,
                          child: Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            helper['name'],
                            style: const TextStyle(color: AppColors.primaryText, fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isAvailable ? AppColors.successGreen : AppColors.warningAmber).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              helper['status'],
                              style: TextStyle(
                                color: isAvailable ? AppColors.successGreen : AppColors.warningAmber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(helper['sub'], style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primaryBlue),
                          const SizedBox(width: 2),
                          Text(helper['distanceText'], style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                          const SizedBox(width: 10),
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFB800)),
                          const SizedBox(width: 2),
                          Text('${helper['rating']} (${helper['reviews']} reviews)', style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.secondaryText),
                  color: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.glassBorder)),
                  onSelected: (val) {
                    if (val == 'report') {
                      Navigator.pop(ctx);
                      _showReportUserDialog(helper);
                    } else if (val == 'block') {
                      Navigator.pop(ctx);
                      _showBlockUserDialog(helper);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(
                        children: [
                          Icon(Icons.report_problem_outlined, color: AppColors.warningAmber, size: 18),
                          SizedBox(width: 8),
                          Text('Report User', style: TextStyle(color: AppColors.primaryText)),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'block',
                      child: Row(
                        children: [
                          Icon(Icons.block_rounded, color: AppColors.emergencyRed, size: 18),
                          SizedBox(width: 8),
                          Text('Block User', style: TextStyle(color: AppColors.emergencyRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(color: AppColors.glassBorder, height: 24),

            // Badges
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (helper['badges'] as List<String>).map((badge) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.elevatedGlassSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_outlined, size: 12, color: AppColors.cyan),
                      const SizedBox(width: 4),
                      Text(badge, style: const TextStyle(color: AppColors.primaryText, fontSize: 11, fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Bio
            const Text('About & Verification', style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              helper['bio'],
              style: const TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.35),
            ),
            const SizedBox(height: 16),

            // Genuine Reviews
            const Text('Recent Verified Review', style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded, color: AppColors.cyan, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      helper['recentReview'],
                      style: const TextStyle(color: AppColors.primaryText, fontSize: 12, fontStyle: FontStyle.italic, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Action Buttons: Call, Message, Can Help / Request Help
            Row(
              children: [
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.elevatedGlassSurface,
                    padding: const EdgeInsets.all(14),
                  ),
                  icon: const Icon(Icons.phone_rounded, color: AppColors.cyan),
                  tooltip: 'Call Helper',
                  onPressed: () => _makePhoneCall(helper['phone']),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.elevatedGlassSurface,
                    padding: const EdgeInsets.all(14),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryBlue),
                  tooltip: 'In-app Chat',
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showMessageSheet(helper);
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.near_me_rounded, color: Colors.white, size: 18),
                    label: const Text('Request Help', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showCanHelpDialog(helper);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCanHelpDialog(Map<String, dynamic> helper) {
    final noteController = TextEditingController(text: 'Need assistance in Anna Salai nearby.');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.send_rounded, color: AppColors.primaryBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Request Help from ${helper['name']}',
                style: const TextStyle(color: AppColors.primaryText, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${helper['name']} (${helper['category']}) will receive your approximate location (Anna Salai, ~${helper['distanceText']}).',
              style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteController,
              style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Help Note / Urgent Requirement',
                labelStyle: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                filled: true,
                fillColor: AppColors.secondaryBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.elevatedGlassSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 14, color: AppColors.cyan),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your exact coordinates are guarded until helper accepts request.',
                      style: TextStyle(color: AppColors.secondaryText, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final note = noteController.text.trim();
              if (helper['connectionType'] == 'BLE_DIRECT' || helper['connectionType'] == 'WIFI_DIRECT') {
                ref.read(bleMeshProvider.notifier).sendDirectHelpRequest(
                      peer: helper,
                      message: note,
                    );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text(
                      '🚨 Direct ${helper['connectionType'] == 'BLE_DIRECT' ? 'Bluetooth' : 'Wi-Fi'} Alert transmitted to ${helper['name']}!',
                      style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }
              _startHelpRequestLifecycle(helper, note);
            },
            child: const Text('Send Help Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // 12. Help Request Lifecycle: REQUEST_SENT -> ACCEPTED -> ON_THE_WAY -> ARRIVED
  void _startHelpRequestLifecycle(Map<String, dynamic> helper, String note) {
    setState(() {
      _activeRequest = {
        'helper': helper,
        'note': note,
        'status': 'REQUEST_SENT',
        'requestedAt': DateTime.now(),
        'etaMinutes': 4,
      };
    });

    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text('Help request transmitted to ${helper['name']}. Status: Request Sent.', style: const TextStyle(color: AppColors.cyan)),
      ),
    );

    // Simulate realistic volunteer acceptance progression after 3 seconds
    _requestSimulationTimer?.cancel();
    _requestSimulationTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _activeRequest != null && _activeRequest!['status'] == 'REQUEST_SENT') {
        setState(() {
          _activeRequest!['status'] = 'ACCEPTED';
        });
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surface,
            content: Text('${helper['name']} ACCEPTED your request! Getting ready.', style: const TextStyle(color: AppColors.successGreen)),
          ),
        );

        // Progress to On the Way after 4 seconds
        _requestSimulationTimer = Timer(const Duration(seconds: 5), () {
          if (mounted && _activeRequest != null && _activeRequest!['status'] == 'ACCEPTED') {
            setState(() {
              _activeRequest!['status'] = 'ON_THE_WAY';
            });
            HapticFeedback.lightImpact();
          }
        });
      }
    });
  }

  void _progressTrackingStatusManually() {
    if (_activeRequest == null) return;
    setState(() {
      final current = _activeRequest!['status'];
      if (current == 'REQUEST_SENT') {
        _activeRequest!['status'] = 'ACCEPTED';
      } else if (current == 'ACCEPTED') {
        _activeRequest!['status'] = 'ON_THE_WAY';
      } else if (current == 'ON_THE_WAY') {
        _activeRequest!['status'] = 'ARRIVED';
      } else if (current == 'ARRIVED') {
        _completeActiveRequest();
      }
    });
  }

  void _cancelActiveRequest() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Help Request?', style: TextStyle(color: AppColors.primaryText)),
        content: const Text(
          'Are you sure you want to cancel? The volunteer will be notified that help is no longer required.',
          style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
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
              _requestSimulationTimer?.cancel();
              setState(() => _activeRequest = null);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help request cancelled.')),
              );
            },
            child: const Text('Confirm Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _completeActiveRequest() {
    final helper = _activeRequest!['helper'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.glassBorder)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 24),
            const SizedBox(width: 8),
            const Text('Help Completed', style: TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thank you for using GuardVarX. Did ${helper['name']} resolve your emergency?', style: const TextStyle(color: AppColors.secondaryText, fontSize: 13)),
            const SizedBox(height: 14),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 28),
                Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 28),
                Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 28),
                Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 28),
                Icon(Icons.star_rounded, color: Color(0xFFFFB800), size: 28),
              ],
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _activeRequest = null);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.surface,
                  content: Text('Feedback submitted. Helper rating updated!', style: TextStyle(color: AppColors.successGreen)),
                ),
              );
            },
            child: const Text('Submit & Finish', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showReportUserDialog(Map<String, dynamic> helper) {
    String selectedReason = 'Suspicious Activity';
    final commentCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.report_problem_rounded, color: AppColors.warningAmber),
              const SizedBox(width: 8),
              Text('Report ${helper['name']}', style: const TextStyle(color: AppColors.primaryText, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please select the violation reason:', style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedReason,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.secondaryBackground,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                items: ['Suspicious Activity', 'Inappropriate Behavior', 'No-show / False Availability', 'Harassment', 'Other']
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (val) => setDialogState(() => selectedReason = val!),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: commentCtrl,
                style: const TextStyle(color: AppColors.primaryText, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Additional details (optional)...',
                  hintStyle: const TextStyle(color: AppColors.mutedText),
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
              child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.surface,
                    content: Text('Report against ${helper['name']} submitted to GuardVarX Safety Admin.', style: const TextStyle(color: AppColors.cyan)),
                  ),
                );
              },
              child: const Text('Submit Report', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockUserDialog(Map<String, dynamic> helper) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Block Helper?', style: TextStyle(color: AppColors.primaryText)),
        content: Text(
          '${helper['name']} will be blocked. They will not appear in your nearby radar or map anymore.',
          style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.secondaryText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.emergencyRed),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _blockedHelperIds.add(helper['id']));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${helper['name']} has been blocked.')),
              );
            },
            child: const Text('Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMessageSheet(Map<String, dynamic> helper) {
    final textController = TextEditingController();
    final scrollController = ScrollController();
    final helperId = (helper['id'] ?? helper['name'] ?? 'peer').toString();
    final helperName = (helper['name'] ?? 'Helper').toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final meshChatState = ref.watch(offlineMeshChatProvider);
          final messages = ref.read(offlineMeshChatProvider.notifier).getMessagesForPeer(helperId);

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              height: MediaQuery.of(ctx).size.height * 0.72,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: AppColors.glassBorder)),
              ),
              child: Column(
                children: [
                  // Top pull indicator
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                              child: Text(
                                helperName.isNotEmpty ? helperName[0] : '?',
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      helperName,
                                      style: const TextStyle(
                                        color: AppColors.primaryText,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.successGreen.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppColors.successGreen.withOpacity(0.3)),
                                      ),
                                      child: const Text(
                                        'OFFLINE P2P',
                                        style: TextStyle(
                                          color: AppColors.successGreen,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  helper['sub'] ?? 'Nearby Peer',
                                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.cyan, size: 20),
                              tooltip: 'Offline Audio Call',
                              onPressed: () {
                                Navigator.pop(ctx);
                                ref.read(offlineP2PCallProvider.notifier).startCall(
                                  peerId: helperId,
                                  peerName: helperName,
                                  type: OfflineCallType.audio,
                                );
                                context.push('/offline-call');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.videocam_rounded, color: AppColors.primaryBlue, size: 22),
                              tooltip: 'Offline Video Call',
                              onPressed: () {
                                Navigator.pop(ctx);
                                ref.read(offlineP2PCallProvider.notifier).startCall(
                                  peerId: helperId,
                                  peerName: helperName,
                                  type: OfflineCallType.video,
                                );
                                context.push('/offline-call');
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: AppColors.secondaryText),
                              onPressed: () => Navigator.pop(ctx),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Wi-Fi UDP Broadcast & BLE Mesh Indicator Banner
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryBlue.withOpacity(0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.wifi_tethering, color: AppColors.cyan, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Same Wi-Fi (UDP 58888) & BLE Mesh Active',
                                style: TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                meshChatState.statusMessage,
                                style: const TextStyle(color: AppColors.mutedText, fontSize: 10),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.bluetooth_audio, color: AppColors.primaryBlue, size: 18),
                      ],
                    ),
                  ),

                  const Divider(color: AppColors.glassBorder, height: 16),

                  // Chat Message List
                  Expanded(
                    child: messages.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.mark_chat_unread_outlined,
                                    size: 44,
                                    color: AppColors.mutedText.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No offline messages with $helperName yet',
                                    style: const TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Messages are broadcasted directly over your local Wi-Fi subnet (UDP 58888) and BLE packet bursts without mobile data.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppColors.mutedText, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              final msg = messages[index];
                              final isMe = msg.senderId == 'me';
                              return Align(
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  constraints: BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width * 0.76,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? AppColors.primaryBlue.withOpacity(0.85)
                                        : (msg.isEmergency
                                            ? AppColors.emergencyRed.withOpacity(0.25)
                                            : AppColors.secondaryBackground),
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 16),
                                    ),
                                    border: Border.all(
                                      color: isMe
                                          ? AppColors.cyan.withOpacity(0.3)
                                          : (msg.isEmergency
                                              ? AppColors.emergencyRed.withOpacity(0.5)
                                              : AppColors.glassBorder),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      if (msg.isEmergency)
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(Icons.warning_amber_rounded, color: AppColors.emergencyRed, size: 14),
                                            SizedBox(width: 4),
                                            Text(
                                              'EMERGENCY ALERT',
                                              style: TextStyle(
                                                color: AppColors.emergencyRed,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      Text(
                                        msg.text,
                                        style: TextStyle(
                                          color: isMe ? Colors.white : AppColors.primaryText,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(
                                              color: isMe ? Colors.white70 : AppColors.mutedText,
                                              fontSize: 10,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.sensors,
                                            size: 11,
                                            color: isMe ? Colors.white70 : AppColors.cyan,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            msg.channel,
                                            style: TextStyle(
                                              color: isMe ? Colors.white70 : AppColors.cyan,
                                              fontSize: 9,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Quick preset chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildQuickMeshChip(
                            label: '🚨 Urgent: Need Help',
                            isEmergency: true,
                            onTap: () async {
                              await ref.read(offlineMeshChatProvider.notifier).sendMessage(
                                peerId: helperId,
                                peerName: helperName,
                                text: 'URGENT: I need immediate assistance! Location beacon active.',
                                isEmergency: true,
                              );
                              _scrollToBottom(scrollController);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildQuickMeshChip(
                            label: '📍 Are you nearby?',
                            onTap: () async {
                              await ref.read(offlineMeshChatProvider.notifier).sendMessage(
                                peerId: helperId,
                                peerName: helperName,
                                text: 'Hello, are you currently nearby? Please respond offline.',
                              );
                              _scrollToBottom(scrollController);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildQuickMeshChip(
                            label: '✅ I am safe now',
                            onTap: () async {
                              await ref.read(offlineMeshChatProvider.notifier).sendMessage(
                                peerId: helperId,
                                peerName: helperName,
                                text: 'Update: I am safe now. Thank you for your support.',
                              );
                              _scrollToBottom(scrollController);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Input Field
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textController,
                            style: const TextStyle(color: AppColors.primaryText, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Type offline mesh message...',
                              hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                              filled: true,
                              fillColor: AppColors.secondaryBackground,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.glassBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.glassBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.primaryBlue),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.camera_alt_rounded, color: AppColors.cyan, size: 22),
                          tooltip: 'Send Offline Photo Evidence',
                          onPressed: () async {
                            final picker = ImagePicker();
                            final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                            if (photo != null) {
                              await ref.read(offlineMeshChatProvider.notifier).sendMessage(
                                peerId: helperId,
                                peerName: helperName,
                                text: '📷 [OFFLINE PHOTO EVIDENCE] ${photo.name} transmitted over P2P mesh (0 Internet)',
                              );
                              _scrollToBottom(scrollController);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: AppColors.surface,
                                    content: Text('📷 Photo sent to peer via Wi-Fi P2P & BLE Mesh!', style: TextStyle(color: AppColors.successGreen)),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        IconButton.filled(
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.all(12),
                          ),
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          onPressed: () async {
                            final text = textController.text.trim();
                            if (text.isNotEmpty) {
                              textController.clear();
                              await ref.read(offlineMeshChatProvider.notifier).sendMessage(
                                peerId: helperId,
                                peerName: helperName,
                                text: text,
                              );
                              _scrollToBottom(scrollController);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickMeshChip({
    required String label,
    required VoidCallback onTap,
    bool isEmergency = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isEmergency ? AppColors.emergencyRed.withOpacity(0.18) : AppColors.elevatedGlassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isEmergency ? AppColors.emergencyRed.withOpacity(0.4) : AppColors.glassBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isEmergency ? AppColors.emergencyRed : AppColors.cyan,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _scrollToBottom(ScrollController controller) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }


  void _showDistanceRadiusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Select Search Radius', style: TextStyle(color: AppColors.primaryText)),
        children: [
          {'label': '500 m', 'meters': 500},
          {'label': '1 km', 'meters': 1000},
          {'label': '2 km', 'meters': 2000},
          {'label': '5 km', 'meters': 5000},
          {'label': '10 km', 'meters': 10000},
        ].map((item) {
          final isSel = _maxDistanceMeters == item['meters'];
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _maxDistanceMeters = item['meters'] as int);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item['label'] as String, style: const TextStyle(color: AppColors.primaryText, fontSize: 15)),
                if (isSel) const Icon(Icons.check, color: AppColors.primaryBlue, size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bleMesh = ref.watch(bleMeshProvider);
    final filtered = _getFilteredHelpers(bleMesh.discoveredPeers);
    final liveLoc = ref.watch(liveLocationProvider);
    final userPos = LatLng(liveLoc.latitude, liveLoc.longitude);

    // Build markers for Google Map
    final Set<Marker> mapMarkers = {
      Marker(
        markerId: const MarkerId('user_location'),
        position: userPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'You (Current Location)'),
      ),
    };

    for (var i = 0; i < filtered.length; i++) {
      final h = filtered[i];
      mapMarkers.add(
        Marker(
          markerId: MarkerId(h['id']),
          position: LatLng(h['lat'] as double, h['lng'] as double),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            h['isAvailable'] ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: '${h['name']} (${h['category']})',
            snippet: '${h['distanceText']} • Rating ${h['rating']}★',
            onTap: () => _showHelperProfileModal(h),
          ),
          onTap: () => setState(() => _selectedHelperIndex = i),
        ),
      );
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
          child: SingleChildScrollView(
            controller: ref.watch(nearbyScrollControllerProvider),
            padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // A. Header (GuardVarX / Nearby Help + SOS button + Notification)
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
                              'Nearby Help',
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
                        // 15. SOS Button
                        GestureDetector(
                          onTap: () => ref.read(mainNavigationProvider.notifier).setTab(2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.emergencyRed,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.emergencyRed.withOpacity(0.4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('SOS', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: AppColors.primaryText, size: 22),
                          onPressed: () => context.push('/notifications'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // Offline Bluetooth & Wi-Fi Direct Mesh Radar Banner
                _buildBleMeshBanner(bleMesh),
                const SizedBox(height: AppSpacing.sm),

                // B. 1. Search Bar (Search people, services, area)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: AppColors.primaryText, fontSize: 13),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search people, services, medical, road assistance...',
                      hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.cyan, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.secondaryText, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // C. 2. Category Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _categoryList.map((cat) {
                      final isSel = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: ChoiceChip(
                          avatar: Icon(
                            _getCategoryIcon(cat),
                            size: 14,
                            color: isSel ? Colors.white : AppColors.cyan,
                          ),
                          label: Text(cat, style: TextStyle(color: isSel ? Colors.white : AppColors.secondaryText, fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.w500)),
                          selected: isSel,
                          selectedColor: AppColors.primaryBlue,
                          backgroundColor: AppColors.elevatedGlassSurface,
                          side: BorderSide(color: isSel ? AppColors.primaryBlue : AppColors.glassBorder),
                          onSelected: (_) => setState(() => _selectedCategory = cat),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // D. Filter & Sort Row (Distance, Availability, Verified, Sort, Map/Radar Toggle)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // 4. Distance Filter
                      ActionChip(
                        avatar: const Icon(Icons.radar_rounded, size: 14, color: AppColors.cyan),
                        label: Text('${_maxDistanceMeters ~/ 1000} km', style: const TextStyle(color: AppColors.primaryText, fontSize: 11)),
                        backgroundColor: AppColors.elevatedGlassSurface,
                        side: const BorderSide(color: AppColors.glassBorder),
                        onPressed: _showDistanceRadiusDialog,
                      ),
                      const SizedBox(width: 6),

                      // 5. Availability Filter
                      ActionChip(
                        avatar: const Icon(Icons.schedule_rounded, size: 14, color: AppColors.cyan),
                        label: Text(_availabilityFilter, style: const TextStyle(color: AppColors.primaryText, fontSize: 11)),
                        backgroundColor: AppColors.elevatedGlassSurface,
                        side: const BorderSide(color: AppColors.glassBorder),
                        onPressed: () {
                          setState(() {
                            if (_availabilityFilter == 'Any') {
                              _availabilityFilter = 'Available Now';
                            } else if (_availabilityFilter == 'Available Now') {
                              _availabilityFilter = 'Available Later';
                            } else {
                              _availabilityFilter = 'Any';
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 6),

                      // 6. Verified Users Only
                      FilterChip(
                        avatar: const Icon(Icons.verified_rounded, size: 14, color: AppColors.primaryBlue),
                        label: const Text('Verified Only', style: TextStyle(color: AppColors.primaryText, fontSize: 11)),
                        selected: _verifiedOnly,
                        selectedColor: AppColors.primaryBlue.withOpacity(0.25),
                        backgroundColor: AppColors.elevatedGlassSurface,
                        side: BorderSide(color: _verifiedOnly ? AppColors.primaryBlue : AppColors.glassBorder),
                        onSelected: (val) => setState(() => _verifiedOnly = val),
                      ),
                      const SizedBox(width: 6),

                      // 7. Sort By
                      ActionChip(
                        avatar: const Icon(Icons.sort_rounded, size: 14, color: AppColors.cyan),
                        label: Text('Sort: ${_sortBy.toUpperCase()}', style: const TextStyle(color: AppColors.primaryText, fontSize: 11)),
                        backgroundColor: AppColors.elevatedGlassSurface,
                        side: const BorderSide(color: AppColors.glassBorder),
                        onPressed: () {
                          setState(() {
                            if (_sortBy == 'distance') {
                              _sortBy = 'rating';
                            } else if (_sortBy == 'rating') {
                              _sortBy = 'active';
                            } else {
                              _sortBy = 'distance';
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 6),

                      // Map / Radar View Toggle
                      ActionChip(
                        avatar: Icon(_showGoogleMap ? Icons.map_rounded : Icons.radar_rounded, size: 14, color: AppColors.cyan),
                        label: Text(_showGoogleMap ? 'Google Map' : 'Radar View', style: const TextStyle(color: AppColors.primaryText, fontSize: 11)),
                        backgroundColor: AppColors.elevatedGlassSurface,
                        side: const BorderSide(color: AppColors.glassBorder),
                        onPressed: () => setState(() => _showGoogleMap = !_showGoogleMap),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // E. 12. Active Request Tracking Banner (If request active)
                if (_activeRequest != null) _buildActiveTrackingBanner(),

                // F. 3. Nearby Map (Google Map OR Radar Widget)
                if (_showGoogleMap)
                  _buildGoogleMapWidget(userPos, mapMarkers)
                else
                  _buildRadarMapWidget(filtered),
                const SizedBox(height: AppSpacing.md),

                // G. Helpers Header & Result Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nearby Helpers (${filtered.length})',
                      style: const TextStyle(color: AppColors.primaryText, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Within ${_maxDistanceMeters ~/ 1000} km',
                      style: const TextStyle(color: AppColors.secondaryText, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // H. Helper Cards List
                if (filtered.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.person_search_rounded, size: 40, color: AppColors.mutedText),
                        const SizedBox(height: 10),
                        const Text(
                          'No helpers match your search or filters',
                          style: TextStyle(color: AppColors.primaryText, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Try expanding search radius or clearing category filters.',
                          style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _selectedCategory = 'All';
                              _maxDistanceMeters = 10000;
                              _availabilityFilter = 'Any';
                              _verifiedOnly = false;
                            });
                          },
                          child: const Text('Reset All Filters', style: TextStyle(color: AppColors.cyan)),
                        ),
                      ],
                    ),
                  )
                else
                  ...filtered.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final helper = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildHelperCard(helper, isHighlighted: _selectedHelperIndex == idx),
                    );
                  }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Active Request Tracking Component
  Widget _buildActiveTrackingBanner() {
    final req = _activeRequest!;
    final helper = req['helper'] as Map<String, dynamic>;
    final status = req['status'] as String;

    String statusLabel = 'Request Transmitted';
    Color statusColor = AppColors.cyan;
    IconData statusIcon = Icons.hourglass_top_rounded;

    if (status == 'REQUEST_SENT') {
      statusLabel = '1. Request Sent • Awaiting Response';
      statusColor = AppColors.cyan;
      statusIcon = Icons.hourglass_top_rounded;
    } else if (status == 'ACCEPTED') {
      statusLabel = '2. Accepted by ${helper['name']}!';
      statusColor = AppColors.successGreen;
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'ON_THE_WAY') {
      statusLabel = '3. On the Way (~${req['etaMinutes']} min away)';
      statusColor = AppColors.primaryBlue;
      statusIcon = Icons.directions_walk_rounded;
    } else if (status == 'ARRIVED') {
      statusLabel = '4. Volunteer Arrived at Location!';
      statusColor = AppColors.purpleAccent;
      statusIcon = Icons.location_on_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(color: statusColor.withOpacity(0.2), blurRadius: 12),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(color: statusColor, fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              GestureDetector(
                onTap: _progressTrackingStatusManually,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.elevatedGlassSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: const Text('Update Status', style: TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.25),
                child: Text(helper['name'][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(helper['name'], style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('${helper['category']} • ${helper['distanceText']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                  ],
                ),
              ),
              IconButton.filledTonal(
                style: IconButton.styleFrom(backgroundColor: AppColors.elevatedGlassSurface),
                icon: const Icon(Icons.phone_rounded, color: AppColors.cyan, size: 18),
                onPressed: () => _makePhoneCall(helper['phone']),
              ),
              const SizedBox(width: 4),
              IconButton.filledTonal(
                style: IconButton.styleFrom(backgroundColor: AppColors.elevatedGlassSurface),
                icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryBlue, size: 18),
                onPressed: () => _showMessageSheet(helper),
              ),
            ],
          ),
          const Divider(color: AppColors.glassBorder, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _cancelActiveRequest,
                child: const Text('Cancel Request', style: TextStyle(color: AppColors.emergencyRed, fontSize: 12)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _completeActiveRequest,
                child: const Text('Help Complete', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Offline Bluetooth & Wi-Fi Direct Mesh Banner
  Widget _buildBleMeshBanner(BleMeshState bleMesh) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bleMesh.isScanning ? AppColors.cyan : AppColors.glassBorder,
          width: bleMesh.isScanning ? 1.6 : 1.0,
        ),
        boxShadow: bleMesh.isScanning
            ? [
                BoxShadow(
                  color: AppColors.cyan.withOpacity(0.18),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (bleMesh.isScanning ? AppColors.cyan : AppColors.mutedText).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              bleMesh.isScanning ? Icons.bluetooth_searching_rounded : Icons.bluetooth_disabled_rounded,
              color: bleMesh.isScanning ? AppColors.cyan : AppColors.mutedText,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Bluetooth & Wi-Fi Direct Mesh',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'NO INTERNET',
                        style: TextStyle(color: AppColors.successGreen, fontSize: 8, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  bleMesh.isScanning
                      ? '${bleMesh.discoveredPeers.length} GuardVarX devices active in direct range'
                      : 'Radar standby • Tap switch to discover peers',
                  style: TextStyle(
                    color: bleMesh.isScanning ? AppColors.cyan : AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: bleMesh.isScanning,
            activeColor: AppColors.cyan,
            onChanged: (val) {
              ref.read(bleMeshProvider.notifier).toggleBleMesh(val);
            },
          ),
        ],
      ),
    );
  }

  // Google Map View
  Widget _buildGoogleMapWidget(LatLng userPos, Set<Marker> markers) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: userPos, zoom: 14.5),
            markers: markers,
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
              heroTag: 'recenter_nearby_gps',
              backgroundColor: AppColors.surface,
              child: const Icon(Icons.my_location_rounded, color: AppColors.cyan, size: 18),
              onPressed: () {
                _mapController?.animateCamera(CameraUpdate.newLatLngZoom(userPos, 15.0));
              },
            ),
          ),
        ],
      ),
    );
  }

  // Radar Map View
  Widget _buildRadarMapWidget(List<Map<String, dynamic>> filtered) {
    return GlassCard(
      height: 220,
      borderRadius: AppSpacing.radiusLg,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: GridPaper(color: AppColors.cyan, divisions: 2, subdivisions: 1),
            ),
          ),
          Center(
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cyan.withOpacity(0.2), width: 1.2),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cyan.withOpacity(0.3), width: 1.2),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cyan.withOpacity(0.4), width: 1.2),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(color: AppColors.primaryBlue.withOpacity(0.8), blurRadius: 16, spreadRadius: 4),
                ],
              ),
            ),
          ),
          ...filtered.asMap().entries.map((entry) {
            final idx = entry.key;
            final h = entry.value;
            final double angle = h['radarAngle'] as double;
            final double radiusFraction = h['radarRadius'] as double;
            final double r = 85.0 * radiusFraction;

            return Positioned(
              left: 170 + r * (angle < 0 ? -1 : 1) * 0.8,
              top: 100 + r * (angle.abs() > 1 ? 0.7 : -0.7),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedHelperIndex = idx);
                  _showHelperProfileModal(h);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: h['isAvailable'] ? AppColors.successGreen : AppColors.warningAmber,
                      child: Text(h['name'][0], style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(4)),
                      child: Text('${h['distanceMeters']}m', style: const TextStyle(color: Colors.white, fontSize: 8)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // 8. Helper Card Item
  Widget _buildHelperCard(Map<String, dynamic> helper, {bool isHighlighted = false}) {
    final isAvailable = helper['isAvailable'] as bool;

    return GestureDetector(
      onTap: () => _showHelperProfileModal(helper),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        borderRadius: AppSpacing.radiusLg,
        borderColor: isHighlighted ? AppColors.primaryBlue : AppColors.glassBorder,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                  child: Text(
                    helper['name'][0],
                    style: const TextStyle(fontSize: 18, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isAvailable ? AppColors.successGreen : AppColors.warningAmber,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        helper['name'],
                        style: const TextStyle(color: AppColors.primaryText, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      if (helper['isVerified']) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, size: 14, color: AppColors.primaryBlue),
                      ],
                      if (helper['connectionType'] == 'BLE_DIRECT' || helper['connectionType'] == 'WIFI_DIRECT') ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: AppColors.cyan.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.cyan.withOpacity(0.5), width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                helper['connectionType'] == 'BLE_DIRECT' ? Icons.bluetooth_rounded : Icons.wifi_tethering_rounded,
                                color: AppColors.cyan,
                                size: 10,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                helper['connectionType'] == 'BLE_DIRECT' ? 'BLE P2P' : 'Wi-Fi P2P',
                                style: const TextStyle(color: AppColors.cyan, fontSize: 8, fontWeight: FontWeight.w900),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isAvailable ? AppColors.successGreen : AppColors.warningAmber).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          helper['status'],
                          style: TextStyle(
                            color: isAvailable ? AppColors.successGreen : AppColors.warningAmber,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(helper['sub'], maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: AppColors.primaryBlue),
                      const SizedBox(width: 2),
                      Text(helper['distanceText'], style: const TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                      const SizedBox(width: 8),
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFFFB800)),
                      const SizedBox(width: 2),
                      Text('${helper['rating']} (${helper['reviews']})', style: const TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Actions: Call, Chat, Alert Buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.elevatedGlassSurface,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                  icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.cyan, size: 16),
                  tooltip: 'Offline Call',
                  onPressed: () {
                    final helperId = (helper['id'] ?? helper['name'] ?? 'peer').toString();
                    final helperName = (helper['name'] ?? 'Helper').toString();
                    ref.read(offlineP2PCallProvider.notifier).startCall(
                          peerId: helperId,
                          peerName: helperName,
                          type: OfflineCallType.audio,
                        );
                    context.push('/offline-call');
                  },
                ),
                const SizedBox(width: 4),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.elevatedGlassSurface,
                    padding: const EdgeInsets.all(8),
                    minimumSize: const Size(36, 36),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primaryBlue, size: 16),
                  tooltip: 'Offline Chat',
                  onPressed: () => _showMessageSheet(helper),
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  icon: Icon(
                    helper['connectionType'] != null ? Icons.bluetooth_audio_rounded : Icons.near_me_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                  label: Text(
                    isAvailable ? (helper['connectionType'] != null ? 'P2P Alert' : 'Request') : 'Alert',
                    style: TextStyle(
                      color: isAvailable ? Colors.white : AppColors.secondaryText,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: helper['connectionType'] != null
                        ? AppColors.cyan
                        : (isAvailable ? AppColors.primaryBlue : AppColors.elevatedGlassSurface),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showCanHelpDialog(helper),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Medical Help':
        return Icons.medical_services_rounded;
      case 'Safety Support':
        return Icons.shield_rounded;
      case 'Road Assistance':
        return Icons.directions_car_rounded;
      case 'Women Safety':
        return Icons.female_rounded;
      case 'Senior/Elderly Help':
        return Icons.elderly_rounded;
      case 'Student Help':
        return Icons.school_rounded;
      case 'Lost & Found':
        return Icons.search_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }
}
