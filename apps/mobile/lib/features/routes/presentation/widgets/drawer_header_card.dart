import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/user_view_model.dart';

/// Header zone of the routes sheet — avatar + name + email + optional
/// "Assinar" CTA. Help and Settings icons live in the sheet's top bar
/// (in [AppDrawer]), not here.
///
/// Spoke parity §10.1 amendment 2026-05-27.
class DrawerHeaderCard extends StatelessWidget {
  const DrawerHeaderCard({
    super.key,
    required this.user,
    required this.onHelp,
    required this.onSettings,
    required this.onSubscribe,
  });

  final UserViewModel user;
  // Kept for source compatibility while the sheet shell evolves. These
  // currently route to no-op shims because Help/Settings now render in
  // the sheet top bar.
  final VoidCallback onHelp;
  final VoidCallback onSettings;
  final VoidCallback onSubscribe;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primaryLight,
                child: Icon(
                  LucideIcons.user,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (user.planLine != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.planLine!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (!user.hasActiveSubscription) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onSubscribe,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.btn),
                ),
              ),
              child: const Text(
                'Assinar',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
