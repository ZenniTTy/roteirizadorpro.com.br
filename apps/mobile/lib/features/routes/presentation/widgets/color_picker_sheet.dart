import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/stop_color.dart';

/// Resultado do picker: distingue 'escolheu cor' de 'limpou' (dismiss = null).
sealed class ColorPickerResult {
  const ColorPickerResult();
}

class ColorPicked extends ColorPickerResult {
  const ColorPicked(this.color);
  final StopColor color;
}

class ColorCleared extends ColorPickerResult {
  const ColorCleared();
}

/// Token visual de cada StopColor — identidade própria (ADR-0035): o
/// prototipo não define cores de parada, então usamos a mesma família
/// tailwind-500 dos tokens existentes (success #22C55E = green-500,
/// error #EF4444 = red-500, warning #F59E0B = amber-500).
Color stopColorToken(StopColor c) => switch (c) {
      StopColor.blue => const Color(0xFF3B82F6), // blue-500
      StopColor.teal => const Color(0xFF14B8A6), // teal-500
      StopColor.purple => const Color(0xFFA855F7), // purple-500
      StopColor.pink => const Color(0xFFEC4899), // pink-500
      StopColor.orange => const Color(0xFFF97316), // orange-500
    };

/// Bottom sheet de cor da parada (F10 — exatamente 5 cores), padrão Á6:
/// commit-on-dismiss puro, `useRootNavigator: true` (H13), seleção local
/// até o "Concluído".
class ColorPickerSheet extends StatefulWidget {
  const ColorPickerSheet({super.key, this.current});
  final StopColor? current;

  /// Abre via showModalBottomSheet(useRootNavigator: true, useSafeArea: true) — H13.
  static Future<ColorPickerResult?> show(
    BuildContext context, {
    StopColor? current,
  }) {
    return showModalBottomSheet<ColorPickerResult>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ColorPickerSheet(current: current),
    );
  }

  @override
  State<ColorPickerSheet> createState() => _ColorPickerSheetState();
}

class _ColorPickerSheetState extends State<ColorPickerSheet> {
  StopColor? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(const ColorCleared()),
                child: const Text(
                  'Limpar',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ),
              const Text(
                'Cor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(
                  _selected == null
                      ? const ColorCleared()
                      : ColorPicked(_selected!),
                ),
                child: const Text(
                  'Concluído',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final color in StopColor.values)
                Semantics(
                  identifier: 'edit_stop_color_${color.name}',
                  button: true,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _selected = color),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stopColorToken(color),
                      ),
                      child: _selected == color
                          ? const Icon(
                              LucideIcons.check,
                              key: Key('color_swatch_check'),
                              color: Colors.white,
                              size: 22,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
