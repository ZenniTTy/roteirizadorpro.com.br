import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/route_config.dart';
import '../widgets/time_picker_sheet.dart';

/// Full-screen "Configure a pausa" — Spoke white-label (ADR-0044).
///
/// Per the live Spoke capture (M54, 2026-06-09,
/// `/tmp/spoke-a56-pausa-inspection/EVIDENCE.md`): a routed page (back arrow,
/// NOT a sheet), with a title + subtitle, a time WINDOW ("Quando deseja fazer
/// a pausa?" → "Entre" / "E" fields, default 08:00–15:00), a duration field
/// ("Qual será a duração da pausa?" → "Padrão (30 min)", a free integer of
/// minutes), and a pinned full-width "Adicionar pausa" CTA.
///
/// Returns-intent (ADR-0049): the page pops a [BreakSchedulerResult] —
/// [BreakSaved] on confirm, [BreakRemoved] when the user removes an existing
/// break; system Back / the `←` pops `null` (cancel). The parent
/// (`RouteDetailsPage`) routes the result to `addBreak` / `updateBreak` /
/// `removeBreak`. Mirrors Spoke's `BreakSetupArgs` (Add/Edit) +
/// `BreakSetupResult` (Changed/Removed).
///
/// [initialBreak] selects the mode: `null` → ADD (fields start at the Spoke
/// defaults, no remove button); non-null → EDIT (fields pre-filled from it, a
/// "Remover pausa" button appears). The primary CTA reads "Concluído" in BOTH
/// modes — Spoke's `BreakSetupState.primaryButtonText` defaults to
/// `R.string.done` (the `break_screen_add_break_button` string exists but is
/// NOT this CTA). Confirmed in the static dump (D4, 2026-06-10).
///
/// The two time fields reuse the shipped numpad [TimePickerSheet] (ADR-0042) —
/// the same widget Spoke's `bsp_time_picker` renders for these fields, with the
/// header copy "Definir primeiro horário" / "Definir último horário" matching
/// the live capture. The duration uses a numeric-input dialog, exactly as
/// Spoke's "Duração da pausa (minutos)" AlertDialog does.
class BreakSchedulerPage extends StatefulWidget {
  const BreakSchedulerPage({super.key, this.initialBreak});

  /// When non-null, the page opens in EDIT mode pre-filled with this break and
  /// shows the "Remover pausa" action. When null, it opens in ADD mode.
  final BreakConfig? initialBreak;

  /// Spoke's verbatim window defaults (live capture).
  static const TimeOfDay defaultFrom = TimeOfDay(hour: 8, minute: 0);
  static const TimeOfDay defaultTo = TimeOfDay(hour: 15, minute: 0);

  /// Spoke's verbatim duration default ("Padrão (30 min)").
  static const int defaultDurationMinutes = 30;

  @override
  State<BreakSchedulerPage> createState() => _BreakSchedulerPageState();
}

class _BreakSchedulerPageState extends State<BreakSchedulerPage> {
  late TimeOfDay _fromTime =
      widget.initialBreak?.fromTime ?? BreakSchedulerPage.defaultFrom;
  late TimeOfDay _toTime =
      widget.initialBreak?.toTime ?? BreakSchedulerPage.defaultTo;
  late int _durationMinutes = widget.initialBreak?.durationMinutes ??
      BreakSchedulerPage.defaultDurationMinutes;

  bool get _isEdit => widget.initialBreak != null;

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// While the duration is still the Spoke default (30), the field reads
  /// "Padrão (30 min)"; any other value reads the bare "N min". Derived from
  /// the value itself (not a separate touched-flag) so re-confirming 30
  /// without changing it keeps the "Padrão" framing — the prefix denotes the
  /// default VALUE, per ADR-0044.
  String get _durationLabel =>
      _durationMinutes == BreakSchedulerPage.defaultDurationMinutes
          ? 'Padrão ($_durationMinutes min)'
          : '$_durationMinutes min';

