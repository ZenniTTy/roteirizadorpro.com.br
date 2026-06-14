import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../route_config/domain/route_config.dart';
import '../../route_config/presentation/widgets/route_config_row.dart';
import '../../route_config/state/route_config_controller.dart';
import '../data/location_service.dart';
import '../domain/optimization/route_optimizer.dart';
import '../domain/optimize_direction.dart';
import '../domain/optimize_type.dart';
import '../domain/stop.dart';
import '../state/active_route_provider.dart';
import '../state/active_route_state_provider.dart';
import '../state/current_route_stops_provider.dart';
import '../state/map_controls_controller.dart';
import '../state/optimization_controller.dart';
import '../state/optimization_ftue_repository.dart';
import '../state/routes_provider.dart';
import 'widgets/app_drawer.dart';
import 'widgets/id_education_dialog.dart';
import 'widgets/not_enough_stops_dialog.dart';
import 'widgets/optimization_error_dialog.dart';
import 'widgets/optimize_cta.dart';
import 'widgets/pre_confirm_view.dart';
import 'widgets/refine_route_sheet.dart';

/// Shell that hosts the active route's map + sheet.
///
/// Layout per Spoke v3.65.1 live dump 2026-05-27 (bounds reference 1080×2400):
///   - Map full-screen behind everything
///   - Floating circular hamburger top-left abre [AppDrawer]
///   - 2 floating circular map controls direita (layer toggle + recenter)
///     stub visual; wiring real em Área 3
///   - Sheet collapsed no rodapé com search pill estilo input clicável
///     contendo OCR + Voice + kebab como suffix icons
class RouteShellPage extends ConsumerStatefulWidget {
  const RouteShellPage({super.key});

  @override
  ConsumerState<RouteShellPage> createState() => _RouteShellPageState();
}

