import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/route_config.dart';
import '../../domain/route_defaults.dart';
import '../../state/route_config_controller.dart';
import '../../state/route_defaults_controller.dart';
import '../widgets/destination_picker_sheet.dart';
import '../widgets/route_config_row.dart';
import '../widgets/route_details_section.dart';
import '../widgets/time_picker_sheet.dart';

/// Full-screen "Detalhes da rota" — Spoke white-label layout.
///
/// Per Spoke (live inspection 2026-06-01): there is NO AppBar — the close X
/// floats top-left inside the scrollable content, the title is a body-level
/// h1, "Concluído" is a full-width filled button pinned at the bottom, and
/// the single "Salvar como padrão" checkbox sits below it.
class RouteDetailsPage extends ConsumerStatefulWidget {
  const RouteDetailsPage({super.key, required this.routeId});

  final String routeId;

  @override
  ConsumerState<RouteDetailsPage> createState() => _RouteDetailsPageState();
}

class _RouteDetailsPageState extends ConsumerState<RouteDetailsPage> {
  /// Single global "Salvar como padrão" flag — Spoke uses one screen-level
  /// checkbox, NOT one per section. Default is UNCHECKED (per Spoke,
  /// live-confirmed 2026-06-10, ADR-0047).
  bool _saveAsDefault = false;

