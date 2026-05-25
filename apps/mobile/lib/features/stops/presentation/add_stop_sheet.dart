import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:roteirizador_pro/core/services/id.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/stops/domain/stop.dart';
import 'package:roteirizador_pro/features/stops/state/stops_controller.dart';

/// Result returned by [AddStopSheet] when it closes. The wrapper
/// ([AddStopPage]) inspects this value to decide what to do next —
/// navigate to a downstream capture page (voice/camera) or just clean up.
///
/// Returning a value (rather than calling `context.push` from inside the
/// sheet) avoids Flutter issue #155746: showModalBottomSheet's local
/// Navigator inside a StatefulShellRoute branch causes nested-route push
/// from inside the modal to fail silently. The parent route owns the
/// real navigation context, so it does the push after the sheet resolves.
enum AddStopResult {
  /// User submitted a manual address; [StopsController.add] was called.
  /// Wrapper should fire `onSaved` (or default-pop).
  saved,

  /// User chose the voice-capture shortcut. Wrapper should push
  /// `/home/stops/voice`.
  voice,

  /// User chose the camera/OCR-capture shortcut. Wrapper should push
  /// `/home/stops/ocr`.
  camera,
}

/// Bottom-sheet UI for adding a stop. Mirrors
/// `prototipo/screens-a.jsx ScreenAddStop` (lines 279-364) — drag handle,
/// title, search input, three method-shortcut buttons (Teclado / Voz / Câmera),
/// and a "Adicionar parada" CTA.
///
/// Voice and Câmera tap fires a 200 ms visual-feedback delay then closes the
/// sheet (returning [AddStopResult.voice] or [AddStopResult.camera]). The
/// hosting wrapper does the actual route push. Keyboard is the inline
/// default — the user types directly and submits via the CTA, which
/// closes the sheet with [AddStopResult.saved] after invoking
/// [StopsController.add].
///
/// The [onSaved] callback is preserved for direct-pump test paths that
/// host this sheet outside [AddStopPage]. The production wrapper path
/// passes `onSaved: null` and uses the returned [AddStopResult] instead.
class AddStopSheet extends ConsumerStatefulWidget {
  const AddStopSheet({super.key, this.onSaved});

  final void Function(BuildContext context)? onSaved;

  @override
  ConsumerState<AddStopSheet> createState() => _AddStopSheetState();
}

class _AddStopSheetState extends ConsumerState<AddStopSheet> {
  late final TextEditingController _textController;
  late final FocusNode _inputFocus;
  String _selectedMethod = 'keyboard';
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _inputFocus = FocusNode();
    _inputFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    // Risk-1 mitigation: cancel any pending nav timer so Navigator.pop
    // never runs against a defunct context after the sheet is dismissed
    // (swipe-down, barrier tap, programmatic pop).
    _navTimer?.cancel();
    _inputFocus.removeListener(_onFocusChange);
    _inputFocus.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    // Force rebuild so the input focus-ring + background swap update
    // (mirrors prototype Input :focus state in ui.jsx:122-145).
    if (mounted) setState(() {});
  }

  void _selectMethod(String method) {
    setState(() => _selectedMethod = method);
  }

  void _onMethodTap(String method) {
    _selectMethod(method);
    if (method == 'keyboard') return;

    // Capture the Navigator BEFORE the timer fires. After the sheet
    // pops, this widget's context is defunct.
    final navigator = Navigator.of(context);
    final result =
        method == 'voice' ? AddStopResult.voice : AddStopResult.camera;
    _navTimer?.cancel();
    _navTimer = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      // Pop the sheet with the intent. The wrapper awaits this future
      // and pushes the matching capture route based on the result.
      // This pattern avoids Flutter issue #155746 (nested-branch push
      // from inside a modal hosted by StatefulShellRoute fails silently).
      navigator.pop(result);
    });
  }

  Future<void> _onAddStop() async {
    final label = _textController.text.trim();
    if (label.isEmpty) return;

    // Capture navigator before the async gap that may invalidate context.
    final navigator = Navigator.of(context);
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

    navigator.pop(AddStopResult.saved);
    if (!mounted) return;
    // onSaved is retained for direct-pump test paths. Production wrapper
    // (AddStopPage) passes onSaved: null and observes AddStopResult.saved
    // from the popped future instead.
    widget.onSaved?.call(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    // Outer Container carries the sheetTop shadow (mirrors prototype
    // tokens.js:27 `sheetShadow`). Material handles the clipping for the
    // rounded top corners.
    return Container(
      decoration: const BoxDecoration(
        boxShadow: AppShadows.sheetTop,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 12, 24, 24 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _DragHandle(),
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
              _SearchInput(
                controller: _textController,
                focusNode: _inputFocus,
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
              _PrimaryCta(
                label: 'Adicionar parada',
                onPressed: _onAddStop,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Drag handle pill at the top of the sheet. Static — extracted to a
/// `const` widget so [_AddStopSheetState.setState] rebuilds skip it.
class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        key: const Key('drag-handle'),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Search input mirroring `prototipo/ui.jsx Input` lines 122-145:
/// unfocused = `RP.surface` background, transparent border; focused =
/// white background, `RP.primary` 1.5px border, `AppShadows.inputFocus`
/// ring.
class _SearchInput extends StatelessWidget {
  const _SearchInput({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;
    return Container(
      decoration: BoxDecoration(
        boxShadow: isFocused ? AppShadows.inputFocus : const [],
        borderRadius: BorderRadius.circular(AppRadii.input),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search,
            size: 20,
            color: AppColors.textMuted,
          ),
          hintText: 'Digite o endereço ou CEP...',
          filled: true,
          fillColor: isFocused ? Colors.white : AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.input),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.input),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.input),
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Primary CTA button mirroring `prototipo/ui.jsx PrimaryButton`
/// lines 68-97: height 52, radius `AppRadii.btn` (24), background
/// `AppColors.primary`, `AppShadows.primaryButton` glow, white text 16/w600.
/// Private to this file (Karpathy §3 — no premature shared widget; promote
/// when a second consumer appears).
class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: AppShadows.primaryButton,
          borderRadius: BorderRadius.circular(AppRadii.btn),
        ),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.btn),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            elevation: 0,
          ),
          child: Text(label),
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