class _RouteShellPageState extends ConsumerState<RouteShellPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  // Altura do sheet em fração da tela (0..1). Inicializa com collapsed
  // após o primeiro build pra incluir o bottom inset do device.
  double _sheetFraction = 0.18;
  double? _dragStartFraction;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(-23.550520, -46.633308),
    zoom: 13.0,
  );

  // Frações canônicas dos 3 snaps (calculadas dinamicamente em build):
  late double _collapsedFraction;
  static const double _mediumFraction = 0.40;
  static const double _expandedFraction = 0.90;

  // One-shot do auto-expand (H6): quando a rota ativa ganha a 1ª parada (ou o
  // shell monta com ≥1), o sheet snapa pra expanded UMA vez. Colapso manual
  // posterior não é revertido.
  bool _hasAutoExpanded = false;

  @override
  void initState() {
    super.initState();
    // Cobertura do caso "shell monta com rota ativa que JÁ tem stops" (H6-i):
    // o ref.listen do build só vê transições, não o estado inicial.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasAutoExpanded) return;
      if (ref.read(currentRouteStopsProvider).isNotEmpty) {
        _hasAutoExpanded = true;
        setState(() => _sheetFraction = _expandedFraction);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Transição 0→≥1 na contagem de stops da rota ativa → auto-expand
    // one-shot (H6-ii). `_hasAutoExpanded` impede re-disparo (H6-iii).
    ref.listen<int>(
      currentRouteStopsProvider.select((stops) => stops.length),
      (previous, next) {
        if (next >= 1 && !_hasAutoExpanded) {
          _hasAutoExpanded = true;
          setState(() => _sheetFraction = _expandedFraction);
        }
      },
    );

    final mq = MediaQuery.of(context);

    // ADR-0046: the active-route sheet surfaces a "Configuração de rota"
    // summary (2 rows: Início + Ida-e-volta) that opens the full Detalhes da
    // rota page. It exists only when a route is active — when
    // `activeRouteIdProvider` is null the shell shows the placeholder with no
    // config section (`active_route_provider.dart` contract).
    //
    // Only `activeRouteIdProvider` is watched here (rarely changes, keepAlive).
    // The per-field RouteConfig watches live INSIDE `_ConfigSummarySection`
    // (a ConsumerWidget) via `.select`, so a break/time mutation on the
    // Detalhes page rebuilds the two summary rows — not the whole shell shell
    // (map + drag geometry).
    final activeRouteId = ref.watch(activeRouteIdProvider);
    final Widget? configSummary = activeRouteId == null
        ? null
        : _ConfigSummarySection(
            routeId: activeRouteId,
            onOpenDetails: () => context.push(
              '/home/routes/active/$activeRouteId/details',
            ),
          );

    // Lista de stops da rota ativa (MS-A6 T7). O displayName observa só a
    // rota ativa via select — mutações em outras rotas não rebuildam o shell.
    final stops = ref.watch(currentRouteStopsProvider);
    final routeDisplayName = activeRouteId == null
        ? null
        : ref.watch(
            routesProvider.select(
              (routes) => routes
                  .where((r) => r.id == activeRouteId)
                  .firstOrNull
                  ?.displayName(),
            ),
          );

    // Estado da rota ativa → escolhe o corpo do sheet (Á7 PR-B1). DRAFT mostra o
    // `_ActiveRouteSheet`; PRE-CONFIRM (otimizado, não confirmado) mostra o
    // `PreConfirmView` no MESMO shell — o mapa em cima permanece (o
    // polyline+markers numerados são o PR-B2). Espelha o Spoke, onde o
    // EditRouteFragment renderiza por estado, sem tela separada.
    final activeRouteState = ref.watch(activeRouteStateProvider);
    final isPreConfirm = activeRouteState?.isPreConfirm ?? false;
    final activeMetrics = activeRouteId == null
        ? null
        : ref.watch(
            routesProvider.select((routes) {
              final r = routes.where((x) => x.id == activeRouteId).firstOrNull;
              return r == null
                  ? null
                  : (
                      duration: r.totalDurationMinutes ?? 0,
                      distance: r.totalDistanceMeters ?? 0.0,
                    );
            }),
          );

    // Map layer preference (normal <-> satellite). While it loads we render the
    // Spoke default (normal) so the map never flickers a wrong layer.
    final mapType = ref.watch(
          mapControlsControllerProvider.select((s) => s.value?.mapType),
        ) ??
        MapType.normal;

    // Collapsed = handle (24) + pill row height (48 + 16 vertical padding) +
    // bottom system nav inset + a small breathing pad. Não inclui os
    // big buttons — eles só aparecem quando o sheet sobe pra medium+.
    final collapsedPx = 24.0 + 16.0 + 48.0 + 16.0 + mq.padding.bottom;
    _collapsedFraction = (collapsedPx / mq.size.height).clamp(0.10, 0.30);

    final clampedFraction =
        _sheetFraction.clamp(_collapsedFraction, _expandedFraction);

    return Scaffold(
      // ARQUITETURA descoberta via Maestro do Spoke 2026-05-28:
      // - O mapa do Spoke NÃO é full-screen — ele OCUPA SÓ A FATIA DA TELA
      //   acima do sheet. Quando o sheet expande, o mapa encolhe (vide
      //   `[0,0][1080,2058]` → `[0,0][1080,1245]` no dump pós-swipe).
      // - Isso elimina a sobreposição mapa-sheet, evitando que o
      //   EagerGestureRecognizer do GoogleMap (PlatformView) intercepte
      //   gestos verticais que deveriam ser do sheet (flutter#105994).
      //
      // Implementação em Flutter: Column { Expanded(map), SizedBox(sheet) }.
      // Conforme `_sheetFraction` cresce via drag handle, o SizedBox
      // toma mais espaço e o Expanded encolhe automaticamente.
      //
      // O DraggableScrollableSheet do Flutter NÃO funciona dentro de um
      // SizedBox (depende de altura unconstrained pra calcular *ChildSize).
      // Por isso usamos um sheet MANUAL: AnimatedContainer + GestureDetector
      // no handle, snap states discretos.
      body: Column(
        children: [
          Expanded(
            // RepaintBoundary isolates the map + static floating chrome from
            // the per-frame setState the sheet drag fires (onHandleDragUpdate),
            // so the floating buttons aren't recomposited on every drag frame.
            child: RepaintBoundary(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: GoogleMap(
                      mapType: mapType,
                      initialCameraPosition: _initialPosition,
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                      // Render the blue GPS dot; our own button replaces the
                      // native recenter FAB (which we keep disabled).
                      myLocationEnabled: true,
                      // A user-initiated pan drops follow mode (Spoke's exit to
                      // `MapControllerMode.Manual`). Our recenter animation also
                      // fires this callback; the controller's pending-move
                      // counter (set in `_onRecenter`) consumes our own moves so
                      // only a real user pan drops follow — order-independent of
                      // when `animateCamera` resolves.
                      onCameraMoveStarted: () {
                        ref
                            .read(mapControlsControllerProvider.notifier)
                            .onCameraMoveStarted();
                      },
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      myLocationButtonEnabled: false,
                      compassEnabled: false,
                    ),
                  ),
                  Positioned(
                    top: mq.padding.top + 12,
                    left: 16,
                    child: _FloatingCircleButton(
                      semanticsLabel: 'Abrir menu',
                      icon: LucideIcons.menu,
                      onTap: () => AppDrawer.show(context),
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 12,
                    // Own RepaintBoundary: an InkWell ripple on either map
                    // control must not invalidate the GoogleMap PlatformView
                    // layer they share with it (perf-auditor MS-A3).
                    child: RepaintBoundary(
                      child: Column(
                        children: [
                          _FloatingCircleButton(
                            semanticsLabel: 'Alternar modo de mapa',
                            icon: LucideIcons.layers,
                            onTap: _onToggleMapType,
                            iconColor: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          _FloatingCircleButton(
                            semanticsLabel: 'Alternar para o mapa',
                            icon: LucideIcons.locateFixed,
                            onTap: _onRecenter,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: _dragStartFraction != null
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: mq.size.height * clampedFraction,
            child: isPreConfirm
                ? PreConfirmView(
                    stops: stops,
                    durationMinutes: activeMetrics?.duration ?? 0,
                    distanceMeters: activeMetrics?.distance ?? 0.0,
                    onRefine: _onRefine,
                    onConfirm: _onConfirm,
                    onStopTap: activeRouteId == null
                        ? (_) {}
                        : (stopId) => context.push(
                              '/home/routes/active/$activeRouteId'
                              '/stops/$stopId/edit',
                            ),
                  )
                : _ActiveRouteSheet(
                    currentFraction: clampedFraction,
                    collapsedFraction: _collapsedFraction,
                    configSummary: configSummary,
                    stops: stops,
                    routeDisplayName: routeDisplayName,
                    onAddStopTap: _openAddStop,
                    onOptimizeTap: _onOptimize,
                    onRouteNameTap: activeRouteId == null
                        ? null
                        : () =>
                            context.push('/home/routes/$activeRouteId/edit'),
                    onStopTap: activeRouteId == null
                        ? null
                        : (stopId) => context.push(
                              '/home/routes/active/$activeRouteId'
                              '/stops/$stopId/edit',
                            ),
                    onHandleDragStart: () {
                      _dragStartFraction = _sheetFraction;
                    },
                    onHandleDragUpdate: (delta) {
                      if (_dragStartFraction == null) return;
                      setState(() {
                        _sheetFraction =
                            (_sheetFraction - delta / mq.size.height).clamp(
                          _collapsedFraction,
                          _expandedFraction,
                        );
                      });
                    },
                    onHandleDragEnd: (velocity) {
                      _dragStartFraction = null;
                      setState(() => _sheetFraction = _snapTo(velocity));
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Layer toggle (Spoke `MapTypeClick`). Flips the persisted map layer and
  /// confirms the new state with an original-microcopy toast (ADR-0035 — not
  /// Spoke's verbatim "Satélite ativado/desativado", but the same two states).
  Future<void> _onToggleMapType() async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(mapControlsControllerProvider.notifier).toggleMapType();
    if (!mounted) return;
    final isSatellite =
        ref.read(mapControlsControllerProvider).value?.mapType ==
            MapType.satellite;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            isSatellite ? 'Modo Satélite ativado' : 'Modo Mapa ativado',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// Recenter (Spoke `ReCenterButtonClick`). Resolves the device location and,
  /// on success, enters follow mode + animates the camera. Degrades gracefully
  /// with a toast when permission is denied or the position is unavailable —
  /// never throws (mirrors `EditRouteViewModel.m9428W`'s no-permission branch).
  Future<void> _onRecenter() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await ref.read(locationServiceProvider).currentLocation();
    if (!mounted) return;

    switch (result) {
      case LocationReady(:final latitude, :final longitude):
        final notifier = ref.read(mapControlsControllerProvider.notifier);
        await notifier.startFollowing();
        final controller = await _controller.future;
        if (!mounted) return;
        // Attribute the upcoming onCameraMoveStarted to us (consumed by the
        // controller's pending-move counter), so our own animation does not
        // get mistaken for a user pan and drop the follow we just enabled.
        notifier.beginProgrammaticMove();
        await controller.animateCamera(
          CameraUpdate.newLatLng(LatLng(latitude, longitude)),
        );
      case LocationDenied():
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Permita o acesso à localização para centralizar no mapa.',
              ),
            ),
          );
      case LocationUnavailable():
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Não foi possível obter sua localização agora.'),
            ),
          );
    }
  }

  /// Abre o add-stop e trata o resultado do pop (H9 — o SHELL é o dono do
  /// toast: o context daqui está vivo após o pop do add-stop):
  ///   - `String id` → stop NOVO: SnackBar "Parada adicionada" + action
  ///     "Ver" (hide + push do editor com `?new=1`, F4);
  ///   - `({String editStopId})` → parada EXISTENTE (Section A): push
  ///     direto do editor, sem toast e sem badge (H11);
  ///   - null → cancelado/back: nada.
  Future<void> _openAddStop() async {
    final result = await context.push<Object?>('/home/routes/add-stop');
    if (!mounted) return;
    final activeRouteId = ref.read(activeRouteIdProvider);
    if (activeRouteId == null) return;

    switch (result) {
      case final String newStopId:
        final messenger = ScaffoldMessenger.of(context);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: const Text('Parada adicionada'),
              action: SnackBarAction(
                label: 'Ver',
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                  if (!mounted) return;
                  context.push(
                    '/home/routes/active/$activeRouteId'
                    '/stops/$newStopId/edit?new=1',
                  );
                },
              ),
            ),
          );
      case (editStopId: final String stopId):
        context.push(
          '/home/routes/active/$activeRouteId/stops/$stopId/edit',
        );
      default:
        break;
    }
  }

  /// Dispara a otimização da rota ativa (Á7 PR-A). Lê os stops, delega ao
  /// [OptimizationController] e reage ao [OptimizationOutcome] selado:
  /// G1 (NotEnoughStops) → diálogo "Adicione mais paradas"; falha de
  /// rede/solver → diálogo de erro; sucesso → SnackBar honest-stub com as
  /// métricas reais do solver (o PR-B troca isto pela transição ao
  /// PRE-CONFIRM).
  Future<void> _onOptimize() async {
    final stops = ref.read(currentRouteStopsProvider);
    if (stops.isEmpty) {
      await showNotEnoughStopsDialog(context);
      return;
    }
    // Start = posição da rota (Slice 2: usa o primeiro stop como referência
    // até a Partida real estar wirada; o solver é determinístico de qualquer
    // forma). O PR-B liga isto à Partida da config.
    final outcome =
        await ref.read(optimizationControllerProvider.notifier).optimize(
              start: GeoPoint(stops.first.lat, stops.first.lng),
              stops: stops,
              type: OptimizeType.restartRoute,
            );
    if (!mounted) return;
    switch (outcome) {
      case NotEnoughStops():
        await showNotEnoughStopsDialog(context);
      case OptimizationFailure():
        // O diálogo de erro oferece duas ações reais: "Tentar de novo" re-roda
        // o solver; "Pular otimização" é honest-stub no PR-A (o Ready-to-Run com
        // banner "Otimização pendente" do Spoke é PR-C). Consumir a escolha é
        // obrigatório — descartar o retorno deixaria "Tentar de novo" sem efeito.
        final choice = await showOptimizationErrorDialog(context);
        if (!mounted) return;
        switch (choice) {
          case OptimizationErrorChoice.retry:
            await _onOptimize();
          case OptimizationErrorChoice.skip:
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Otimização pulada por enquanto.')),
            );
          case null:
            break; // diálogo dispensado (barrier/back) — sem ação
        }
      case OptimizationSuccess(:final result):
        final routeId = ref.read(activeRouteIdProvider);
        if (routeId == null) return;
        // FTUE one-shot ANTES de aplicar (o Spoke mostra o educativo de
        // numeração na 1ª otimização da vida do usuário; nas próximas, não).
        final ftue = ref.read(optimizationFtueRepositoryProvider);
        if (!await ftue.isNumberingAcknowledged()) {
          if (!mounted) return;
          final choice = await showIdEducationDialog(context);
          if (choice == IdEducationChoice.acknowledge) {
            await ftue.acknowledgeNumbering();
          } else if (choice == IdEducationChoice.configure) {
            // "Ajustar formato" leva ao formato do ID (Á10) — honest-stub aqui.
            await ftue.acknowledgeNumbering();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ajuste de formato do ID — em breve.'),
              ),
            );
          }
          // choice == null (barrier/back): não marca o FTUE; reaparece na
          // próxima otimização — aceitável (sem estado órfão).
        }
        // Aplica o resultado: o switch de estado no build leva ao
        // PreConfirmView automaticamente.
        ref.read(routesProvider.notifier).applyOptimization(routeId, result);
    }
  }

  /// "Refinar" do PRE-CONFIRM → sheet {Inverter / Ordenar manual}. "Inverter"
  /// re-roda o solver com [OptimizeDirection.reverse]; "Ordenar manualmente"
  /// (OrderStopGroups) é o PR-D — honest-stub observável aqui.
  Future<void> _onRefine() async {
    final choice = await showRefineRouteSheet(context);
    if (!mounted || choice == null) return;
    final routeId = ref.read(activeRouteIdProvider);
    if (routeId == null) return;

    switch (choice) {
      case RefineRouteChoice.invert:
        final stops = ref.read(currentRouteStopsProvider);
        if (stops.isEmpty) return;
        final outcome =
            await ref.read(optimizationControllerProvider.notifier).optimize(
                  start: GeoPoint(stops.first.lat, stops.first.lng),
                  stops: stops,
                  type: OptimizeType.reorderFlexible,
                  direction: OptimizeDirection.reverse,
                );
        if (!mounted) return;
        switch (outcome) {
          case OptimizationSuccess(:final result):
            ref
                .read(routesProvider.notifier)
                .applyOptimization(routeId, result);
          case OptimizationFailure():
            // Erro do solver ao inverter — NÃO engolir em silêncio. Mesmo
            // tratamento do _onOptimize: oferece "Tentar de novo" / "Pular".
            final choice = await showOptimizationErrorDialog(context);
            if (!mounted) return;
            if (choice == OptimizationErrorChoice.retry) await _onRefine();
          case NotEnoughStops():
            // A rota já está otimizada (estamos no PRE-CONFIRM) — inverter não
            // muda a contagem; caminho teórico. Diálogo G1 por consistência.
            await showNotEnoughStopsDialog(context);
        }
      case RefineRouteChoice.manualOrder:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ordenar no mapa — em breve.')),
        );
    }
  }

  /// "Confirmar" do PRE-CONFIRM → leva ao Ready-to-Run, que é o PR-C.
  /// Honest-stub observável: NÃO grava `confirmed:true` ainda (sem destino
  /// Ready-to-Run o estado ficaria órfão).
  void _onConfirm() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:
            Text('Tudo certo — a confirmação final chega na próxima etapa.'),
      ),
    );
  }

  /// Snap helper — comportamento canônico Spoke (live 2026-05-28):
  ///   - Flick pra cima (velocity < -kFlick) → próximo snap MAIOR.
  ///   - Flick pra baixo (velocity > kFlick) → próximo snap MENOR.
  ///   - Sem flick claro → snap-to-nearest na fração atual.
  ///
  /// O snap-to-nearest puro (que tinha antes) tornava a transição
  /// mid → expanded relutante: como mid (0.40) está mais perto de
  /// collapsed (0.18) que de expanded (0.90), qualquer arrasto suave
  /// voltava pro mid. Direction-based resolve: qualquer flick pra cima
  /// já promove ao próximo snap maior, igual Spoke.
  double _snapTo(double velocity) {
    const kFlickThreshold = 50.0; // px/s — abaixo disso conta como "parado".
    final snaps = [_collapsedFraction, _mediumFraction, _expandedFraction];

    if (velocity < -kFlickThreshold) {
      // Flick pra cima → próximo snap maior que o atual (com pequena
      // tolerância pra evitar comparar com o próprio).
      for (final s in snaps) {
        if (s > _sheetFraction + 0.01) return s;
      }
      return snaps.last;
    }
    if (velocity > kFlickThreshold) {
      // Flick pra baixo → próximo snap menor que o atual.
      for (final s in snaps.reversed) {
        if (s < _sheetFraction - 0.01) return s;
      }
      return snaps.first;
    }

    // Sem flick claro: snap-to-nearest puro.
    var closest = snaps.first;
    var minDist = (_sheetFraction - closest).abs();
    for (final s in snaps) {
      final d = (_sheetFraction - s).abs();
      if (d < minDist) {
        minDist = d;
        closest = s;
      }
    }
    return closest;
  }
}

