import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';

/// Opção retornada por [showReoptimizeOptionsSheet].
///
/// - [update]: mantém a rota e reposiciona só as paradas novas.
/// - [reoptimize]: refaz a sequência inteira em busca da melhor ordem.
enum ReoptimizeChoice { update, reoptimize }

/// Abre o bottom sheet "Como recalcular" (T8 — Á7 PR-B).
///
/// Título: "Como recalcular"
/// Itens:
///   - "Ajustar o que mudou" / "Mantém a rota e reposiciona só as paradas novas"
///     → [ReoptimizeChoice.update]
///   - "Recalcular do zero" / "Refaz a sequência inteira em busca da melhor ordem"
///     → [ReoptimizeChoice.reoptimize]
///
/// **Microcopy ORIGINAL (ADR-0010)** — reformulada do `optimization_explainer_*`
/// do Spoke (baseline pt-rBR: "Compare as opções" / "Reotimizar" / "Recalcula a
/// rota do zero..." / "Reordenar apenas as paradas alteradas"). Confirmado
/// 1:1 contra `values-pt-rBR/strings.xml`: nenhuma string aqui é verbatim.
///
/// Dismiss da barrier → null.
Future<ReoptimizeChoice?> showReoptimizeOptionsSheet(BuildContext context) {
  return showModalBottomSheet<ReoptimizeChoice>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    backgroundColor: AppColors.bg,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Como recalcular',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
          ListTile(
            leading:
                const Icon(LucideIcons.refreshCw, color: AppColors.primary),
            title: const Text(
              'Ajustar o que mudou',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            subtitle: const Text(
              'Mantém a rota e reposiciona só as paradas novas',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            onTap: () =>
                Navigator.of(sheetContext).pop(ReoptimizeChoice.update),
          ),
          ListTile(
            leading: const Icon(LucideIcons.sparkles, color: AppColors.primary),
            title: const Text(
              'Recalcular do zero',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            subtitle: const Text(
              'Refaz a sequência inteira em busca da melhor ordem',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            onTap: () =>
                Navigator.of(sheetContext).pop(ReoptimizeChoice.reoptimize),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
