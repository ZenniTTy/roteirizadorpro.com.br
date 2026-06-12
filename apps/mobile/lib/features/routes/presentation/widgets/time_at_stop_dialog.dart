import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

/// Dialog de edição do tempo na parada (F9/H14 — MS-A6 T16).
///
/// - Título: 'Tempo na parada'
/// - Dois TextFields: 'Minutos' e 'Segundos' (strings do dump v3.65.1:
///   minutes_selection_title / seconds_selection_title).
/// - Filtro só-dígitos + max 5 chars em ambos os campos.
/// - Hints = componentes de [defaultDuration] (H14: o fallback canônico vive
///   em Settings.fallbackStopDuration; o caller resolve e passa pronto).
/// - Pré-preenchimento: [current] != null → componentes min/seg; null →
///   ambos vazios (herda o default global).
/// - Commit-on-dismiss via PopScope canPop:false (mesmo padrão do
///   PackageCountDialog — barrier + back popam com valor).
/// - Ambos vazios ou total zero → resolve `(duration: null)` (herda default).
/// - SEM botão OK/Concluído.
class TimeAtStopDialog {
  TimeAtStopDialog._();

  /// Exibe o dialog. O record retornado é o novo override a aplicar
  /// (`duration: null` = herdar o default global). Null externo só acontece
  /// em remoção programática da rota.
  static Future<({Duration? duration})?> show(
    BuildContext context, {
    required Duration? current,
    required Duration defaultDuration,
  }) {
    return showDialog<({Duration? duration})>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _TimeAtStopDialogBody(
        current: current,
        defaultDuration: defaultDuration,
      ),
    );
  }
}

class _TimeAtStopDialogBody extends StatefulWidget {
  const _TimeAtStopDialogBody({
    required this.current,
    required this.defaultDuration,
  });

  final Duration? current;
  final Duration defaultDuration;

  @override
  State<_TimeAtStopDialogBody> createState() => _TimeAtStopDialogBodyState();
}

class _TimeAtStopDialogBodyState extends State<_TimeAtStopDialogBody> {
  late final TextEditingController _minutes;
  late final TextEditingController _seconds;

  @override
  void initState() {
    super.initState();
    final current = widget.current;
    _minutes = TextEditingController(
      text: current == null ? '' : '${current.inMinutes}',
    );
    _seconds = TextEditingController(
      text: current == null ? '' : '${current.inSeconds % 60}',
    );
  }

  @override
  void dispose() {
    _minutes.dispose();
    _seconds.dispose();
    super.dispose();
  }

  ({Duration? duration}) _parse() {
    final m = int.tryParse(_minutes.text) ?? 0;
    final s = int.tryParse(_seconds.text) ?? 0;
    final total = Duration(minutes: m, seconds: s);
    // Vazios ou total zero → herda o default global (F9).
    return (duration: total == Duration.zero ? null : total);
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(5),
            ],
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            style: const TextStyle(fontSize: 16, color: AppColors.text),
            onSubmitted: (_) => Navigator.of(context).pop(_parse()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // canPop:false + onPopInvokedWithResult: barrier-tap e back viram
    // pop-com-valor — commit-on-dismiss (F9, idiom PackageCountDialog).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_parse());
      },
      child: Dialog(
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tempo na parada',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(
                    label: 'Minutos',
                    controller: _minutes,
                    hint: '${widget.defaultDuration.inMinutes}',
                  ),
                  const SizedBox(width: 12),
                  _field(
                    label: 'Segundos',
                    controller: _seconds,
                    hint: '${widget.defaultDuration.inSeconds % 60}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