class _FloatingCircleButton extends StatelessWidget {
  const _FloatingCircleButton({
    required this.semanticsLabel,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  final String semanticsLabel;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Material(
        color: AppColors.bg,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: const Color(0x2E1A1A2E),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, size: 22, color: iconColor ?? AppColors.text),
          ),
        ),
      ),
    );
  }
}

class _ActiveRouteSheet extends StatelessWidget {
  const _ActiveRouteSheet({
    required this.currentFraction,
    required this.collapsedFraction,
    required this.configSummary,
    required this.stops,
    required this.routeDisplayName,
    required this.onAddStopTap,
    required this.onOptimizeTap,
    required this.onRouteNameTap,
    required this.onStopTap,
    required this.onHandleDragStart,
    required this.onHandleDragUpdate,
    required this.onHandleDragEnd,
  });

  /// Fração atual do sheet (mesma usada pelo AnimatedContainer do pai).
  /// Quando estamos perto do collapsedFraction, escondemos os 2 big buttons
  /// fixos no rodapé pra não aparecerem cortados.
  final double currentFraction;

  /// Fração mínima (collapsed). Usado como ponto de comparação.
  final double collapsedFraction;

  /// "Configuração de rota" summary (ADR-0046), or `null` when there is no
  /// active route. Rendered inside the medium+ scrollable body, above the
  /// empty-state/stop-list, mirroring Spoke's `stepList` placement.
  final Widget? configSummary;

