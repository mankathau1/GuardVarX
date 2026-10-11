import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/navigation_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/glass_card.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _posts = [
    {
      'id': 'post_1',
      'category': 'Safety Alerts',
      'type': 'Safety Alert',
      'icon': Icons.shield_rounded,
      'iconColor': AppColors.emergencyRed,
      'badge': 'High Priority',
      'badgeColor': AppColors.emergencyRed,
      'timeLocation': '2 hours ago • Anna Salai, Chennai',
      'title': 'Suspicious activity reported',
      'description':
          'A user reported a suspicious person loitering near the Anna Salai metro station. Please stay alert and avoid the area if possible.',
      'likes': 24,
      'comments': 8,
      'hasLiked': false,
      'actionText': 'View on Map >',
      'actionRoute': '/location-details',
      'imageUrl': 'assets/sample_street.jpg',
    },
    {
      'id': 'post_2',
      'category': 'Missing People',
      'type': 'Missing Person',
      'icon': Icons.person_search_rounded,
      'iconColor': AppColors.purpleAccent,
      'badge': 'Verifying',
      'badgeColor': AppColors.warningAmber,
      'timeLocation': '5 hours ago • T. Nagar, Chennai',
      'title': 'Missing: 17-year-old girl',
      'description':
          'Last seen near T. Nagar bus stand at 6:30 PM. Wearing blue jeans and white top. If you have any information, please contact the number below.',
      'likes': 118,
      'comments': 32,
      'hasLiked': false,
      'actionText': 'View Details >',
      'actionRoute': null,
      'imageUrl': 'assets/sample_person.jpg',
    },
    {
      'id': 'post_3',
      'category': 'Lost & Found',
      'type': 'Lost & Found',
      'icon': Icons.lock_outline_rounded,
      'iconColor': AppColors.successGreen,
      'badge': 'Resolved',
      'badgeColor': AppColors.successGreen,
      'timeLocation': '8 hours ago • Guindy, Chennai',
      'title': 'Found: Black wallet',
      'description':
          'A black wallet was found near Guindy railway station. Contains ID cards. Contact to claim.',
      'likes': 36,
      'comments': 12,
      'hasLiked': false,
      'actionText': 'View Details >',
      'actionRoute': null,
      'imageUrl': 'assets/sample_wallet.jpg',
    },
    {
      'id': 'post_4',
      'category': 'Helpful Tips',
      'type': 'Help & Information',
      'icon': Icons.info_outline_rounded,
      'iconColor': AppColors.cyan,
      'badge': null,
      'badgeColor': null,
      'timeLocation': '1 day ago • Chennai',
      'title': 'Safety Tip: Travelling at night',
      'description':
          'Try to share your live location with a trusted contact when travelling alone at night. Use well-lit routes and stay aware of your surroundings.',
      'likes': 92,
      'comments': 15,
      'hasLiked': false,
      'actionText': 'Read More >',
      'actionRoute': null,
      'imageUrl': 'assets/sample_night.jpg',
    },
  ];

  List<Map<String, dynamic>> get _filteredPosts {
    final query = _searchController.text.trim().toLowerCase();
    return _posts.where((p) {
      if (_selectedFilter != 'All' && p['category'] != _selectedFilter) {
        return false;
      }
      if (query.isNotEmpty) {
        final title = (p['title'] as String).toLowerCase();
        final desc = (p['description'] as String).toLowerCase();
        final loc = (p['timeLocation'] as String).toLowerCase();
        if (!title.contains(query) && !desc.contains(query) && !loc.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _showCommentSheet(Map<String, dynamic> post) {
    final commentController = TextEditingController();
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
                  Text('Comments (${post['comments']})', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.close, color: AppColors.secondaryText), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(color: AppColors.glassBorder),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: AppColors.primaryBlue, radius: 14, child: Text('S', style: TextStyle(color: Colors.white, fontSize: 11))),
                title: const Text('Sunita V.', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                subtitle: const Text('Police patrol was alerted in Anna Salai. Area under watch.', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: commentController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Add verified comment...',
                        hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                        filled: true,
                        fillColor: AppColors.secondaryBackground,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send_rounded, color: AppColors.cyan),
                    onPressed: () {
                      if (commentController.text.isNotEmpty) {
                        setState(() => post['comments'] = (post['comments'] as int) + 1);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Comment posted.')));
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

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPosts;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 100.0), // Padding above floating bottom bar
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // A. Header (GuardVarX / Community + Bell + Avatar)
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
                            'Community',
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
              const SizedBox(height: 2),
              const Text(
                'A safer community, together.',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.md),

              // B. Search Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: AppColors.secondaryText, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        decoration: const InputDecoration(
                          hintText: 'Search posts, areas, topics...',
                          hintStyle: TextStyle(color: AppColors.mutedText, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        child: const Icon(Icons.clear, color: AppColors.secondaryText, size: 18),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // C. Filter Pills
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill('All', Icons.grid_view_rounded),
                    const SizedBox(width: 8),
                    _buildFilterPill('Safety Alerts', Icons.shield_rounded),
                    const SizedBox(width: 8),
                    _buildFilterPill('Missing People', Icons.person_search_rounded),
                    const SizedBox(width: 8),
                    _buildFilterPill('Lost & Found', Icons.lock_outline_rounded),
                    const SizedBox(width: 8),
                    _buildFilterPill('Helpful Tips', Icons.lightbulb_outline_rounded),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // D. Recent Safety Alerts Near You Card (Red glowing banner with map thumbnail)
              GlassCard(
                borderRadius: AppSpacing.radiusLg,
                borderColor: AppColors.emergencyRed.withOpacity(0.4),
                glowColor: AppColors.emergencyRedGlow,
                glowRadius: 14,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.emergencyRed.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: AppColors.emergencyRed, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Recent Safety Alerts Near You',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('3 new reports in your area >',
                              style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/location-details'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.elevatedGlassSurface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: const Text('View on Map >',
                            style: TextStyle(color: AppColors.cyan, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // E. Community Feed Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Community Feed', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.elevatedGlassSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.location_on_rounded, size: 12, color: AppColors.primaryBlue),
                        SizedBox(width: 4),
                        Text('Nearby', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                        Icon(Icons.keyboard_arrow_down, size: 14, color: AppColors.secondaryText),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // F. Feed Posts List
              ...filtered.map((post) => Padding(
                    padding: const EdgeInsets.only(bottom: 14.0),
                    child: _buildFeedCard(post),
                  )),

              const SizedBox(height: AppSpacing.md),

              // G. Community Impact Widget
              GlassCard(
                borderRadius: AppSpacing.radiusLg,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.groups_rounded, color: AppColors.cyan, size: 20),
                        SizedBox(width: 8),
                        Text('Community Impact', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildImpactItem('12.4K', 'Active Members', Icons.person_outline, AppColors.cyan),
                        _buildImpactItem('317', 'Reports Resolved', Icons.check_circle_outline, AppColors.successGreen),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildImpactItem('8', 'Missing People Found', Icons.person_search_outlined, AppColors.emergencyRed),
                        _buildImpactItem('1.2K', 'Safety Tips Shared', Icons.lightbulb_outline, AppColors.warningAmber),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // H. Glowing "Report Something" Card
              GestureDetector(
                onTap: () => context.push('/report'),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: AppColors.primaryBlue.withOpacity(0.5), blurRadius: 16, spreadRadius: 1),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Report Something', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            SizedBox(height: 2),
                            Text('Help make places safer for everyone', style: TextStyle(color: Colors.white70, fontSize: 11)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // I. Safety Topics List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Safety Topics', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('See All >', style: TextStyle(color: AppColors.cyan, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 10),
              _buildSafetyTopicItem("Women's Safety", '1.2K posts', Icons.security_rounded, AppColors.purpleAccent),
              const SizedBox(height: 6),
              _buildSafetyTopicItem('Travel Safety', '856 posts', Icons.directions_car_rounded, AppColors.primaryBlue),
              const SizedBox(height: 6),
              _buildSafetyTopicItem('Student Safety', '642 posts', Icons.school_rounded, AppColors.cyan),
              const SizedBox(height: 6),
              _buildSafetyTopicItem('Neighbourhood Watch', '518 posts', Icons.home_rounded, AppColors.warningAmber),
              const SizedBox(height: 6),
              _buildSafetyTopicItem('Elderly Safety', '431 posts', Icons.favorite_rounded, AppColors.emergencyRed),
              const SizedBox(height: 6),
              _buildSafetyTopicItem('Disaster Preparedness', '298 posts', Icons.tsunami_rounded, AppColors.cyan),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill(String title, IconData icon) {
    final isSelected = _selectedFilter == title;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue.withOpacity(0.3) : AppColors.glassSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.cyan),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.secondaryText,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedCard(Map<String, dynamic> post) {
    final hasLiked = post['hasLiked'] as bool;
    final likes = post['likes'] as int;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: AppSpacing.radiusLg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category, Time, Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (post['iconColor'] as Color).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(post['icon'] as IconData, size: 16, color: post['iconColor'] as Color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post['type'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(post['timeLocation'] as String, style: const TextStyle(color: AppColors.secondaryText, fontSize: 10)),
                  ],
                ),
              ),
              if (post['badge'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (post['badgeColor'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: post['badgeColor'] as Color),
                  ),
                  child: Text(post['badge'] as String, style: TextStyle(color: post['badgeColor'] as Color, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Title & Description
          Text(post['title'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            post['description'] as String,
            style: const TextStyle(color: AppColors.secondaryText, fontSize: 12, height: 1.35),
          ),
          const SizedBox(height: 12),

          // Action row: Likes, Comments, Share, and Route Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        post['hasLiked'] = !hasLiked;
                        post['likes'] = hasLiked ? likes - 1 : likes + 1;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(hasLiked ? Icons.thumb_up_alt : Icons.thumb_up_alt_outlined, size: 14, color: hasLiked ? AppColors.cyan : AppColors.secondaryText),
                        const SizedBox(width: 4),
                        Text('$likes', style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () => _showCommentSheet(post),
                    child: Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 14, color: AppColors.secondaryText),
                        const SizedBox(width: 4),
                        Text('${post['comments']}', style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Safety alert link copied to share.')));
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.share_outlined, size: 14, color: AppColors.secondaryText),
                        SizedBox(width: 4),
                        Text('Share', style: TextStyle(color: AppColors.secondaryText, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  if (post['actionRoute'] != null) {
                    context.push(post['actionRoute'] as String);
                  } else {
                    _showCommentSheet(post);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.elevatedGlassSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Text(post['actionText'] as String, style: const TextStyle(color: AppColors.cyan, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactItem(String val, String label, IconData icon, Color color) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(label, style: const TextStyle(color: AppColors.secondaryText, fontSize: 9)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTopicItem(String title, String count, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: 12.0,
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
          Text(count, style: const TextStyle(color: AppColors.secondaryText, fontSize: 11)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded, color: AppColors.secondaryText, size: 16),
        ],
      ),
    );
  }
}
