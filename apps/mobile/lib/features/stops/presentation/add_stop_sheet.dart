import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:roteirizador_pro/core/services/id.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

/// Bottom-sheet UI for adding a stop. Mirrors
/// `prototipo/screens-a.jsx ScreenAddStop` (lines 279-364) — drag handle,
/// title, search input, three method-shortcut buttons (Teclado / Voz / Câmera),
/// and a "Adicionar parada" CTA.
///
/// Voice and Câmera tap fires a 200 ms visual-feedback delay then closes the
/// sheet and navigates to the matching capture route. Keyboard is the inline
/// default — the user types directly and submits via the CTA.
class AddStopSheet extends ConsumerStatefulWidget {
  const AddStopSheet({super.key, this.onSaved});

  final void Function(BuildContext context)? onSaved;

  @override
  ConsumerState<AddStopSheet> createState() => _AddStopSheetState();
}

class _AddStopSheetState extends ConsumerState<AddStopSheet> {
  late final TextEditingController _textController;
  String _selectedMethod = 'keyboard';
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    // Risk-1 mitigation: cancel any pending nav timer so Navigator.pop /
    // context.push never run against a defunct context after the sheet
    // is dismissed (swipe-down, barrier tap, programmatic pop).
    _navTimer?.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _selectMethod(String method) {
    setState(() => _selectedMethod = method);
  }

  void _onMethodTap(String method) {
    _selectMethod(method);
    if (method == 'keyboard') return;

    _navTimer?.cancel();
    _navTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      final route = method == 'voice' ? '/stops/add/voice' : '/stops/add/ocr';
      // maybePop closes the sheet in production (overlay) and is a no-op
      // in widget tests that mount the sheet directly under the router.
      Navigator.of(context).maybePop();
      context.push(route);
    });
  }

  Future<void> _onAddStop() async {
    final label = _textController.text.trim();
    if (label.isEmpty) return;

    final stop = Stop(
      id: newId(),
      lat: 0,
      lng: 0,
      label: label,
      source: StopSource.manual,
      createdAt: DateTime.now(),
    );
    await ref.read(stopsControllerProvider.notifier).add(stop);
    if (!mounted) return;

    await Navigator.of(context).maybePop();
    if (!mounted) return;
    widget.onSaved?.call(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                key: const Key('drag-handle'),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Adicionar parada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                hintText: 'Digite o endereço ou CEP...',
              ),
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _MethodButton(
                    label: 'Teclado',
                    icon: Icons.keyboard,
                    isSelected: _selectedMethod == 'keyboard',
                    onTap: () => _onMethodTap('keyboard'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MethodButton(
                    label: 'Voz',
                    icon: Icons.mic,
                    isSelected: _selectedMethod == 'voice',
                    onTap: () => _onMethodTap('voice'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _MethodButton(
                    label: 'Câmera',
                    icon: Icons.camera_alt,
                    isSelected: _selectedMethod == 'camera',
                    onTap: () => _onMethodTap('camera'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _onAddStop,
                child: const Text('Adicionar parada'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single method-shortcut button used by [AddStopSheet]. Private to this
/// file — promote to `shared/` only if a second consumer appears
/// (Karpathy §3, no premature shared widgets).
class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = isSelected ? AppColors.primary : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          key: Key(
            'method-btn-${_keySegment(label)}-${isSelected ? "selected" : "unselected"}',
          ),
          height: 56,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: foreground),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Maps the localized label to the ASCII Key segment the tests assert on
  /// (`Key('method-btn-voice-selected')` etc).
  static String _keySegment(String label) {
    switch (label) {
      case 'Teclado':
        return 'keyboard';
      case 'Voz':
        return 'voice';
      case 'Câmera':
        return 'camera';
      default:
        return label.toLowerCase();
    }
  }
}
