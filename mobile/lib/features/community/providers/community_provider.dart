import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';

class CommunityReportItem {
  final String id;
  final String category;
  final String title;
  final String description;
  final double latitudeFuzzed;
  final double longitudeFuzzed;
  final int upvotes;
  final DateTime createdAt;

  CommunityReportItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.latitudeFuzzed,
    required this.longitudeFuzzed,
    required this.upvotes,
    required this.createdAt,
  });

  factory CommunityReportItem.fromJson(Map<String, dynamic> json) {
    return CommunityReportItem(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'GENERAL',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      latitudeFuzzed: (json['latitude_fuzzed'] as num?)?.toDouble() ?? 0.0,
      longitudeFuzzed: (json['longitude_fuzzed'] as num?)?.toDouble() ?? 0.0,
      upvotes: json['upvotes'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class CommunityNotifier extends StateNotifier<List<CommunityReportItem>> {
  final ApiClient apiClient;

  CommunityNotifier(this.apiClient) : super([]) {
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.communityReports);
      final list = (res.data as List).map((i) => CommunityReportItem.fromJson(i as Map<String, dynamic>)).toList();
      state = list;
    } catch (_) {
      if (state.isEmpty) {
        state = [
          CommunityReportItem(
            id: 'rep_1',
            category: 'POOR_LIGHTING',
            title: 'Dark pedestrian walkway near Metro Gate 2',
            description: 'Street lamps not functional along 300m stretch. Avoid walking alone after 8 PM.',
            latitudeFuzzed: 28.57,
            longitudeFuzzed: 77.32,
            upvotes: 18,
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          CommunityReportItem(
            id: 'rep_2',
            category: 'ROAD_BLOCKAGE',
            title: 'Underpass waterlogging after heavy rain',
            description: 'Sector 15 underpass blocked, pedestrians directed towards main flyover.',
            latitudeFuzzed: 28.58,
            longitudeFuzzed: 77.31,
            upvotes: 9,
            createdAt: DateTime.now().subtract(const Duration(hours: 6)),
          ),
        ];
      }
    }
  }

  Future<void> addReport(String category, String title, String description) async {
    final tempItem = CommunityReportItem(
      id: 'rep_${DateTime.now().millisecondsSinceEpoch}',
      category: category,
      title: title,
      description: description,
      latitudeFuzzed: 28.58,
      longitudeFuzzed: 77.32,
      upvotes: 1,
      createdAt: DateTime.now(),
    );
    state = [tempItem, ...state];

    try {
      await apiClient.dio.post(
        ApiEndpoints.communityReports,
        data: {
          'category': category,
          'title': title,
          'description': description,
          'latitude_fuzzed': 28.58,
          'longitude_fuzzed': 77.32,
        },
      );
      await fetchReports();
    } catch (_) {}
  }
}

final communityProvider = StateNotifierProvider<CommunityNotifier, List<CommunityReportItem>>((ref) {
  final client = ref.watch(apiClientProvider);
  return CommunityNotifier(client);
});
