import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';

class ContactItem {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final bool isConfirmed;
  final bool canReceiveSOS;
  final bool canViewSafeWalk;

  ContactItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isConfirmed = false,
    this.canReceiveSOS = true,
    this.canViewSafeWalk = true,
  });

  factory ContactItem.fromJson(Map<String, dynamic> json) {
    return ContactItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relationship: json['relationship'] as String? ?? '',
      isConfirmed: json['is_confirmed'] as bool? ?? false,
      canReceiveSOS: json['can_receive_sos'] as bool? ?? true,
      canViewSafeWalk: json['can_view_safe_walk'] as bool? ?? true,
    );
  }
}

class ContactsNotifier extends StateNotifier<List<ContactItem>> {
  final ApiClient apiClient;

  ContactsNotifier(this.apiClient) : super([]) {
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    try {
      final res = await apiClient.dio.get(ApiEndpoints.trustedContacts);
      final list = (res.data as List).map((i) => ContactItem.fromJson(i as Map<String, dynamic>)).toList();
      state = list;
    } catch (_) {
      // Default initial mock contacts for preview if offline
      if (state.isEmpty) {
        state = [
          ContactItem(
            id: 'tc_1',
            name: 'Aarav Sharma',
            phone: '+91 98123 45678',
            relationship: 'Brother',
            isConfirmed: true,
          ),
          ContactItem(
            id: 'tc_2',
            name: 'Pooja Verma',
            phone: '+91 98765 43210',
            relationship: 'Friend',
            isConfirmed: true,
          ),
        ];
      }
    }
  }

  Future<void> addContact(String name, String phone, String relationship) async {
    final tempItem = ContactItem(
      id: 'tc_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      relationship: relationship,
    );
    state = [...state, tempItem];

    try {
      await apiClient.dio.post(
        ApiEndpoints.trustedContacts,
        data: {
          'name': name,
          'phone': phone,
          'relationship': relationship,
        },
      );
      await fetchContacts();
    } catch (_) {}
  }

  Future<void> removeContact(String id) async {
    state = state.where((c) => c.id != id).toList();
    try {
      await apiClient.dio.delete('${ApiEndpoints.trustedContacts}/$id');
    } catch (_) {}
  }
}

final contactsProvider = StateNotifierProvider<ContactsNotifier, List<ContactItem>>((ref) {
  final client = ref.watch(apiClientProvider);
  return ContactsNotifier(client);
});
