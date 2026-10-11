import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_container.dart';
import '../../domain/emergency_model.dart';

class DeliveryTrackerWidget extends StatelessWidget {
  final EmergencyIncident incident;

  const DeliveryTrackerWidget({
    super.key,
    required this.incident,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DELIVERY PIPELINE',
                style: TextStyle(
                  color: AppColors.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(incident.status).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  incident.status.displayTitle.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(incident.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStageItem(
            title: '1. Local Storage Secured',
            subtitle: 'Saved to encrypted on-device SQLite database',
            isComplete: true,
            isCurrent: incident.status == DeliveryStatus.localSaved,
          ),
          _buildStageItem(
            title: '2. Transport Dispatch',
            subtitle: incident.status == DeliveryStatus.relaying
                ? 'Relaying via Bluetooth Low Energy mesh'
                : 'Direct HTTPS network transmission',
            isComplete: incident.status.index >= DeliveryStatus.sending.index,
            isCurrent: incident.status == DeliveryStatus.sending || incident.status == DeliveryStatus.relaying,
          ),
          _buildStageItem(
            title: '3. Server Confirmed Reception',
            subtitle: incident.receiptId != null
                ? 'Receipt ID: ${incident.receiptId}'
                : 'Awaiting server cryptographic receipt',
            isComplete: incident.status.index >= DeliveryStatus.serverReceived.index,
            isCurrent: incident.status == DeliveryStatus.serverReceived,
          ),
          _buildStageItem(
            title: '4. Trusted Contacts Notified',
            subtitle: incident.contactsNotifiedCount > 0
                ? 'FCM high-priority alert pushed to ${incident.contactsNotifiedCount} contact(s)'
                : 'Push notification requested',
            isComplete: incident.status.index >= DeliveryStatus.contactNotificationRequested.index,
            isCurrent: incident.status == DeliveryStatus.contactNotificationRequested,
          ),
          _buildStageItem(
            title: '5. Contact Acknowledged',
            subtitle: incident.status.index >= DeliveryStatus.contactAcknowledged.index
                ? 'A contact confirmed opening the alert'
                : 'Awaiting contact confirmation',
            isComplete: incident.status.index >= DeliveryStatus.contactAcknowledged.index,
            isCurrent: incident.status == DeliveryStatus.contactAcknowledged,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStageItem({
    required String title,
    required String subtitle,
    required bool isComplete,
    required bool isCurrent,
    bool isLast = false,
  }) {
    final color = isComplete
        ? AppColors.successGreen
        : isCurrent
            ? AppColors.warningAmber
            : AppColors.mutedText;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isComplete ? AppColors.successGreen : Colors.transparent,
                border: Border.all(color: color, width: 2),
              ),
              child: isComplete
                  ? const Icon(Icons.check, size: 10, color: Colors.black)
                  : isCurrent
                      ? const Center(
                          child: SizedBox(
                            width: 6,
                            height: 6,
                            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.warningAmber),
                          ),
                        )
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isComplete ? AppColors.successGreen.withOpacity(0.4) : AppColors.glassBorder,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isComplete || isCurrent ? AppColors.primaryText : AppColors.mutedText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 11,
                  height: 1.3,
                ),
              ),
              if (!isLast) const SizedBox(height: 14),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(DeliveryStatus status) {
    switch (status) {
      case DeliveryStatus.resolved:
        return AppColors.successGreen;
      case DeliveryStatus.serverReceived:
      case DeliveryStatus.contactAcknowledged:
      case DeliveryStatus.helperAccepted:
      case DeliveryStatus.helperArrived:
        return AppColors.primaryBlue;
      case DeliveryStatus.cancelled:
        return AppColors.mutedText;
      case DeliveryStatus.failed:
      case DeliveryStatus.noRoute:
        return AppColors.emergencyRed;
      default:
        return AppColors.warningAmber;
    }
  }
}
