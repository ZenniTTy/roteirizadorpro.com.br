import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Step list da rota ativa — peças compartilhadas pelos três estados do shell
/// (DRAFT, PRE-CONFIRM, Ready-to-Run). Espelha a ANATOMIA do `editroute/steplist`
/// do Spoke v3.65.1 (ver `docs/superpowers/specs/2026-06-21-active-route-steplist-design.md`),
/// com identidade visual ORIGINAL (ADR-0035 — Spoke rege comportamento/estrutura,
/// não pixels):
///
/// - **Linha de início** sempre no topo ("Iniciar no local atual" / "Ponto de
///   partida") — `RouteStartStep`.
/// - **Linhas de parada** com slot esquerdo (disco): círculo vazio em DRAFT
///   (sem posição), número quando otimizada, número + ETA ("Chegada HH:mm")
///   quando há horário previsto — `RouteStopStep`.
/// - **Linha de destino** sempre no fim ("Nenhum destino" / "Ida e volta" /
///   "Finalizar em X") — `RouteEndStep`.
/// - **Trilho vertical** conectando os passos (visual "metrô" do Spoke).
///
/// O ETA por parada é o `Stop.estimatedArrival` (aproximação local no Slice 2,
/// real no Slice 3). Em DRAFT ele é null → disco fica círculo vazio, sem hora.

/// Formata um ETA absoluto como "HH:mm" 24h (PT-BR).
String formatEta(DateTime eta) => '${eta.hour.toString().padLeft(2, '0')}:'
    '${eta.minute.toString().padLeft(2, '0')}';

const _railColor = AppColors.border;
const _railWidth = 40.0;
const _discSize = 28.0;
// Centro vertical do disco a partir do topo da linha (padding 12 + raio 14).
const _discCenterY = 12.0 + _discSize / 2;

/// Linha de uma parada. Em DRAFT [position]/[etaTime] são null → disco vira
/// círculo vazio (fiel ao Spoke: número/ETA só pós-otimização).
class RouteStopStep extends StatelessWidget {
  const RouteStopStep({
    required this.streetName,
    required this.fullAddress,
    required this.statusColor,
    this.position,
    this.etaTime,
    this.isFirst = false,
    this.isLast = false,
    this.faded = false,
    this.onTap,
    this.semanticsId,
    this.statusDotKey,
    this.trailing,
    super.key,
  });

  final String streetName;
  final String fullAddress;
  final Color statusColor;

  /// Override do identificador de acessibilidade (o shell passa `stop_card_N`
  /// para manter os testes de tap/estrutura). Default deriva da [position].
  final String? semanticsId;

  /// Key do dot de status (o shell passa `stop_card_N_status_dot`).
  final Key? statusDotKey;

  /// Override do trailing: quando fornecido, substitui o dot de status (ex.: o
  /// chip de ID de parada "A1" nos estados otimizados — número da parada e ID
  /// coexistem, o formato Moderno do Spoke existe pra não confundi-los).
  final Widget? trailing;

  /// Posição 1-based na rota otimizada; null em DRAFT (disco = círculo vazio).
  final int? position;

  /// ETA formatado ("14:32"); null quando não otimizada (sem hora).
  final String? etaTime;

  /// Primeira parada — sem trilho acima (o trilho conecta só as paradas entre
  /// si, já que início/destino vivem no config-summary, não na lista).
  final bool isFirst;

  /// Última parada — sem trilho abaixo.
  final bool isLast;
  final bool faded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _StepRow(
      semanticsId: semanticsId ?? 'route_stop_step_${position ?? 'draft'}',
      hasLineAbove: !isFirst,
      hasLineBelow: !isLast,
      faded: faded,
      disc: _StepDisc(number: position, timeTop: etaTime),
      lineOne: streetName,
      lineTwo: fullAddress,
      trailing: trailing ??
          Container(
            key: statusDotKey,
            width: 10,
            height: 10,
            decoration:
                BoxDecoration(shape: BoxShape.circle, color: statusColor),
          ),
      onTap: onTap,
    );
  }
}

/// Linha genérica da step list: coluna do trilho (linha vertical + disco) +
/// conteúdo (duas linhas) + trailing opcional. O trilho é contínuo entre as
/// linhas via [hasLineAbove]/[hasLineBelow].
class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.semanticsId,
    required this.disc,
    required this.lineOne,
    required this.hasLineAbove,
    required this.hasLineBelow,
    this.lineTwo,
    this.trailing,
    this.faded = false,
    this.onTap,
  });

  final String semanticsId;
  final Widget disc;
  final String lineOne;
  final String? lineTwo;
  final Widget? trailing;
  final bool hasLineAbove;
  final bool hasLineBelow;
  final bool faded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = faded ? AppColors.textMuted : AppColors.text;
    return Semantics(
      identifier: semanticsId,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RailColumn(
                disc: disc,
                hasLineAbove: hasLineAbove,
                hasLineBelow: hasLineBelow,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lineOne,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (lineTwo != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          lineTwo!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(right: 20, top: 12),
                  child: trailing,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Coluna do trilho: linha vertical contínua (acima/abaixo) + disco centrado.
class _RailColumn extends StatelessWidget {
  const _RailColumn({
    required this.disc,
    required this.hasLineAbove,
    required this.hasLineBelow,
  });

  final Widget disc;
  final bool hasLineAbove;
  final bool hasLineBelow;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _railWidth,
      child: Stack(
        children: [
          if (hasLineAbove)
            const Positioned(
              top: 0,
              left: _railWidth / 2 - 1,
              width: 2,
              height: _discCenterY,
              child: ColoredBox(color: _railColor),
            ),
          if (hasLineBelow)
            const Positioned(
              top: _discCenterY,
              bottom: 0,
              left: _railWidth / 2 - 1,
              width: 2,
              child: ColoredBox(color: _railColor),
            ),
          Positioned(
            top: 12,
            left: (_railWidth - _discSize) / 2,
            child: disc,
          ),
        ],
      ),
    );
  }
}

/// Disco do slot esquerdo. Prioridade do conteúdo (fiel ao `AbstractC2673d`):
/// número (StopNumber) > círculo vazio (Circle). Quando há [timeTop] (ETA), ele
/// aparece como rótulo pequeno ACIMA do disco — o "TimeAndStopNumber" do Spoke
/// (número + hora coexistem).
class _StepDisc extends StatelessWidget {
  const _StepDisc({this.number, this.timeTop});

  final int? number;
  final String? timeTop;

  @override
  Widget build(BuildContext context) {
    final Widget disc;
    if (number != null) {
      disc = _circle(
        child: Text(
          '$number',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      );
    } else {
      disc = _circle();
    }

    if (timeTop == null) return disc;
    // Número/ícone + hora: o rótulo de hora cresce ACIMA do disco sem mover o
    // centro do disco (o trilho permanece alinhado).
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        disc,
        Positioned(
          bottom: _discSize - 2,
          child: Text(
            timeTop!,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _circle({Widget? child}) {
    return Container(
      width: _discSize,
      height: _discSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.bg,
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: child,
    );
  }
}