  /// Stops da rota ativa (MS-A6 T7). Vazio = branch empty-state atual.
  final List<Stop> stops;

  /// Nome de display da rota ativa (header da lista, H8). Null sem rota.
  final String? routeDisplayName;

  /// Abre o add-stop com await-push e trata o resultado (toast "Ver" /
  /// push direto do editor — H9/H11). Dono: `_RouteShellPageState`.
  final Future<void> Function() onAddStopTap;

  /// Dispara a otimização da rota ativa (Á7 PR-A). Dono: `_RouteShellPageState`.
  final VoidCallback onOptimizeTap;

  /// Tap no nome da rota → wizard de edição (H8). Null sem rota ativa.
  final VoidCallback? onRouteNameTap;

  /// Tap num stop card → editor da parada (T7→T8). Null sem rota ativa.
  final void Function(String stopId)? onStopTap;

  /// Disparado quando o user começa a arrastar a área do handle (parte
  /// superior do sheet, ~24px). O parent guarda a fração atual pra usar
  /// como ponto de partida do drag.
  final VoidCallback onHandleDragStart;

  /// Delta em pixels (positivo = movimento pra BAIXO; negativo = pra CIMA).
  /// O parent traduz isso em incremento de altura do SizedBox que envolve
  /// este sheet (movimento pra cima EXPANDE o sheet, isto é, cresce a
  /// altura → mapa encolhe).
  final void Function(double deltaPixels) onHandleDragUpdate;

