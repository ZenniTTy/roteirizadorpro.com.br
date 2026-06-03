import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';

/// Spoke-fidelity numpad time picker (ADR-0042).
///
/// Replicates Spoke's `bsp_time_picker` BottomSheetDialog: a live-text header
/// over a 4×3 grid of 12 keys (digits 1–9, `:00`, `0`, `:30`), a confirm FAB,
/// and a backspace button. State is local — a `String _buffer` of up to 4
/// digits — and ALWAYS starts empty when the sheet opens (ADR-0042 §Decision).
///
/// Callers open the sheet via [showModalBottomSheet]<[TimeOfDay]>; the FAB
/// pops the route with the parsed [TimeOfDay] result. Tap-outside / system
/// back resolves the Future with `null` (cancel semantics).
class TimePickerSheet extends StatefulWidget {
  const TimePickerSheet({super.key, required this.title});

  /// Placeholder text shown in the header while [_TimePickerSheetState._buffer]
  /// is empty. Caller decides PT-BR copy (e.g. "Definir horário de início" /
  /// "Definir horário de término"); this widget renders it verbatim.
  final String title;

  @override
  State<TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<TimePickerSheet> {
  /// Raw digit buffer, 0..4 chars long. Always digits; never a colon.
  String _buffer = '';

  bool get _isFull => _buffer.length >= 4;

  /// Header display: empty → title; 1 digit → "H"; 2 → "HH"; 3 → "H:MM";
  /// 4 → "HH:MM".
  String get _headerText {
    if (_buffer.isEmpty) return widget.title;
    return _formatBuffer(_buffer);
  }

  String _formatBuffer(String buf) {
    switch (buf.length) {
      case 1:
      case 2:
        return buf;
      case 3:
        return '${buf[0]}:${buf.substring(1)}';
      case 4:
        return '${buf.substring(0, 2)}:${buf.substring(2)}';
      default:
        return buf;
    }
  }

  /// Parse [buf] into `(hour, minute)` if it represents a complete time.
  ///
  /// Spoke surfaces two complete shapes: a 3-digit buffer (H:MM, hour `0..9`)
  /// produced by tapping a `:MM` shortcut on a 1-digit buffer, and a 4-digit
  /// buffer (HH:MM). Anything shorter is mid-typing.
  (int hour, int minute)? _parseTime(String buf) {
    final int? h;
    final int? m;
    if (buf.length == 3) {
      h = int.tryParse(buf.substring(0, 1));
      m = int.tryParse(buf.substring(1, 3));
    } else if (buf.length == 4) {
      h = int.tryParse(buf.substring(0, 2));
      m = int.tryParse(buf.substring(2, 4));
    } else {
      return null;
    }
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return (h, m);
  }

  bool _isValidFullTime(String buf) => _parseTime(buf) != null;

  /// Whether tapping the `:MM` shortcut for `mm` would yield a valid time
  /// given the current 1- or 2-digit buffer. With 1 digit we append literally
  /// (3-char H:MM); with 2 digits we append literally (4-char HH:MM).
  bool _shortcutEnabled(String mm) {
    if (_buffer.length != 1 && _buffer.length != 2) return false;
    return _isValidFullTime('$_buffer$mm');
  }

  void _onDigit(String d) {
    if (_isFull) return;
    setState(() => _buffer = '$_buffer$d');
  }

  void _onShortcut(String mm) {
    if (!_shortcutEnabled(mm)) return;
    setState(() => _buffer = '$_buffer$mm');
  }

  void _onBackspace() {
    if (_buffer.isEmpty) return;
    setState(() => _buffer = _buffer.substring(0, _buffer.length - 1));
  }

  void _onConfirm() {
    final parsed = _parseTime(_buffer);
    if (parsed == null) return;
    Navigator.pop<TimeOfDay>(
      context,
      TimeOfDay(hour: parsed.$1, minute: parsed.$2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _isValidFullTime(_buffer);
    final canBackspace = _buffer.isNotEmpty;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              identifier: 'time_picker_header',
              container: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  _headerText,
                  style: TextStyle(
                    fontSize: _buffer.isEmpty ? 18 : 32,
                    fontWeight: FontWeight.w600,
                    color:
                        _buffer.isEmpty ? AppColors.textMuted : AppColors.text,
                  ),
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2,
              children: [
                for (final d in const [
                  '1',
                  '2',
                  '3',
                  '4',
                  '5',
                  '6',
                  '7',
                  '8',
                  '9',
                ])
                  _Key(
                    semanticsId: 'time_picker_digit_$d',
                    label: d,
                    onTap: _isFull ? null : () => _onDigit(d),
                  ),
                _Key(
                  semanticsId: 'time_picker_shortcut_00',
                  label: ':00',
                  onTap:
                      _shortcutEnabled('00') ? () => _onShortcut('00') : null,
                ),
                _Key(
                  semanticsId: 'time_picker_digit_0',
                  label: '0',
                  onTap: _isFull ? null : () => _onDigit('0'),
                ),
                _Key(
                  semanticsId: 'time_picker_shortcut_30',
                  label: ':30',
                  onTap:
                      _shortcutEnabled('30') ? () => _onShortcut('30') : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(width: 56),
                Expanded(
                  child: Center(
                    child: Semantics(
                      identifier: 'time_picker_confirm',
                      button: true,
                      child: FloatingActionButton(
                        onPressed: canConfirm ? _onConfirm : null,
                        backgroundColor: AppColors.primary,
                        disabledElevation: 0,
                        child: const Icon(
                          LucideIcons.check,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 56,
                  child: Semantics(
                    identifier: 'time_picker_backspace',
                    button: true,
                    child: IconButton(
                      onPressed: canBackspace ? _onBackspace : null,
                      icon: const Icon(LucideIcons.delete),
                      color: AppColors.text,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One tappable cell in the 4×3 grid. Disabled state is encoded by a `null`
/// `onTap` — Material 3 dims the [InkWell] ripple automatically; we also fade
/// the label to [AppColors.textMuted] to mirror Spoke's disabled `:00`/`:30`.
class _Key extends StatelessWidget {
  const _Key({
    required this.semanticsId,
    required this.label,
    required this.onTap,
  });

  final String semanticsId;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      identifier: semanticsId,
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: enabled ? AppColors.text : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