  Future<void> _onTapFrom() async {
    final picked = await _showTimePicker('Definir primeiro horário');
    if (picked == null) return;
    setState(() => _fromTime = picked);
  }

  Future<void> _onTapTo() async {
    final picked = await _showTimePicker('Definir último horário');
    if (picked == null) return;
    setState(() => _toTime = picked);
  }

  /// Shared launcher for the reused numpad [TimePickerSheet]. Mirrors the
  /// identical launcher in `route_details_page.dart`. Returns `null` on
  /// tap-outside / system back.
  Future<TimeOfDay?> _showTimePicker(String title) {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      useRootNavigator: true,
      backgroundColor: AppColors.bg,
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.sheet),
        ),
      ),
      builder: (_) => TimePickerSheet(title: title),
    );
  }

  /// Open the Spoke "Duração da pausa (minutos)" numeric dialog. Pops `null`
  /// on Cancelar / scrim; on Definir, applies the typed minutes. Minutes ≤ 0
  /// are rejected (a zero/negative break is meaningless) — the only validity
  /// gate, mirroring the solver-window rule, not a Spoke-invisible disable.
  Future<void> _onTapDuration() async {
    final picked = await showDialog<int>(
      context: context,
      useRootNavigator: true,
      builder: (_) => _DurationInputDialog(initialMinutes: _durationMinutes),
    );
    if (picked == null) return;
    setState(() => _durationMinutes = picked);
  }

  /// Confirm ("Concluído") — pops [BreakSaved] with the current window/duration.
  /// The parent appends (add mode) or replaces at index (edit mode).
  void _onConfirm() {
    Navigator.of(context).pop<BreakSchedulerResult>(
      BreakSaved(
        BreakConfig(
          fromTime: _fromTime,
          toTime: _toTime,
          durationMinutes: _durationMinutes,
        ),
      ),
    );
  }

  /// "Remover pausa" (edit mode only) — confirms via Spoke's
  /// `remove_break_confirmation_dialog` ("Quer remover a pausa…?"), then pops
  /// [BreakRemoved] so the parent drops the break at its index. Cancel keeps
  /// the user on the editor with no change.
  Future<void> _onRemove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (_) => const _RemoveBreakDialog(),
    );
    if (confirmed != true || !mounted) return;
    Navigator.of(context).pop<BreakSchedulerResult>(const BreakRemoved());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BackButton(onTap: () => Navigator.of(context).pop()),
                    const SizedBox(height: 8),
                    const Text(
                      'Configure a pausa',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Planeje suas pausas para ter estimativas mais precisas '
                      'de paradas e duração da rota.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Quando deseja fazer a pausa?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _WindowRow(
                      fromLabel: _formatTime(_fromTime),
                      toLabel: _formatTime(_toTime),
                      onTapFrom: _onTapFrom,
                      onTapTo: _onTapTo,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Qual será a duração da pausa?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _DurationField(
                      label: _durationLabel,
                      onTap: _onTapDuration,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ConfirmButton(onPressed: _onConfirm),
                  // Edit mode only: Spoke's "Remover pausa" destructive action
                  // (BreakSetupState.hasRemoveButton). Absent in add mode.
                  if (_isEdit) ...[
                    const SizedBox(height: 8),
                    _RemoveBreakButton(onPressed: _onRemove),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top-left back arrow (Spoke's `←`, a11y "Voltar"). Pops `null` (cancel).
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'break_scheduler_back',
      button: true,
      child: IconButton(
        icon: const Icon(LucideIcons.arrowLeft, color: AppColors.text),
        tooltip: 'Voltar',
        onPressed: onTap,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

/// The "Entre [from]   E   [to]" time-window pair. A leading clock icon, then
/// two tappable bordered fields with a "—" separator (Spoke layout).
class _WindowRow extends StatelessWidget {
  const _WindowRow({
    required this.fromLabel,
    required this.toLabel,
    required this.onTapFrom,
    required this.onTapTo,
  });

  final String fromLabel;
  final String toLabel;
  final VoidCallback onTapFrom;
  final VoidCallback onTapTo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(LucideIcons.clock, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: _TimeField(
            semanticsId: 'break_from_time',
            label: 'Entre',
            value: fromLabel,
            onTap: onTapFrom,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('—', style: TextStyle(color: AppColors.textMuted)),
        ),
        Expanded(
          child: _TimeField(
            semanticsId: 'break_to_time',
            label: 'E',
            value: toLabel,
            onTap: onTapTo,
          ),
        ),
      ],
    );
  }
}

/// One bordered, tappable time field with a small floating label (Spoke's
/// OutlinedTextField look). The value is the `HH:MM` string.
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.semanticsId,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String semanticsId;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticsId,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.input),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadii.input),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width tappable duration field with a leading stopwatch icon and a
/// floating "Duração da pausa" label (Spoke layout).
class _DurationField extends StatelessWidget {
  const _DurationField({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(LucideIcons.timer, color: AppColors.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Semantics(
            identifier: 'break_duration',
            button: true,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(AppRadii.input),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadii.input),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Duração da pausa',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Pinned full-width primary CTA. Reads "Concluído" in BOTH add and edit modes
/// — Spoke's `BreakSetupState.primaryButtonText` defaults to `R.string.done`
/// (D4 dump finding, 2026-06-10). The semantics id stays `break_scheduler_confirm`
/// (the integration_test + widget tests target it).
class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'break_scheduler_confirm',
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.btn),
            ),
          ),
          onPressed: onPressed,
          child: const Text(
            'Concluído',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// Edit-mode destructive "Remover pausa" action (Spoke's
/// `break_screen_remove_button`). Red text button below the primary CTA.
class _RemoveBreakButton extends StatelessWidget {
  const _RemoveBreakButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'break_scheduler_remove',
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text(
            'Remover pausa',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// Spoke's `remove_break_confirmation_dialog` — "Quer mesmo remover esta
/// pausa?" with Cancelar / Remover. Pops `true` on confirm, `null`/`false`
/// otherwise. (Original PT-BR microcopy per ADR-0035 — Spoke's verbatim
/// "Quer remover a pausa de %1$s da sua rota?" is paraphrased, not cloned.)
class _RemoveBreakDialog extends StatelessWidget {
  const _RemoveBreakDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bg,
      title: const Text('Remover pausa'),
      content: const Text('Quer mesmo remover esta pausa da sua rota?'),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: Semantics(
                identifier: 'break_remove_confirm',
                button: true,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Remover'),
                ),
              ),
            ),
            Semantics(
              identifier: 'break_remove_cancel',
              button: true,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Spoke's "Duração da pausa (minutos)" numeric-input AlertDialog: a numeric
/// TextField pre-filled with the current value, a "Definir" confirm, and a
/// "Cancelar" dismiss. Pops the parsed minutes on Definir (only when > 0),
/// `null` on Cancelar / scrim.
class _DurationInputDialog extends StatefulWidget {
  const _DurationInputDialog({required this.initialMinutes});
  final int initialMinutes;

  @override
  State<_DurationInputDialog> createState() => _DurationInputDialogState();
}

class _DurationInputDialogState extends State<_DurationInputDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialMinutes.toString(),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Parsed minutes if the field holds a positive integer, else null.
  int? get _parsed {
    final n = int.tryParse(_controller.text.trim());
    if (n == null || n <= 0) return null;
    return n;
  }

  void _onConfirm() {
    final n = _parsed;
    if (n == null) return;
    Navigator.of(context).pop<int>(n);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bg,
      title: const Text('Duração da pausa (minutos)'),
      content: Semantics(
        identifier: 'break_duration_input',
        child: TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _onConfirm(),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: Semantics(
                identifier: 'break_duration_confirm',
                button: true,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _parsed == null ? null : _onConfirm,
                  child: const Text('Definir'),
                ),
              ),
            ),
            Semantics(
              identifier: 'break_duration_cancel',
              button: true,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