  /// Guards the one-shot seed so a rebuild never re-applies saved defaults
  /// over the user's in-screen edits.
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    // MS-A5.8 (ADR-0047): a returning user who saved route defaults sees them
    // pre-filled. Seed the config from the persisted envelope once, after the
    // first frame (the defaults read is async; mutating Riverpod state in
    // initState directly is unsafe). An empty envelope maps to
    // RouteConfig.empty() via toConfig(), so a fresh user is a no-op.
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedFromDefaults());
  }

  Future<void> _seedFromDefaults() async {
    // The `_seeded` precondition defends against a rebuild re-triggering the
    // seed (which would clobber the user's in-screen edits). It is committed
    // only AFTER a successful, applied read below — NOT here — so a transient
    // first-read failure does not permanently foreclose seeding for the page's
    // lifetime. (Seeding is triggered from exactly one post-frame callback in
    // initState; if a second trigger is ever added, this early guard + the
    // single registration still hold the re-entrancy line.)
    if (_seeded || !mounted) return;
    final RouteDefaults defaults;
    try {
      defaults = await ref.read(routeDefaultsControllerProvider.future);
    } catch (e) {
      // A defaults-read failure must never crash the screen — degrade to the
      // unseeded RouteConfig.empty() the page already shows (anti-pattern #11:
      // log, don't swallow silently). `_seeded` stays false so the failure is
      // not recorded as a completed seed. debugPrint is the codebase logging
      // primitive today; this site + the write catch below are the first
      // candidates to graduate to a real reporter when one lands on Flutter.
      debugPrint(
        '[route_details] seed from defaults failed for ${widget.routeId}, '
        'degrading to empty config: $e',
      );
      return;
    }
    if (!mounted || defaults == RouteDefaults.empty()) return;
    _seeded = true; // only after a successful, applied read
    ref
        .read(routeConfigControllerProvider(widget.routeId).notifier)
        .seed(defaults.toConfig());
  }

  /// "Concluído" handler (MS-A5.8, ADR-0047). When "Salvar como padrão" is
  /// checked, persist the current config into the `route_defaults_v1` envelope
  /// BEFORE popping; otherwise pop unchanged. `merge` preserves the persisted
  /// `firstRoute`/`schemaVersion` (the patch's ctor defaults don't clobber).
  ///
  /// Saving the default is BEST-EFFORT: a persistence failure must never trap
  /// the user on the screen or pop silently as if it succeeded. So the write is
  /// guarded, the failure surfaces a SnackBar (the loudest channel here) + a
  /// log, and the page ALWAYS pops afterwards — Concluído is never gated (Spoke
  /// parity). (silent-failure-hunter Finding 1.)
  Future<void> _onConcluido() async {
    if (_saveAsDefault) {
      final config = ref.read(routeConfigControllerProvider(widget.routeId));
      try {
        await ref
            .read(routeDefaultsControllerProvider.notifier)
            .merge(RouteDefaults.fromConfig(config));
      } catch (e) {
        debugPrint('[route_details] could not persist defaults: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível salvar como padrão. Sua rota foi mantida; '
                'tente novamente.',
              ),
            ),
          );
        }
      }
    }
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(routeConfigControllerProvider(widget.routeId));

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(onClose: () => context.pop()),
              const SizedBox(height: 8),
              _partidaSection(config),
              _destinoSection(config),
              _pausaSection(config),
              const SizedBox(height: 24),
              // Spoke parity (live capture 2026-06-03,
              // /tmp/spoke-a5-msfix/EVIDENCE.md §S2): "Concluído" is ALWAYS
              // enabled — Spoke renders it tappable even with neither time set,
              // so the common path (accept the "Iniciar agora mesmo" + "Ida e
              // volta" defaults) is one tap. Solver-window validation
              // (endTime > startTime, isRouteConfigValidProvider /
              // RouteConfig.isValid) stays in the DOMAIN for the Slice-3 solver
              // but must NOT gate this screen's affordance.
              _ConcluidoButton(onPressed: _onConcluido),
              const SizedBox(height: 8),
              _SalvarComoPadraoCheckbox(
                value: _saveAsDefault,
                onChanged: (v) => setState(() => _saveAsDefault = v),
              ),
            ],
          ),
        ),
      ),
    );
  }

  RouteDetailsSection _partidaSection(RouteConfig config) {
    final hasCustomLocation = config.startLocation != null &&
        !config.startLocation!.isUserCurrentLocation;
    final localLabel =
        hasCustomLocation ? config.startLocation!.address : 'Usar local atual';
    final startConfigured = config.timeStart != null;
    // Spoke parity: when not yet configured the row reads the placeholder
    // 'Iniciar agora mesmo' WITH a dimmer live wall-clock trailing it (live
    // capture 2026-06-03, /tmp/spoke-a5-msfix/EVIDENCE.md §S1: two siblings
    // 'Iniciar agora mesmo' + '23:36' tracking the system clock). Once a time
    // is confirmed, the row collapses to just 'HH:MM' (no prefix, no clock).
    // Verified live via ms4-live-detalhes-final.xml bounds [203,752][314,810]
    // showing the lone TextView 'text="10:30"'.
    final inicioLabel = startConfigured
        ? _formatTimeOfDay(config.timeStart!.time)
        : 'Iniciar agora mesmo';

    return RouteDetailsSection(
      title: 'Partida',
      children: [
        RouteConfigRow(
          semanticsKey: 'partida_local',
          label: localLabel,
          leading: LucideIcons.locateFixed,
          active: true,
          onTap: _onTapPartidaLocal,
        ),
        RouteConfigRow(
          semanticsKey: 'partida_inicio',
          label: inicioLabel,
          // Only the unconfigured state shows the live clock; once confirmed
          // the row is just the lone 'HH:MM' label (Spoke collapse, 23ff0ff).
          trailingValue: startConfigured ? null : const LiveClockLabel(),
          leading: LucideIcons.clock,
          active: true,
          onTap: _onTapPartidaInicio,
        ),
      ],
    );
  }

  /// Push the Partida sub-picker (`AddStopPage` in `PickerMode.startLocation`)
  /// and, on success, write the selected [StartLocation] back into
  /// `routeConfigControllerProvider`. The Future resolves to `null` when the
  /// user dismisses the picker (X close / back), per the Spoke contract.
  Future<void> _onTapPartidaLocal() async {
    final result = await context.push<StartLocation>(
      '/home/routes/active/${widget.routeId}/details/start-location',
    );
    if (result == null) return;
    ref
        .read(routeConfigControllerProvider(widget.routeId).notifier)
        .setStartLocation(result);
  }

  /// Open the Spoke-fidelity numpad picker (ADR-0042) for the Partida-Início
  /// row and, on confirm, write the resulting [TimeOfDay] back through
  /// `routeConfigController.setTimeStart`. Sheet returns `null` on
  /// tap-outside / system back — that's a cancel, leave state untouched.
  Future<void> _onTapPartidaInicio() async {
    // Spoke time-picker header copy (live capture 2026-06-03,
    // /tmp/spoke-a5-msfix/timepicker-inicio-header.png, rid bsp_input_time):
    // the start picker header reads "Definir primeiro horário", NOT
    // "...horário de início". The Destino ROW placeholder (line ~152) keeps
    // "Definir horário de término" — that's the row, verified separately.
    final picked = await _showTimePicker('Definir primeiro horário');
    if (picked == null) return;
    ref
        .read(routeConfigControllerProvider(widget.routeId).notifier)
        .setTimeStart(TimeStart(time: picked));
  }

  RouteDetailsSection _destinoSection(RouteConfig config) {
    // The Destino row is always rendered as "configured" (blue icon).
    // `RouteConfig.empty()` ships `destination: RoundTrip()` per Spoke parity,
    // so the row's primary text is "Ida e volta" out of the box. The null
    // branch in the `_destination*` helpers below is defense-in-depth for the
    // public `withDestination(null)` updater — it renders the same Spoke
    // default rather than blanking the row.
    return RouteDetailsSection(
      title: 'Destino',
      children: [
        RouteConfigRow(
          semanticsKey: 'destino',
          label: _destinationLabel(config.destination),
          subtitle: _destinationSubtitle(config.destination),
          leading: _destinationIcon(config.destination),
          active: true,
          onTap: _onTapDestino,
        ),
        RouteConfigRow(
          semanticsKey: 'destino_horario_termino',
          label: config.timeEnd == null
              ? 'Definir horário de término'
              : _formatTimeOfDay(config.timeEnd!.time),
          leading: LucideIcons.clock,
          active: config.timeEnd != null,
          onTap: _onTapDestinoHorarioTermino,
        ),
      ],
    );
  }

  /// Symmetric counterpart of [_onTapPartidaInicio] for the Destino-Término
  /// row — opens the same numpad sheet and writes [TimeEnd] on confirm.
  Future<void> _onTapDestinoHorarioTermino() async {
    // Spoke end picker header reads "Definir último horário" (live capture
    // 2026-06-03, /tmp/spoke-a5-msfix/timepicker-termino-header.png).
    final picked = await _showTimePicker('Definir último horário');
    if (picked == null) return;
    ref
        .read(routeConfigControllerProvider(widget.routeId).notifier)
        .setTimeEnd(TimeEnd(time: picked));
  }

  /// Open the Spoke Destino bottom sheet (ADR-0043) and act on the popped
  /// [DestinationChoice]:
  ///
  /// - `null` (Concluído / scrim / system Back) → no-op, selection unchanged.
  /// - [DestinationChosen] (card 1 or 3) → apply via `setDestination`.
  /// - [AddressSearchRequested] (card 2) → the sheet has already closed; push
  ///   the full-screen address search (`AddStopPage(mode: endLocation)`) and,
  ///   on a returned [SpecificAddress], apply it. Backing out returns to
  ///   Detalhes da rota (the sheet is NOT reshown) and leaves the selection
  ///   untouched (divergence #6).
  Future<void> _onTapDestino() async {
    final choice = await _showDestinationPicker();
    final notifier =
        ref.read(routeConfigControllerProvider(widget.routeId).notifier);

    switch (choice) {
      case null:
        return;
      case DestinationChosen(:final destination):
        notifier.setDestination(destination);
      case AddressSearchRequested():
        if (!mounted) return;
        final address = await context.push<SpecificAddress>(
          '/home/routes/active/${widget.routeId}/details/end-location',
        );
        if (address == null) return;
        notifier.setDestination(address);
    }
  }

  /// Launcher for the [DestinationPickerSheet] modal, mirroring
  /// [_showTimePicker]. Returns `null` on tap-outside / system Back.
  Future<DestinationChoice?> _showDestinationPicker() {
    return showModalBottomSheet<DestinationChoice>(
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
      builder: (_) => const DestinationPickerSheet(),
    );
  }

  /// Shared launcher for the [TimePickerSheet] modal so both time rows use
  /// identical config. Mirrors the [showModalBottomSheet] pattern used by
  /// `AppDrawer` (single precedent in this codebase for sheet-as-modal).
  /// Returns `null` on tap-outside / system back.
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

  RouteDetailsSection _pausaSection(RouteConfig config) {
    final rows = <Widget>[
      for (var i = 0; i < config.breaks.length; i++)
        RouteConfigRow(
          semanticsKey: 'pausa_$i',
          // Spoke's two-line row (D4 dump, GAP-3): bold "Pausa de N min" title +
          // muted "Entre A e B" subtitle (route_setup_break_option_title/_subtitle),
          // NOT a single concatenated string. Tappable → reopens in edit mode
          // (Spoke's BreakSetupArgs.EditBreak).
          label: 'Pausa de ${config.breaks[i].durationMinutes} min',
          subtitle:
              'Entre ${_formatTimeOfDay(config.breaks[i].fromTime)} e ${_formatTimeOfDay(config.breaks[i].toTime)}',
          leading: LucideIcons.coffee,
          active: true,
          onTap: () => _onTapEditarPausa(i, config.breaks[i]),
        ),
      RouteConfigRow(
        semanticsKey: 'adicionar_pausa',
        label: 'Adicionar pausa',
        leading: LucideIcons.coffee,
        active: false,
        onTap: _onTapAdicionarPausa,
      ),
    ];

    return RouteDetailsSection(title: 'Pausa', children: rows);
  }

  /// Push the "Configure a pausa" page in ADD mode (no `initialBreak`). On a
  /// returned [BreakSaved], append via `addBreak`; `null`/[BreakRemoved] are
  /// no-ops here (remove is unreachable in add mode). ADR-0044 + ADR-0049.
  Future<void> _onTapAdicionarPausa() async {
    final result = await context.push<BreakSchedulerResult>(
      '/home/routes/active/${widget.routeId}/details/break-scheduler',
    );
    if (result is! BreakSaved) return;
    ref
        .read(routeConfigControllerProvider(widget.routeId).notifier)
        .addBreak(result.config);
  }

  /// Push the "Configure a pausa" page in EDIT mode (ADR-0049), pre-filled with
  /// the break at [index] (passed as GoRouter `extra`). On [BreakSaved] replace
  /// it via `updateBreak`; on [BreakRemoved] drop it via `removeBreak`; `null`
  /// (cancel) leaves the list untouched. Mirrors Spoke's EditBreak flow.
  Future<void> _onTapEditarPausa(int index, BreakConfig current) async {
    final result = await context.push<BreakSchedulerResult>(
      '/home/routes/active/${widget.routeId}/details/break-scheduler',
      extra: current,
    );
    if (!mounted) return;
    final notifier =
        ref.read(routeConfigControllerProvider(widget.routeId).notifier);
    switch (result) {
      case null:
        return;
      case BreakSaved(:final config):
        notifier.updateBreak(index, config);
      case BreakRemoved():
        notifier.removeBreak(index);
    }
  }

  /// Maps a [Destination] subtype to its primary row display string.
  ///
  /// `RouteConfig.empty()` ships `destination: RoundTrip()`, so the default
  /// Destino label is "Ida e volta" via the [RoundTrip] arm. The `null` arm
  /// is defensive: [RouteConfig.withDestination] accepts `null` to clear, so
  /// the UI keeps rendering the Spoke default in that edge case rather than
  /// blanking the row. [NoDestination] renders "Nenhum destino" — Spoke's
  /// row copy after "Não usar destino" is chosen (the row copy differs from
  /// the sheet card copy per ADR-0043 §Decision 3).
  String _destinationLabel(Destination? destination) {
    return switch (destination) {
      null || RoundTrip() => 'Ida e volta',
      SpecificAddress(:final address) => address,
      NoDestination() => 'Nenhum destino',
    };
  }

  /// Spoke shows a small subtitle under "Ida e volta" explaining the mode.
  /// Other destination variants have no subtitle — including [NoDestination],
  /// which Spoke renders as a single-line row (divergence #3).
  String? _destinationSubtitle(Destination? destination) {
    return switch (destination) {
      null || RoundTrip() => 'Viagem de ida e volta a partir do local atual',
      SpecificAddress() => null,
      NoDestination() => null,
    };
  }

  /// Row icon per [Destination]. Note the asymmetry the sheet card has with
  /// the row: the sheet card for "Não usar destino" uses [LucideIcons.x], but
  /// the resulting row uses [LucideIcons.flag] (two surfaces, same state —
  /// ADR-0043 §Decision 3 divergence #2). RoundTrip's row icon is
  /// [LucideIcons.cornerUpLeft], identical to its sheet card (divergence #4),
  /// NOT `repeat`.
  IconData _destinationIcon(Destination? destination) {
    return switch (destination) {
      null || RoundTrip() => LucideIcons.cornerUpLeft,
      SpecificAddress() => LucideIcons.mapPin,
      NoDestination() => LucideIcons.flag,
    };
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          identifier: 'route_details_close',
          button: true,
          child: IconButton(
            icon: const Icon(LucideIcons.x, color: AppColors.text),
            tooltip: 'Fechar',
            onPressed: onClose,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(height: 8),
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'Detalhes da rota',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConcluidoButton extends StatelessWidget {
  const _ConcluidoButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'route_details_confirm',
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
          // Always enabled per Spoke (see call site comment). The button
          // never gates on time-validity at the UI layer.
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

class _SalvarComoPadraoCheckbox extends StatelessWidget {
  const _SalvarComoPadraoCheckbox({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'route_details_salvar_como_padrao',
      child: CheckboxListTile(
        value: value,
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
        activeColor: AppColors.primary,
        title: const Text(
          'Salvar como padrão',
          style: TextStyle(fontSize: 14, color: AppColors.text),
        ),
      ),
    );
  }
}
