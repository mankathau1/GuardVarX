import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_card.dart';

class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  String _selectedCategory = 'All';
  String _searchRadius = '2 km';
  String _sortCriteria = 'distance';
  String _mapLayer = 'Dark Standard';
  int? _selectedHelperIndex;

  final List<Map<String, dynamic>> _helpers = [
    {
      'id': 'h_1',
      'name': 'Arunkumar S.',
      'category': 'Safety',
      'sub': 'General Help • Safety Support',
      'distanceMeters': 320,
      'distanceText': '320 m away',
      'rating': 4.8,
      'reviews': 32,
      'status': 'Available',
      'isAvailable': true,
      'isVerified': true,
      'avatarUrl': '',
      'radarAngle': -0.4, // Radians on radar
      'radarRadius': 0.55,
    },
    {
      'id': 'h_2',
      'name': 'Priya M.',
      'category': 'Medical',
      'sub': 'Medical Support • First Aid',
      'distanceMeters': 260,
      'distanceText': '260 m away',
      'rating': 4.9,
      'reviews': 48,
      'status': 'Available',
      'isAvailable': true,
      'isVerified': true,
      'avatarUrl': '',
      'radarAngle': 0.35,
      'radarRadius': 0.45,
    },
    {
      'id': 'h_3',
      'name': 'Vikram R.',
      'category': 'Road',
      'sub': 'Vehicle/Travel Support',
      'distanceMeters': 550,
      'distanceText': '550 m away',
      'rating': 4.7,
      'reviews': 21,
      'status': 'Busy',
      'isAvailable': false,
      'isVerified': true,
      'avatarUrl': '',
      'radarAngle': 0.85,
      'radarRadius': 0.8,
    },
    {
      'id': 'h_4',
      'name': 'Kavitha N.',
      'category': 'Safety',
      'sub': 'Women Safety Escort',
      'distanceMeters': 480,
      'distanceText': '480 m away',
      'rating': 4.9,
      'reviews': 54,
      'status': 'Available',
      'isAvailable': true,
      'isVerified': true,
      'avatarUrl': '',
      'radarAngle': -1.2,
      'radarRadius': 0.7,
    },
    {
      'id': 'h_5',
      'name': 'Deepak K.',
      'category': 'Road',
      'sub': 'Two-Wheeler Support',
      'distanceMeters': 710,
      'distanceText': '710 m away',
      'rating': 4.6,
      'reviews': 18,
      'status': 'Available',
      'isAvailable': true,
      'isVerified': true,
      'avatarUrl': '',
      'radarAngle': -2.2,
      'radarRadius': 0.85,
    },
  ];

  List<Map<String, dynamic>> get _filteredHelpers {
    var list = _helpers.where((h) {
      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Medical') return h['category'] == 'Medical';
      if (_selectedCategory == 'Safety') return h['category'] == 'Safety';
      if (_selectedCategory == 'Road') return h['category'] == 'Road';
      return true;
    }).toList();

    if (_sortCriteria == 'distance') {
      list.sort((a, b) => (a['distanceMeters'] as int).compareTo(b['distanceMeters'] as int));
    } else {
      list.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
    }
    return list;
  }

  void _showCanHelpDialog(Map<String, dynamic> helper) {
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
            Text('Request Help from ${helper['name']}', style: const TextStyle(color: AppColors.primaryText, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${helper['name']} will receive your approximate location (Anna Salai, Teynampet, ~${helper['distanceText']}).',
              style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.elevatedGlassSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 16, color: AppColors.cyan),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('Your exact coordinate is protected until helper accepts.',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.surface,
                  content: Text('Help request dispatched to ${helper['name']}. Status: Awaiting Acceptance.',
                      style: const TextStyle(color: AppColors.successGreen)),
                ),
              );
            },
            child: const Text('Send Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showMessageSheet(Map<String, dynamic> helper) {
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: AppColors.glassBorder)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                        child: Text(helper['name'][0], style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Message ${helper['name']}', style: const TextStyle(color: AppColors.primaryText, fontWeight: FontWeight.bold)),
                          Text(helper['sub'], style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.secondaryText),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: AppColors.glassBorder, height: 24),
              // Safety Quick templates
              Wrap(
                spacing: 6,
                children: [
                  ActionChip(
                    backgroundColor: AppColors.elevatedGlassSurface,
                    label: const Text('Need assistance nearby', style: TextStyle(color: AppColors.cyan, fontSize: 11)),
                    onPressed: () => textController.text = 'Hello, I need quick assistance near Anna Salai.',
                  ),
                  ActionChip(
                    backgroundColor: AppColors.elevatedGlassSurface,
                    label: const Text('Are you available now?', style: TextStyle(color: AppColors.cyan, fontSize: 11)),
                    onPressed: () => textController.text = 'Are you available to assist me right now?',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: textController,
                      style: const TextStyle(color: AppColors.primaryText),
                      decoration: InputDecoration(
                        hintText: 'Type secure message...',
                        hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.secondaryBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.primaryBlue),
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () {
                      if (textController.text.trim().isNotEmpty) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.surface,
                            content: Text('Message sent to ${helper['name']}. Status: Delivered.',
                                style: const TextStyle(color: AppColors.successGreen)),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRadiusDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Select Search Radius', style: TextStyle(color: AppColors.primaryText)),
        children: ['500 m', '1 km', '2 km', '5 km'].map((r) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _searchRadius = r);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r, style: const TextStyle(color: AppColors.primaryText, fontSize: 15)),
                if (_searchRadius == r) const Icon(Icons.check, color: AppColors.primaryBlue, size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showLayersDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Map Display Style', style: TextStyle(color: AppColors.primaryText)),
        children: ['Dark Standard', 'Satellite Imagery', 'Terrain & Metro'].map((l) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _mapLayer = l);
              Navigator.pop(ctx);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l, style: const TextStyle(color: AppColors.primaryText, fontSize: 15)),
                if (_mapLayer == l) const Icon(Icons.check, color: AppColors.cyan, size: 20),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredHelpers;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 100.0), // Padding above floating bottom bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. Header (GuardVarX / Nearby Help + notification bell + avatar)
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
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: AppColors.primaryText, size: 24),
                        onPressed: () => context.push('/notifications'),
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

              // B. Top Card: Nearby Helpers / Verified Users
              GlassCard(
                borderRadius: AppSpacing.radiusLg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.people_rounded, color: AppColors.primaryBlue, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Nearby Helpers',
                            style: TextStyle(color: AppColors.primaryText, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Find trusted people around you',
                            style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.elevatedGlassSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_user_rounded, color: AppColors.cyan, size: 16),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Verified Users', style: TextStyle(color: AppColors.secondaryText, fontSize: 9)),
                              Text('128 near you', style: TextStyle(color: AppColors.primaryText, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // C. Category Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill('All', Icons.gps_fixed_rounded, AppColors.cyan),
                    const SizedBox(width: 8),
                    _buildFilterPill('Medical', Icons.medical_services_rounded, AppColors.emergencyRed),
                    const SizedBox(width: 8),
                    _buildFilterPill('Safety', Icons.shield_rounded, AppColors.primaryBlue),
                    const SizedBox(width: 8),
                    _buildFilterPill('Road', Icons.directions_car_rounded, AppColors.cyan),
                    const SizedBox(width: 8),
                    _buildMoreFilterPill(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // D. Radar Map Widget with Helper Markers & Controls
              _buildRadarMapWidget(),
              const SizedBox(height: AppSpacing.md),

              // E. Location Card & Search Radius row
              Row(
                children: [
                  Expanded(
                    flex: 6,
                    child: GlassCard(
                      onTap: () => context.push('/location-details'),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      borderRadius: AppSpacing.radiusMd,
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: AppColors.primaryBlue, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Your Location', style: TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                                Text('Anna Salai, Teynampet, Chennai',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(color: AppColors.primaryText, fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText, size: 16),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 4,
                    child: GlassCard(
                      onTap: _showRadiusDialog,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      borderRadius: AppSpacing.radiusMd,
                      child: Row(
                        children: [
                          const Icon(Icons.radar_rounded, color: AppColors.cyan, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text('Search in $_searchRadius',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.primaryText, fontSize: 12, fontWeight: FontWeight.w600)),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppColors.secondaryText, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // F. Section Header: Nearby Helpers + Sort
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Nearby Helpers',
                    style: TextStyle(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _sortCriteria = _sortCriteria == 'distance' ? 'rating' : 'distance';
                      });
                    },
                    child: Row(
                      children: [
                        Text('Sorted by $_sortCriteria', style: const TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                        const SizedBox(width: 4),
                        const Icon(Icons.swap_vert_rounded, color: AppColors.cyan, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // G. Helper Cards List
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
    );
  }

  Widget _buildFilterPill(String title, IconData icon, Color activeColor) {
    final isSelected = _selectedCategory == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withOpacity(0.25) : AppColors.glassSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.glassBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.35),
                    blurRadius: 10,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : activeColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.secondaryText,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreFilterPill() {
    return PopupMenuButton<String>(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.glassBorder)),
      onSelected: (val) => setState(() => _selectedCategory = val),
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'Women Safety', child: Text("Women's Safety", style: TextStyle(color: AppColors.primaryText))),
        const PopupMenuItem(value: 'Disaster', child: Text('Disaster Support', style: TextStyle(color: AppColors.primaryText))),
        const PopupMenuItem(value: 'All', child: Text('Reset to All', style: TextStyle(color: AppColors.cyan))),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: const [
            Icon(Icons.auto_awesome, size: 16, color: AppColors.cyan),
            SizedBox(width: 6),
            Text('More', style: TextStyle(color: AppColors.secondaryText, fontSize: 13)),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.secondaryText),
          ],
        ),
      ),
    );
  }

  Widget _buildRadarMapWidget() {
    return GlassCard(
      height: 250,
      borderRadius: AppSpacing.radiusLg,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          // Background Map Texture grid
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: GridPaper(
                color: AppColors.cyan,
                divisions: 2,
                subdivisions: 1,
              ),
            ),
          ),

          // Radar Concentric Circles
          Center(
            child: Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.cyan.withOpacity(0.2), width: 1.2),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 140,
              height: 140,
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

          // Center User Pulsating Position Dot
          Center(
            child: Container(
              width: 22,
              height: 22,
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

          // Helper Markers Positioned Radially on Radar
          ..._helpers.asMap().entries.map((entry) {
            final idx = entry.key;
            final h = entry.value;
            final double angle = h['radarAngle'] as double;
            final double radiusFraction = h['radarRadius'] as double;
            final double r = 95.0 * radiusFraction;

            return Positioned(
              left: 175 + r * (angle < 0 ? -1 : 1) * 0.8,
              top: 115 + r * (angle.abs() > 1 ? 0.7 : -0.7),
              child: GestureDetector(
                onTap: () => setState(() => _selectedHelperIndex = idx),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 17,
                          backgroundColor: AppColors.primaryBlue.withOpacity(0.3),
                          child: Text(h['name'][0], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: h['isAvailable'] ? AppColors.successGreen : AppColors.warningAmber,
                              border: Border.all(color: Colors.black, width: 1.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${h['distanceMeters']}m',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Floating Map Control Buttons (Compass, Layers, Recenter)
          Positioned(
            right: 12,
            top: 12,
            child: Column(
              children: [
                _buildMapActionButton(Icons.navigation_rounded, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bearing locked north', style: TextStyle(color: AppColors.cyan))),
                  );
                }),
                const SizedBox(height: 8),
                _buildMapActionButton(Icons.layers_rounded, _showLayersDialog),
                const SizedBox(height: 8),
                _buildMapActionButton(Icons.my_location_rounded, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recentered on Anna Salai, Teynampet', style: TextStyle(color: AppColors.successGreen))),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.85),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _buildHelperCard(Map<String, dynamic> helper, {bool isHighlighted = false}) {
    final isAvailable = helper['isAvailable'] as bool;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: AppSpacing.radiusLg,
      borderColor: isHighlighted ? AppColors.primaryBlue : AppColors.glassBorder,
      glowColor: isHighlighted ? AppColors.blueGlow : null,
      glowRadius: isHighlighted ? 14 : 0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar with green/amber status badge
          Stack(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                child: Text(
                  helper['name'][0],
                  style: const TextStyle(fontSize: 20, color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isAvailable ? AppColors.successGreen : AppColors.warningAmber,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // Name, Category, Distance, Rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      helper['name'],
                      style: const TextStyle(color: AppColors.primaryText, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, size: 16, color: AppColors.primaryBlue),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isAvailable ? AppColors.successGreen : AppColors.warningAmber).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
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
                Text(
                  helper['sub'],
                  style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.primaryBlue),
                    const SizedBox(width: 2),
                    Text(helper['distanceText'], style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                    const SizedBox(width: 12),
                    const Icon(Icons.star_rounded, size: 15, color: Color(0xFFFFB800)),
                    const SizedBox(width: 2),
                    Text('${helper['rating']} (${helper['reviews']})', style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Action Button: "Can Help" (Blue illuminated) OR "Message" (Glass outline)
          if (isAvailable)
            GestureDetector(
              onTap: () => _showCanHelpDialog(helper),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppColors.primaryBlue.withOpacity(0.4), blurRadius: 8),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.near_me_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Can Help', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _showMessageSheet(helper),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: AppColors.elevatedGlassSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('Message', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
