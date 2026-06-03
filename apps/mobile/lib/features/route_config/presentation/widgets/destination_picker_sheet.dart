import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/route_config.dart';

/// What a tap inside [DestinationPickerSheet] hands back to the parent.
///
/// The sheet never mutates state nor pushes routes itself — it pops one of
/// these intents and lets `route_details_page.dart` decide (the
/// `showModalBottomSheet returns intent` pattern; pushing a GoRouter route
/// from inside a modal sheet is a silent no-op on nested branch routes —
/// Flutter issue #155746). Tap-outside / system Back / "Concluído" resolve
/// the Future with `null` instead of a [DestinationChoice].
sealed class DestinationChoice {
  const DestinationChoice();
}

/// Card 1 ([RoundTrip]) or card 3 ([NoDestination]) was tapped — the parent
/// applies [destination] directly via `setDestination`.
final class DestinationChosen extends DestinationChoice {
  const DestinationChosen(this.destination);
  final Destination destination;
}

/// Card 2 ("Destino em outro endereço") was tapped — the parent pushes the
/// full-screen address search and builds a [SpecificAddress] from the picked
/// place. No [Destination] is known at tap time, so this variant carries none.
final class AddressSearchRequested extends DestinationChoice {
  const AddressSearchRequested();
}

/// Spoke's Destino sub-picker (ADR-0043): a fixed-height bottom sheet with a
/// header ("Destino" + a blue "Concluído" text button), a [Divider], and 3
/// tappable action cards (icon + bold title + lighter subtitle).
///
/// There is NO radio circle and NO selection checkmark — every card opens in
/// the same visual state. A card tap IS the confirm: it pops a
/// [DestinationChoice] and the parent applies it. "Concluído" / scrim / Back
/// pop `null` (close without change). Opened via
/// `showModalBottomSheet<DestinationChoice>`, mirroring the existing
/// `_showTimePicker` launcher.
class DestinationPickerSheet extends StatelessWidget {
  const DestinationPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Destino',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Semantics(
                  identifier: 'destination_done',
                  button: true,
                  child: TextButton(
                    // Close without change — pop null, NOT the current
                    // selection (Spoke: "Concluído" never mutates the row).
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Concluído',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 8),
            _DestinationCard(
              semanticsId: 'destination_card_round_trip',
              icon: LucideIcons.cornerUpLeft,
              title: 'Voltar ao ponto de partida',
              subtitle: 'Ida e volta (recomendado)',
              onTap: () => Navigator.pop<DestinationChoice>(
                context,
                const DestinationChosen(RoundTrip()),
              ),
            ),
            _DestinationCard(
              semanticsId: 'destination_card_specific_address',
              icon: LucideIcons.mapPin,
              title: 'Destino em outro endereço',
              subtitle: 'Digite qualquer endereço',
              onTap: () => Navigator.pop<DestinationChoice>(
                context,
                const AddressSearchRequested(),
              ),
            ),
            _DestinationCard(
              semanticsId: 'destination_card_no_destination',
              icon: LucideIcons.x,
              title: 'Não usar destino',
              subtitle: 'Não recomendado para transportadoras',
              onTap: () => Navigator.pop<DestinationChoice>(
                context,
                const DestinationChosen(NoDestination()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One tappable action card: leading icon + bold title + lighter subtitle.
/// No trailing control — Spoke shows no radio/checkmark on these cards.
class _DestinationCard extends StatelessWidget {
  const _DestinationCard({
    required this.semanticsId,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String semanticsId;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticsId,
      button: true,
      child: Card.outlined(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
          side: const BorderSide(color: AppColors.border),
        ),
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.card),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 22, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