  /// Velocidade vertical final (pixels/segundo). Negativa = flick pra
  /// cima → snap pro maior bucket; positiva = flick pra baixo → snap pro
  /// menor.
  final void Function(double velocityPixelsPerSecond) onHandleDragEnd;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.padding.bottom;

    // Mostrar os big buttons só quando o sheet está claramente acima do
    // collapsed (epsilon 0.02 evita flicker no snap).
    final showButtons = currentFraction > collapsedFraction + 0.02;

    // Altura real do sheet neste frame (mesma fórmula do AnimatedContainer pai).
    // Durante o arrasto pra baixo o sheet passa por frações intermediárias
    // baixas; um rodapé de altura fixa abaixo do corpo flexível estoura o
    // RenderFlex se a altura cair abaixo da soma do chrome fixo. O CTA
    // (52 + 8 + 12 + bottomInset) + handle (24) + search row (64) é mais alto
    // que o piso `showButtons`, então ele ganha um gate de altura próprio.
    final sheetHeight = mq.size.height * currentFraction;
    // Soma do chrome fixo acima/abaixo do corpo flexível: handle (24) +
    // search row (48 + 8×2 de padding = 64) + OptimizeCta (height 52 em
    // optimize_cta.dart) + padding-top do CTA (8) + padding-bottom (12) +
    // a nav-bar do sistema. Se alguma dessas alturas mudar, reavaliar aqui.
    final footerChromePx = 24.0 + 64.0 + 52.0 + 8.0 + 12.0 + bottomInset;
    final hasRoomForCta = sheetHeight >= footerChromePx;

