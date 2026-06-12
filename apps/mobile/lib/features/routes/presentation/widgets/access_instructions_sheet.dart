import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Resultado da sheet de instruções de acesso (F13).
/// Dismiss da barrier → null
/// (o `Future<AccessInstructionsResult?>` resolve null).
sealed class AccessInstructionsResult {
  const AccessInstructionsResult();
}

/// Salvar: texto confirmado pelo usuário + flag se deve gravar como padrão
/// sticky do endereço.
class AccessInstructionsSaved extends AccessInstructionsResult {
  const AccessInstructionsSaved(this.text, {required this.saveAsDefault});

  final String text;
  final bool saveAsDefault;
}

/// Limpar: apaga as instruções do stop; se [clearDefault] = true, apaga também
/// o padrão sticky do endereço (switch estava ON quando o usuário tocou Limpar).
class AccessInstructionsCleared extends AccessInstructionsResult {
  const AccessInstructionsCleared({required this.clearDefault});

  final bool clearDefault;
}

/// Bottom sheet de instruções de acesso (F13 / §13.C.3 / H18 / H13).
///
/// Padrão Á6: commit-on-dismiss, `useRootNavigator: true`, `useSafeArea: true`
/// (idiom ColorPickerSheet / H13). O header tem [TextButton 'Limpar' | título
/// 'Instruções de acesso' | TextButton 'Salvar']. O corpo é um TextField
/// multiline autofocado + um Switch "Salvar como padrão para este endereço".
///
/// Pré-preenchimento (H18): o chamador resolve a precedência stop > sticky antes
/// de invocar [show] e passa o texto via [initialText].
class AccessInstructionsSheet extends StatefulWidget {
  const AccessInstructionsSheet({super.key, this.initialText});

  final String? initialText;

  /// Abre via showModalBottomSheet(useRootNavigator: true, useSafeArea: true)
  /// — H13. Retorna null em caso de dismiss pela barrier.
  static Future<AccessInstructionsResult?> show(
    BuildContext context, {
    String? initialText,
  }) {
    return showModalBottomSheet<AccessInstructionsResult>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        // Sobe a sheet junto com o teclado (TextField autofocado).
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: AccessInstructionsSheet(initialText: initialText),
      ),
    );
  }

  @override
  State<AccessInstructionsSheet> createState() =>
      _AccessInstructionsSheetState();
}

class _AccessInstructionsSheetState extends State<AccessInstructionsSheet> {
  late final TextEditingController _controller;
  bool _saveAsDefault = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                onPressed: () => Navigator.of(context).pop(
                  AccessInstructionsCleared(clearDefault: _saveAsDefault),
                ),
                child: const Text(
                  'Limpar',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ),
              const Flexible(
                child: Text(
                  'Instruções de acesso',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(
                  AccessInstructionsSaved(
                    _controller.text.trim(),
                    saveAsDefault: _saveAsDefault,
                  ),
                ),
                child: const Text(
                  'Salvar',
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
          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: null,
            minLines: 2,
            decoration: InputDecoration(
              hintText: 'Adicionar instruções',
              hintStyle: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            style: const TextStyle(fontSize: 14, color: AppColors.text),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Salvar como padrão para este endereço',
                  style: TextStyle(fontSize: 14, color: AppColors.text),
                ),
              ),
              Switch(
                value: _saveAsDefault,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _saveAsDefault = v),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
