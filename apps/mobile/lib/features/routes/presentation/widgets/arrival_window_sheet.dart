import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../route_config/presentation/widgets/time_picker_sheet.dart';

/// Tipo de retorno da janela de horário de chegada (F7/D8).
///
/// Pop com record = commit; barrier dismiss → null = cancel.
typedef ArrivalWindow = ({TimeOfDay? start, TimeOfDay? end});

/// Sheet da janela de chegada (F7/D8/H1/H13/H19).
///
/// Comportamento:
/// - Header: [TextButton 'Limpar' | título 'Horário de chegada' |
///   TextButton 'Concluído'] — idiom ColorPickerSheet/AccessInstructionsSheet.
/// - Rows verbatim do dump: 'Chegar entre' e 'E' (time_window_start_title /
///   time_window_end_title). Row sem valor exibe 'Qualquer momento' (anytime);
///   com valor exibe HH:MM em formato 24h com zero-pad.
/// - Tap em row abre o numpad [TimePickerSheet] (ADR-0042, segundo modal).
/// - 'Concluído' popa (start: ..., end: ...) com o estado local — um lado só
///   é válido (H1: NÃO copiar a validação ambos-obrigatórios da
///   BreakSchedulerPage).
/// - 'Limpar' popa (start: null, end: null).
/// - Barrier dismiss → Future resolve null (cancel).
class ArrivalWindowSheet extends StatefulWidget {
  const ArrivalWindowSheet({
    super.key,
    this.initialStart,
    this.initialEnd,
  });

  final TimeOfDay? initialStart;
  final TimeOfDay? initialEnd;

  /// Abre a sheet via [showModalBottomSheet]<[ArrivalWindow]>.
  ///
  /// useRootNavigator: true (H13), useSafeArea: true, isScrollControlled:
  /// true. Pop com record = commit; barrier dismiss → null = cancel.
  static Future<ArrivalWindow?> show(
    BuildContext context, {
    TimeOfDay? initialStart,
    TimeOfDay? initialEnd,
  }) {
    return showModalBottomSheet<ArrivalWindow>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ArrivalWindowSheet(
        initialStart: initialStart,
        initialEnd: initialEnd,
      ),
    );
  }

  @override
  State<ArrivalWindowSheet> createState() => _ArrivalWindowSheetState();
}

class _ArrivalWindowSheetState extends State<ArrivalWindowSheet> {
  TimeOfDay? _start;
  TimeOfDay? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialStart;
    _end = widget.initialEnd;
  }

  /// 24h com zero-pad — NÃO usa TimeOfDay.format (locale/12h dependente).
  static String _fmt(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  /// Abre o numpad reusado (ADR-0042) como segundo modal e grava o resultado
  /// no estado local — o commit só acontece no 'Concluído'.
  Future<void> _pick({required bool isStart}) async {
    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: AppColors.bg,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => TimePickerSheet(
        title: isStart ? 'Definir primeiro horário' : 'Definir último horário',
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
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
                onPressed: () => Navigator.of(context)
                    .pop<ArrivalWindow>((start: null, end: null)),
                child: const Text(
                  'Limpar',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ),
              const Flexible(
                child: Text(
                  'Horário de chegada',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context)
                    .pop<ArrivalWindow>((start: _start, end: _end)),
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
          const SizedBox(height: 8),
          _WindowRow(
            semanticsId: 'edit_stop_window_start',
            title: 'Chegar entre',
            value: _start == null ? 'Qualquer momento' : _fmt(_start!),
            onTap: () => _pick(isStart: true),
          ),
          const Divider(height: 1, color: AppColors.border),
          _WindowRow(
            semanticsId: 'edit_stop_window_end',
            title: 'E',
            value: _end == null ? 'Qualquer momento' : _fmt(_end!),
            onTap: () => _pick(isStart: false),
          ),
        ],
      ),
    );
  }
}

/// Row da janela: título à esquerda, valor à direita ('Qualquer momento'
/// quando o lado está vazio). Tap abre o numpad.
class _WindowRow extends StatelessWidget {
  const _WindowRow({
    required this.semanticsId,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final String semanticsId;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticsId,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, color: AppColors.text),
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