    // GestureDetector EXTERNO captura vertical drag em TODA a área do
    // sheet (handle, pill row, big buttons). `behavior: translucent` deixa
    // tap em InkWell internos continuarem funcionando — drag e tap são
    // gestos diferentes na arena do Flutter.
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragStart: (_) => onHandleDragStart(),
      onVerticalDragUpdate: (d) => onHandleDragUpdate(d.delta.dy),
      onVerticalDragEnd: (d) => onHandleDragEnd(d.velocity.pixelsPerSecond.dy),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle bar único (~24px). Único — não duplicado.
              SizedBox(
                height: 24,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              _buildSearchRow(context),
              // Spacer expandido — quando o sheet está medium+ hospeda a seção
              // "Configuração de rota" (MS-A5.7) + o empty state da Spoke
              // (dashed pin + microcopy). No collapsed fica vazio
              // (SizedBox.shrink) pra não ocupar espaço. O corpo é scrollável
              // pra nunca dar overflow em frações intermediárias (a seção de
              // config tem altura fixa). No futuro hospeda a lista de stops.
              // Também serve como área de captura de drag (GestureDetector
              // externo translucent).
              Expanded(
                child: !showButtons
                    ? const SizedBox.shrink()
                    : stops.isNotEmpty
                        // Rota ativa COM paradas (MS-A6 T7): header da lista
                        // + ListView.builder com o config summary como item 0
                        // (H7). Drag no corpo SCROLLA a lista (não
                        // redimensiona o sheet) — intencional, match-Spoke
                        // §10.5: resize fica no handle + search-row.
                        ? _buildStopsBody(context)
                        : configSummary == null
                            // No active route: keep the original centered
                            // empty state (existing Spoke parity, unchanged).
                            ? _buildEmptyState(context)
                            // Active route: config summary on top, empty
                            // state below, in a scroll view so intermediate
                            // fractions never overflow.
                            : SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    configSummary!,
                                    _buildEmptyState(context),
                                  ],
                                ),
                              ),
              ),
              // Big buttons FIXOS no rodapé. Só renderizados quando o sheet
              // está medium+ (showButtons = true) E a rota não tem paradas —
              // eles são empty-state-only (H5); com ≥1 parada o footer fica
              // vazio até a Á7 trazer o CTA "Otimizar rota". Sempre respeitam
              // o bottomInset do device (não ficam por baixo dos nav buttons).
              if (showButtons && stops.isEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SheetPrimaryButton(
                        icon: LucideIcons.plus,
                        label: 'Adicionar parada',
                        onTap: onAddStopTap,
                      ),
                      const SizedBox(height: 10),
                      _SheetOutlinedButton(
                        label: 'Copiar paradas de uma rota anterior',
                        onTap: () => context.push('/home/routes/reuse-stops'),
                      ),
                    ],
                  ),
                ),
              // CTA "Otimizar rota" — nasce aqui (Á7 PR-A). Aparece quando o
              // sheet está medium+ E tem altura pra acomodar o rodapé fixo E a
              // rota tem >=1 parada (o slot que era vazio desde a MS-A6).
              // Otimização é grátis (sem paywall).
              if (showButtons && hasRoomForCta && stops.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset + 12),
                  child: OptimizeCta(
                    enabled: stops.length >= OptimizationController.minStops,
                    onPressed: onOptimizeTap,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Corpo do sheet quando a rota ativa tem ≥1 parada (MS-A6 T7, §10.5):
  /// um ListView.builder ÚNICO — item 0 = header (contador "N paradas" +
  /// nome da rota clicável, H8); item 1 = config summary achatado + título
  /// "Paradas" (H7); itens 2.. = um [_StopCard] por parada. Tudo dentro do
  /// builder para o corpo nunca transbordar em frações intermediárias do
  /// drag (mesma razão do FittedBox no empty state).
  Widget _buildStopsBody(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: stops.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${stops.length} '
                  '${stops.length == 1 ? 'parada' : 'paradas'}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Semantics(
                  identifier: 'sheet_route_name',
                  button: true,
                  child: InkWell(
                    onTap: onRouteNameTap,
                    borderRadius: BorderRadius.circular(6),
                    child: Text(
                      routeDisplayName ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (index == 1) {
          // Config summary + título da seção "Paradas" (H7).
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (configSummary != null) configSummary!,
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  'Paradas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          );
        }
        final position = index - 1; // 1-based
        final stop = stops[position - 1];
        return _StopCard(
          key: ValueKey(stop.id),
          position: position,
          stop: stop,
          onTap: onStopTap == null ? null : () => onStopTap!(stop.id),
        );
      },
    );
  }

  /// Empty state visível quando o sheet está medium+ e a rota não tem
  /// paradas ainda (estado canônico observado na Spoke 2026-05-28).
  /// Pin quadrado arredondado (NÃO oval) + microcopy PT-BR.
  ///
  /// Wrap em FittedBox pra evitar overflow durante o drag em frações
  /// intermediárias (quando o Expanded fica com altura insuficiente
  /// momentaneamente).
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pin 48x48 quadrado arredondado — radius < dimensão/2
              // garante quadrado-com-cantos-arredondados (não oval).
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textMuted.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  LucideIcons.plus,
                  color: AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(height: 10),
              const SizedBox(
                width: 280,
                child: Text(
                  'Adicione as primeiras paradas para começar a criar sua rota',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Search pill + kebab — sempre visível em qualquer estado do sheet.
  Widget _buildSearchRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onAddStopTap,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                height: 48,
                padding: const EdgeInsets.only(left: 12, right: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.search,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Adicionar parada...',
                        style:
                            TextStyle(color: AppColors.textMuted, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _SearchInnerButton(
                      icon: LucideIcons.camera,
                      onTap: () => _comingSoon(context, 'Leitor OCR'),
                    ),
                    const SizedBox(width: 4),
                    _SearchInnerButton(
                      icon: LucideIcons.mic,
                      onTap: () => _comingSoon(context, 'Comando de Voz'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          _GradientCircleButton(
            icon: LucideIcons.moreVertical,
            semanticsLabel: 'Opções da rota',
            onTap: () => _comingSoon(context, 'Opções da Rota'),
          ),
        ],
      ),
    );
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature em breve')),
    );
  }
}

/// Card de uma parada na lista do sheet ativo (MS-A6 T7, §10.5):
/// badge numérico 2 dígitos (tabular) + rua (h6) + endereço completo (muted)
/// + dot de status à direita. O card INTEIRO é clicável → editor da parada.
class _StopCard extends StatelessWidget {
  const _StopCard({
    super.key,
    required this.position,
    required this.stop,
    required this.onTap,
  });

  /// Posição 1-based na lista (badge "01", "02", …).
  final int position;
  final Stop stop;
  final VoidCallback? onTap;

  Color get _statusColor => switch (stop.status) {
        StopStatus.pending => AppColors.textMuted,
        StopStatus.delivered || StopStatus.pickedUp => AppColors.success,
        StopStatus.failed => AppColors.error,
      };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: 'stop_card_$position',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Text(
                position.toString().padLeft(2, '0'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stop.streetName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stop.fullAddress,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                key: Key('stop_card_${position}_status_dot'),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchInnerButton extends StatelessWidget {
  const _SearchInnerButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}

/// Botão principal do sheet: roxo gradient (filled).
/// Texto branco, ícone Lucide branco, fonte menor (14sp) per pedido
/// 2026-05-28 (estavam grandes demais).
class _SheetPrimaryButton extends StatelessWidget {
  const _SheetPrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão secundário do sheet: outlined, sem fill, borda + texto roxos.
/// Spoke (live dump 2026-05-28) renderiza este botão SEM ícone — só
/// texto centralizado. Fonte menor (14sp).
class _SheetOutlinedButton extends StatelessWidget {
  const _SheetOutlinedButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientCircleButton extends StatelessWidget {
  const _GradientCircleButton({
    required this.icon,
    required this.semanticsLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: AppColors.primary.withValues(alpha: 0.3),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(icon, size: 22, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// "Configuração de rota" summary shown in the active-route sheet (ADR-0046).
/// Spoke renders a 2-row summary — Início + Ida-e-volta, NO Pausa —
/// above the stop list; tapping either row opens the full "Detalhes da rota"
/// page (`RouteDetailsPage`). The summary microcopy is DISTINCT from the
/// Detalhes-page rows (Spoke uses "Iniciar no local atual" /
/// "Use a posição do GPS ao otimizar" here, vs "Usar local atual" /
/// "Iniciar agora mesmo" inside Detalhes — live capture 2026-06-10,
/// /tmp/spoke-a57-config-rows-inspection/EVIDENCE.md).
///
/// A [ConsumerWidget] that watches only the two `RouteConfig` fields it
/// renders (`startLocation`, `destination`) via `.select`, so a break/time
/// mutation on the Detalhes page does NOT rebuild the parent shell (map + drag
/// geometry) — only these two rows. The rows are pure reads; all writes happen
/// on the Detalhes page via its own sub-pickers, so both rows simply navigate
/// (no returns-intent — there is no popped result to consume here).
class _ConfigSummarySection extends ConsumerWidget {
  const _ConfigSummarySection({
    required this.routeId,
    required this.onOpenDetails,
  });

  final String routeId;
  final VoidCallback onOpenDetails;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startLocation = ref.watch(
      routeConfigControllerProvider(routeId).select((c) => c.startLocation),
    );
    final destination = ref.watch(
      routeConfigControllerProvider(routeId).select((c) => c.destination),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Configuração de rota',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          RouteConfigRow(
            semanticsKey: 'config_summary_inicio',
            label: _inicioLabel(startLocation),
            subtitle: 'Use a posição do GPS ao otimizar',
            leading: LucideIcons.house,
            active: true,
            onTap: onOpenDetails,
          ),
          RouteConfigRow(
            semanticsKey: 'config_summary_destino',
            label: _destinoLabel(destination),
            subtitle: _destinoSubtitle(destination),
            leading: _destinoIcon(destination),
            active: true,
            onTap: onOpenDetails,
          ),
        ],
      ),
    );
  }

  /// Início primary label: the chosen custom address when set, else Spoke's
  /// GPS placeholder. Matches the active-route summary copy (NOT the Detalhes
  /// "Usar local atual" / "Iniciar agora mesmo" wording).
  String _inicioLabel(StartLocation? loc) {
    if (loc != null && !loc.isUserCurrentLocation) return loc.address;
    return 'Iniciar no local atual';
  }

  /// Ida-e-volta primary label, derived from the destination. RoundTrip (the
  /// `RouteConfig.empty` default) reads "Ida e volta".
  String _destinoLabel(Destination? destination) {
    return switch (destination) {
      null || RoundTrip() => 'Ida e volta',
      SpecificAddress(:final address) => address,
      NoDestination() => 'Nenhum destino',
    };
  }

  /// Summary subtitle. RoundTrip uses Spoke's active-route copy "Retorne ao
  /// ponto de partida" (distinct from the Detalhes-page "Viagem de ida e volta
  /// a partir do local atual"). Other variants have no subtitle.
  String? _destinoSubtitle(Destination? destination) {
    return switch (destination) {
      null || RoundTrip() => 'Retorne ao ponto de partida',
      SpecificAddress() => null,
      NoDestination() => null,
    };
  }

  IconData _destinoIcon(Destination? destination) {
    return switch (destination) {
      null || RoundTrip() => LucideIcons.cornerUpLeft,
      SpecificAddress() => LucideIcons.mapPin,
      NoDestination() => LucideIcons.flag,
    };
  }
}
