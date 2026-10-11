enum EmergencyType {
  personalThreat('Personal safety threat', 'Immediate threat or stalking'),
  medical('Medical emergency', 'Critical health or trauma condition'),
  roadAccident('Road accident', 'Vehicle collision or crash'),
  fire('Fire breakout', 'Building or vehicle fire hazard'),
  missingPerson('Missing person', 'Lost child, elderly, or family member'),
  naturalDisaster('Natural disaster', 'Flood, earthquake, building collapse'),
  vehicleBreakdown('Vehicle breakdown', 'Stranded in unsafe location'),
  other('Other emergency', 'Urgent distress requiring response');

  final String label;
  final String description;
  const EmergencyType(this.label, this.description);
}

enum DeliveryStatus {
  created('Created', 'Alert initialized on device'),
  localSaved('Locally Saved', 'Secured in offline SQLite storage'),
  queued('Queued', 'Awaiting network or mesh transmission'),
  sending('Sending', 'Transmitting to GuardVarX server'),
  relaying('Relaying', 'Broadcasting over peer BLE mesh'),
  serverReceived('Server Received', 'Go Backend confirmed reception'),
  contactNotificationRequested('Notifying Contacts', 'FCM alert dispatched to trusted contacts'),
  contactAcknowledged('Contact Acknowledged', 'Trusted contact opened and confirmed alert'),
  helperAccepted('Helper Accepted', 'Nearby verified helper responded'),
  helperEnRoute('Helper En Route', 'Helper traveling to location'),
  helperArrived('Helper Arrived', 'Helper reached proximity'),
  resolved('Resolved', 'Emergency safely resolved'),
  cancelled('Cancelled', 'Alert cancelled by user'),
  failed('Failed', 'Transmission failed, retrying'),
  noRoute('No Route', 'Mesh exhausted; fallback guidance active');

  final String displayTitle;
  final String description;
  const DeliveryStatus(this.displayTitle, this.description);
}

class EmergencyIncident {
  final String incidentId;
  final EmergencyType emergencyType;
  final String? message;
  final double latitude;
  final double longitude;
  final double accuracyMeters;
  final DateTime locationTimestamp;
  final DeliveryStatus status;
  final String? receiptId;
  final int contactsNotifiedCount;

  EmergencyIncident({
    required this.incidentId,
    required this.emergencyType,
    this.message,
    required this.latitude,
    required this.longitude,
    required this.accuracyMeters,
    required this.locationTimestamp,
    required this.status,
    this.receiptId,
    this.contactsNotifiedCount = 0,
  });

  EmergencyIncident copyWith({
    DeliveryStatus? status,
    String? receiptId,
    int? contactsNotifiedCount,
  }) {
    return EmergencyIncident(
      incidentId: incidentId,
      emergencyType: emergencyType,
      message: message,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: accuracyMeters,
      locationTimestamp: locationTimestamp,
      status: status ?? this.status,
      receiptId: receiptId ?? this.receiptId,
      contactsNotifiedCount: contactsNotifiedCount ?? this.contactsNotifiedCount,
    );
  }
}
