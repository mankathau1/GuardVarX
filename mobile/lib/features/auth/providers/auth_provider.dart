import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';

class UserProfile {
  final String id;
  final String displayName;
  final String phone;
  final String email;
  final String role;
  final bool isAuthenticated;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.phone,
    required this.email,
    required this.role,
    required this.isAuthenticated,
  });

  factory UserProfile.unauthenticated() {
    return UserProfile(
      id: '',
      displayName: '',
      phone: '',
      email: '',
      role: 'STANDARD_USER',
      isAuthenticated: false,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'User',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'STANDARD_USER',
      isAuthenticated: true,
    );
  }
}

class AuthNotifier extends StateNotifier<UserProfile> {
  final ApiClient apiClient;

  AuthNotifier(this.apiClient) : super(UserProfile.unauthenticated());

  Future<void> signInWithPhone(String phone, String otp) async {
    // In production, verifies Firebase phone OTP and sets ID token
    final mockToken = 'mock_${phone.replaceAll('+', '')}_STANDARD_USER';
    apiClient.setAuthToken(mockToken);

    try {
      final response = await apiClient.dio.get(ApiEndpoints.me);
      state = UserProfile.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      state = UserProfile(
        id: 'usr_local',
        displayName: 'Priya Sharma',
        phone: phone,
        email: 'priya@example.com',
        role: 'STANDARD_USER',
        isAuthenticated: true,
      );
    }
  }

  Future<void> signInWithGoogle() async {
    final mockToken = 'mock_google_user_STANDARD_USER';
    apiClient.setAuthToken(mockToken);

    try {
      final response = await apiClient.dio.get(ApiEndpoints.me);
      state = UserProfile.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      state = UserProfile(
        id: 'usr_google_1',
        displayName: 'Verified User',
        phone: '+919876543210',
        email: 'user@guardvarx.org',
        role: 'STANDARD_USER',
        isAuthenticated: true,
      );
    }
  }

  void signOut() {
    apiClient.setAuthToken(null);
    state = UserProfile.unauthenticated();
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authProvider = StateNotifierProvider<AuthNotifier, UserProfile>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthNotifier(client);
});
