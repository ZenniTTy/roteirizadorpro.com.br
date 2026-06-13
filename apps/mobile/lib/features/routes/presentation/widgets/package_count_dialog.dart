import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';

/// Dialog numérico free-text (F8).
///
/// Contrato:
/// - TextField com filtro só-dígitos, máximo 4 caracteres.
/// - hintText '1' (placeholder) quando campo vazio.
/// - Pré-preenchido com o valor atual se [current] > 1; vazio (só hint) se
///   [current] == 1.
/// - Commit-on-dismiss: qualquer dismiss (barrier, back, onSubmitted) aplica o
///   texto digitado. SEM botão OK/Concluído.
/// - Valor retornado: int digitado clampado em 1..9999; campo vazio → 1.
class PackageCountDialog {
  const PackageCountDialog._();

  /// Exibe o dialog e retorna o valor escolhido (nunca null).
  static Future<int> show(
    BuildContext context, {
    required int current,
  }) async {
    final result = await showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (_) => _PackageCountDialogBody(current: current),
    );
    // O body sempre popa com valor (PopScope intercepta barrier/back);
    // o fallback cobre apenas remoção programática da rota.
    return result ?? (current < 1 ? 1 : current);
  }
}

class _PackageCountDialogBody extends StatefulWidget {
  const _PackageCountDialogBody({required this.current});

  final int current;

  @override
  State<_PackageCountDialogBody> createState() =>
      _PackageCountDialogBodyState();
}

class _PackageCountDialogBodyState extends State<_PackageCountDialogBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.current > 1 ? '${widget.current}' : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static int _parse(String text) {
    final n = int.tryParse(text) ?? 1;
    return n.clamp(1, 9999);
  }

  @override
  Widget build(BuildContext context) {
    // canPop:false + onPopInvokedWithResult: barrier-tap e back chegam como
    // maybePop (didPop=false) e viram pop-com-valor — é o commit-on-dismiss
    // do F8. O pop do onSubmitted é direto (Navigator.pop não consulta o
    // PopScope).
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.of(context).pop(_parse(_controller.text));
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
                'Pacotes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  hintText: '1',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                style: const TextStyle(fontSize: 16, color: AppColors.text),
                onSubmitted: (text) => Navigator.of(context).pop(_parse(text)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
