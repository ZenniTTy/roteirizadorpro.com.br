import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import 'widgets/app_drawer.dart';

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

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Collapsed = handle + pill + breathing room + system nav inset.
    final collapsedPx = 130.0 + mq.padding.bottom;
    _collapsedFraction = (collapsedPx / mq.size.height).clamp(0.15, 0.35);

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
            child: Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _initialPosition,
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
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
                  child: Column(
                    children: [
                      _FloatingCircleButton(
                        semanticsLabel: 'Alternar modo de mapa',
                        icon: LucideIcons.layers,
                        onTap: () =>
                            _comingSoon(context, 'Alternar modo de mapa'),
                        iconColor: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      _FloatingCircleButton(
                        semanticsLabel: 'Alternar para o mapa',
                        icon: LucideIcons.locateFixed,
                        onTap: () => _comingSoon(context, 'Centrar no mapa'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          AnimatedContainer(
            duration: _dragStartFraction != null
                ? Duration.zero
                : const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            height: mq.size.height * clampedFraction,
            child: _ActiveRouteSheet(
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

  /// Snap-to-nearest helper. Velocity > 0 = arrastando pra baixo (encolher),
  /// < 0 = pra cima (crescer). Snap mais próximo entre collapsed/medium/
  /// expanded com viés pra direção da velocidade.
  double _snapTo(double velocity) {
    final snaps = [_collapsedFraction, _mediumFraction, _expandedFraction];
    // Aplica viés na direção do flick.
    final biased = _sheetFraction - velocity * 0.0001;
    var closest = snaps.first;
    var minDist = (biased - closest).abs();
    for (final s in snaps) {
      final d = (biased - s).abs();
      if (d < minDist) {
        minDist = d;
        closest = s;
      }
    }
    return closest;
  }
}

void _comingSoon(BuildContext context, String label) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$label — em breve')),
  );
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
    required this.onHandleDragStart,
    required this.onHandleDragUpdate,
    required this.onHandleDragEnd,
  });

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar (~24px) — sem GestureDetector interno: o externo
            // captura.
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
            _buildCollapsedContent(context),
            // Big buttons. ClampingScrollPhysics evita o user scrollar a
            // lista interna acidentalmente — mas como o GestureDetector
            // externo está em arena com qualquer ScrollView interno, no
            // estado collapsed o drag vertical sempre ganha vs scroll.
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildMediumContent(context),
                    SizedBox(height: bottomInset + 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Conteúdo SEMPRE visível, mesmo no estado collapsed:
  /// drag handle + search pill (com OCR + mic + kebab).
  /// Tamanho: ~108px. Cabe na viewport collapsed sem virar o
  /// CustomScrollView scrollable — garantia pro drag-to-expand funcionar.
  Widget _buildCollapsedContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => context.push('/home/routes/add-stop'),
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
                        const Icon(LucideIcons.search,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Adicionar parada...',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 14),
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
        ),
      ],
    );
  }

  /// Conteúdo do estado MEDIUM em diante: 2 big buttons (Adicionar paradas
  /// + Copiar paradas de rota anterior). Fica abaixo do collapsed content;
  /// no estado collapsed o user só vê a borda superior deles antes do drag.
  Widget _buildMediumContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        children: [
          _SheetBigButton(
            icon: LucideIcons.plusCircle,
            label: 'Adicionar paradas',
            onTap: () => context.push('/home/routes/add-stop'),
          ),
          const SizedBox(height: 12),
          _SheetBigButton(
            icon: LucideIcons.copy,
            label: 'Copiar paradas de uma rota anterior',
            onTap: () => _comingSoon(context, 'Copiar paradas'),
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

class _SheetBigButton extends StatelessWidget {
  const _SheetBigButton(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text),
              ),
            ),
          ],
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
