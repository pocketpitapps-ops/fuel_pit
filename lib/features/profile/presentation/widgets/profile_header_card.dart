// lib/features/profile/presentation/widgets/profile_header_card.dart
import 'package:flutter/material.dart';
import '../../domain/user_profile.dart';
import '../../../../shared/widgets/app_card.dart';

class ProfileHeaderCard extends StatelessWidget {
  final UserProfile profile;
  final VoidCallback? onTap; // novo

  const ProfileHeaderCard({super.key, required this.profile, this.onTap});

  String _displayName() {
    final username = profile.username?.trim();
    if (username != null && username.isNotEmpty) return username;

    final fullName = profile.fullName?.trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;

    return 'Motorista Fuel Pit';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final name = _displayName();
    final email = profile.email?.trim();
    final country = profile.country?.trim();
    final mobile = profile.mobileNumber?.trim();

    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: colorScheme.primaryContainer,
                child: Text(
                  name[0].toUpperCase(),
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (email != null && email.isNotEmpty)
                      Text(
                        email,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    if (country != null && country.isNotEmpty)
                      Text(
                        country,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                    if (mobile != null && mobile.isNotEmpty)
                      Text(
                        mobile,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
