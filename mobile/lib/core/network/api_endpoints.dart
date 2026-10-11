class ApiEndpoints {
  static const String baseUrl = 'http://10.0.2.2:8080'; // Android emulator localhost

  static const String health = '/health';
  static const String ready = '/ready';

  static const String me = '/api/v1/me';
  static const String devices = '/api/v1/devices';
  static const String trustedContacts = '/api/v1/trusted-contacts';

  static const String emergencies = '/api/v1/emergencies';
  static String emergencyDetails(String id) => '/api/v1/emergencies/$id';
  static String emergencyCancel(String id) => '/api/v1/emergencies/$id/cancel';
  static String emergencyResolve(String id) => '/api/v1/emergencies/$id/resolve';
  static String emergencyAcks(String id) => '/api/v1/emergencies/$id/acknowledgements';

  static const String safeWalks = '/api/v1/safe-walks';
  static const String safeWalkActive = '/api/v1/safe-walks/active';
  static String safeWalkCheckin(String id) => '/api/v1/safe-walks/$id/checkin';
  static String safeWalkComplete(String id) => '/api/v1/safe-walks/$id/complete';

  static const String responderAvailability = '/api/v1/responders/availability';
  static const String missions = '/api/v1/missions';

  static const String communityReports = '/api/v1/community/reports';
}
