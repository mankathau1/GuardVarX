import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/glass_container.dart';
import '../providers/contacts_provider.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController(text: 'Family');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.primarySurface,
        title: const Text('Add Trusted Contact', style: TextStyle(color: AppColors.primaryText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: InputDecoration(
                labelText: 'Contact Name',
                labelStyle: const TextStyle(color: AppColors.secondaryText),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: InputDecoration(
                labelText: 'Mobile Phone (+91)',
                labelStyle: const TextStyle(color: AppColors.secondaryText),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: relationController,
              style: const TextStyle(color: AppColors.primaryText),
              decoration: InputDecoration(
                labelText: 'Relationship (e.g. Sister, Friend)',
                labelStyle: const TextStyle(color: AppColors.secondaryText),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
            onPressed: () {
              if (nameController.text.trim().isNotEmpty && phoneController.text.trim().isNotEmpty) {
                ref.read(contactsProvider.notifier).addContact(
                      nameController.text.trim(),
                      phoneController.text.trim(),
                      relationController.text.trim(),
                    );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trusted Contacts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: AppColors.primaryBlue),
            onPressed: _showAddContactDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          children: [
            const Text(
              'Your Circle of Trust',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'These contacts will receive immediate high-priority push notifications and offline SMS whenever an emergency or missed check-in occurs.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),

            if (contacts.isEmpty) ...[
              GlassContainer(
                padding: const EdgeInsets.all(32),
                child: const Center(
                  child: Text(
                    'No trusted contacts configured yet.\nTap "+" above to add your family or close friends.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
                  ),
                ),
              ),
            ] else ...[
              ...contacts.map((c) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 18,
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primaryBlue.withOpacity(0.2),
                          child: Text(
                            c.name.isNotEmpty ? c.name[0] : '?',
                            style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    c.name,
                                    style: const TextStyle(
                                      color: AppColors.primaryText,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.elevatedGlassSurface,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      c.relationship,
                                      style: const TextStyle(color: AppColors.secondaryText, fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.phone,
                                style: const TextStyle(color: AppColors.secondaryText, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, size: 12, color: AppColors.successGreen),
                                  const SizedBox(width: 4),
                                  const Text('Consent Active', style: TextStyle(color: AppColors.successGreen, fontSize: 11)),
                                  const SizedBox(width: 12),
                                  Icon(Icons.notifications_active, size: 12, color: AppColors.primaryBlue.withOpacity(0.8)),
                                  const SizedBox(width: 4),
                                  const Text('SOS Enabled', style: TextStyle(color: AppColors.primaryBlue, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.mutedText, size: 20),
                          onPressed: () => ref.read(contactsProvider.notifier).removeContact(c.id),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
