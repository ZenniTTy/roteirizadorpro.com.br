import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../settings/data/settings_repository.dart';
import '../../../settings/state/settings_controller.dart';
import '../../domain/optimization_state.dart';
import '../../domain/package_details.dart';
import '../../domain/place_in_vehicle.dart';
import '../../domain/stop.dart';
import '../../domain/stop_order_policy.dart';
import '../../state/routes_provider.dart';
import '../../state/address_instructions_controller.dart';
import '../widgets/access_instructions_sheet.dart';
import '../widgets/confirm_deferred_removal_dialog.dart';
import '../widgets/arrival_window_sheet.dart';
import '../widgets/package_finder_sheet.dart';
import '../widgets/time_at_stop_dialog.dart';
import '../widgets/color_picker_sheet.dart';
import '../widgets/package_count_row.dart';
import '../widgets/stop_notes_section.dart';

/// Página full-screen de edição de parada (MS-A6 T8, D1).
///
/// Rota: `/home/routes/active/:routeId/stops/:stopId/edit`
/// Query param: `?new=1` → [showAddedBadge] = true (via toast-"Ver" /
/// Duplicar, F4/F5).
///
/// Edits são aplicados LIVE por campo (F3 — cada sub-surface commit-on-dismiss
/// chama `updateStop`); o botão "Concluído" apenas fecha a página.
/// As rows abaixo nascem com stub-SnackBar POR ROW e são substituídas pelas
/// sub-surfaces reais nas tasks T10–T16 (nunca `onTap: () {}` silencioso).
class EditStopPage extends ConsumerStatefulWidget {
  const EditStopPage({
    super.key,
    required this.routeId,
    required this.stopId,
    this.showAddedBadge = false,
  });

  final String routeId;
  final String stopId;

  /// Exibe o badge "Adicionada" quando `true`.
  final bool showAddedBadge;

  @override
  ConsumerState<EditStopPage> createState() => _EditStopPageState();
}

class _EditStopPageState extends ConsumerState<EditStopPage> {
  // H12: garante UM único pop agendado quando o stopId não resolve
  // (removida na janela do toast "Ver", deep-link stale, restore).
  bool _popScheduled = false;

  void _stub(String feature) {
    showAppSnackBar(context, '$feature em breve');
  }

  /// Instruções de acesso (F13/H18): pré-preenche com a instrução desta
  /// parada OU o default sticky do endereço; Salvar com switch ON grava nos
  /// dois; Limpar limpa o stop (e o default, se switch ON).
  Future<void> _openAccessInstructions(Stop stop) async {
    final repo = ref.read(addressInstructionsRepositoryProvider);
    final sticky = await repo.instructionFor(stop.fullAddress);
    if (!mounted) return;
    final result = await AccessInstructionsSheet.show(
      context,
      initialText: stop.accessInstructions ?? sticky,
    );
    if (!mounted) return;
    switch (result) {
      case AccessInstructionsSaved(:final text, :final saveAsDefault):
        final next = text.isEmpty ? null : text;
        ref.read(routesProvider.notifier).updateStop(
              widget.routeId,
              stop.copyWith(accessInstructions: next),
            );
        if (saveAsDefault && next != null) {
          await repo.saveDefault(stop.fullAddress, next);
        }
      case AccessInstructionsCleared(:final clearDefault):
        ref.read(routesProvider.notifier).updateStop(
              widget.routeId,
              stop.copyWith(accessInstructions: null),
            );
        if (clearDefault) await repo.clearDefault(stop.fullAddress);
      case null:
        break;
    }
  }

  /// 24h com zero-pad — NÃO usa TimeOfDay.format (locale/12h dependente).
  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';

  /// Display da janela de chegada (jadx UiFormatters.m8466v): ambos →
  /// 'HH:MM - HH:MM'; só início → 'Após HH:MM'; só fim → 'Antes de HH:MM';
  /// vazio → 'Qualquer momento'.
  String _formatWindow(Stop stop) {
    final start = stop.timeWindowStart;
    final end = stop.timeWindowEnd;
    if (start != null && end != null) {
      return '${_formatTime(start)} - ${_formatTime(end)}';
    }
    if (start != null) return 'Após ${_formatTime(start)}';
    if (end != null) return 'Antes de ${_formatTime(end)}';
    return 'Qualquer momento';
  }

  /// Janela de chegada (F7/H1/D8): sheet com 2 rows → numpad. Record popado
  /// = janela completa; null explícito em um lado LIMPA (copyWith _omit).
  Future<void> _openArrivalWindow(Stop stop) async {
    final result = await ArrivalWindowSheet.show(
      context,
      initialStart: stop.timeWindowStart,
      initialEnd: stop.timeWindowEnd,
    );
    if (result == null || !mounted) return;
    ref.read(routesProvider.notifier).updateStop(
          widget.routeId,
          stop.copyWith(
            timeWindowStart: result.start,
            timeWindowEnd: result.end,
          ),
        );
  }

  /// Default global do tempo na parada (H14): lê do settingsController;
  /// enquanto carrega (ou em erro) usa o fallback canônico declarado UMA vez
  /// em [Settings.fallbackStopDuration].
  /// Caminho do BUILD (rebuild quando o default global muda): usado por
  /// [_formatTimeAtStop]. Em callbacks de evento use [_readGlobalStopDuration].
  Duration get _watchGlobalStopDuration =>
      ref.watch(
        settingsControllerProvider
            .select((async) => async.value?.defaultStopDuration),
      ) ??
      Settings.fallbackStopDuration;

  /// Caminho de CALLBACK (idiom Riverpod — `read`, não `watch`, fora do build):
  /// usado por [_openTimeAtStop]. `watch` num event handler cria subscription
  /// órfã e é anti-pattern (achado da auditoria pré-merge MS-A6).
  Duration _readGlobalStopDuration() =>
      ref.read(
        settingsControllerProvider
            .select((async) => async.value?.defaultStopDuration),
      ) ??
      Settings.fallbackStopDuration;

  /// Formato curto de Duration (jadx UiFormatters.m8453f): partes não-zero
  /// h/min/s juntadas por ' '; zero → '0 min'.
  static String _formatDuration(Duration d) {
    if (d == Duration.zero) return '0 min';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    final parts = <String>[
      if (h > 0) '$h h',
      if (m > 0) '$m min',
      if (s > 0) '$s s',
    ];
    return parts.join(' ');
  }

  /// Row 'Tempo na parada' (F9): override → duração formatada; herdando →
  /// 'Padrão (`<default global>`)' (default_brackets_value).
  String _formatTimeAtStop(Stop stop) {
    final override = stop.estimatedTimeAtStop;
    if (override != null) return _formatDuration(override);
    return 'Padrão (${_formatDuration(_watchGlobalStopDuration)})';
  }

  /// Tempo na parada (F9/H14): dialog min+seg commit-on-dismiss; o record
  /// retornado é o novo override (duration: null = herda o default global).
  Future<void> _openTimeAtStop(Stop stop) async {
    final result = await TimeAtStopDialog.show(
      context,
      current: stop.estimatedTimeAtStop,
      defaultDuration: _readGlobalStopDuration(),
    );
    if (result == null || !mounted) return;
    ref.read(routesProvider.notifier).updateStop(
          widget.routeId,
          stop.copyWith(estimatedTimeAtStop: result.duration),
        );
  }

  /// Row 'Localizador de pacotes' (F11): componentes definidos juntados por
  /// ', ' na ordem dimensão, tipo, Y, X, Z; nada definido → 'Não definido'.
  String _formatFinder(Stop stop) {
    final details = stop.packageDetails;
    final place = stop.placeInVehicle;
    final parts = <String>[
      if (details?.dimension != null)
        switch (details!.dimension!) {
          PackageDimension.small => 'Pequeno',
          PackageDimension.medium => 'Médio',
          PackageDimension.large => 'Grande',
        },
      if (details?.type != null)
        switch (details!.type!) {
          PackageType.box => 'Caixa',
          PackageType.bag => 'Sacola',
          PackageType.letter => 'Carta',
        },
      if (place?.y != null)
        switch (place!.y!) {
          PlaceY.front => 'Frente',
          PlaceY.middle => 'Meio',
          PlaceY.back => 'Atrás',
        },
      if (place?.x != null)
        switch (place!.x!) {
          PlaceX.left => 'Esquerda',
          PlaceX.right => 'Direita',
        },
      if (place?.z != null)
        switch (place!.z!) {
          PlaceZ.floor => 'Chão',
          PlaceZ.shelf => 'Prateleira',
        },
    ];
    return parts.isEmpty ? 'Não definido' : parts.join(', ');
  }

  /// Localizador de pacotes (F11/H13): sheet inline; record popado é o novo
  /// estado completo (null explícito limpa via copyWith _omit).
  Future<void> _openPackageFinder(Stop stop) async {
    final result = await PackageFinderSheet.show(
      context,
      initialDetails: stop.packageDetails,
      initialPlace: stop.placeInVehicle,
      deliveryId: stop.deliveryId,
    );
    if (result == null || !mounted) return;
    ref.read(routesProvider.notifier).updateStop(
          widget.routeId,
          stop.copyWith(
            packageDetails: result.details,
            placeInVehicle: result.place,
          ),
        );
  }

  /// Mudar endereço (T17/H10): pusha o sub-picker aninhado (AddStopPage em
  /// PickerMode.changeAddress) e, ao receber o record, troca SÓ os 4 campos
  /// de endereço do Stop — todos os demais campos preservados. Path absoluto
  /// (não deriva da uri atual: `?new=1` corromperia o push relativo).
  Future<void> _openChangeAddress(Stop stop) async {
    final result = await context.push<Object?>(
      '/home/routes/active/${widget.routeId}/stops/${widget.stopId}'
      '/edit/change-address',
    );
    if (!mounted) return;
    if (result
        case (
          lat: final double lat,
          lng: final double lng,
          streetName: final String streetName,
          fullAddress: final String fullAddress,
        )) {
      ref.read(routesProvider.notifier).updateStop(
            widget.routeId,
            stop.copyWith(
              lat: lat,
              lng: lng,
              streetName: streetName,
              fullAddress: fullAddress,
            ),
          );
    }
  }

  /// Duplicar parada (F5/H11): duplicateStop IMEDIATO (sem dialog) e
  /// pushReplacement do editor da duplicata com ?new=1 — back da duplicata
  /// volta pra lista/home, não pro editor da original.
  void _duplicateStop() {
    final newId = ref
        .read(routesProvider.notifier)
        .duplicateStop(widget.routeId, widget.stopId);
    if (newId == null) return;
    context.pushReplacement(
      '/home/routes/active/${widget.routeId}/stops/$newId/edit?new=1',
    );
  }

  /// Remover parada (F6). Dois caminhos por ESTADO da rota (paridade Spoke,
  /// Á7 G5):
  ///   - Rota OTIMIZADA (PRE-CONFIRM): remoção DEFERIDA — confirma via
  ///     `ConfirmDeferredRemovalDialog`, marca `pendingRemoval` e NÃO faz pop;
  ///     a parada fica na lista até a próxima otimização (o solver a exclui).
  ///   - Rota DRAFT: remoção IMEDIATA (`removeStop` + pop do editor — Área 6).
  /// O Spoke ramifica em `StopActionsController.onDeleteStopClick` por
  /// `optimization == OPTIMIZED`.
  Future<void> _confirmRemove(Stop stop) async {
    final route = ref
        .read(routesProvider)
        .where((r) => r.id == widget.routeId)
        .firstOrNull;
    final isOptimized =
        route?.routeState.optimization == OptimizationState.optimized;

    if (isOptimized) {
      final confirmed = await showConfirmDeferredRemovalDialog(
        context,
        stopLabel: stop.deliveryId ?? stop.streetName,
      );
      if (confirmed != true || !mounted) return;
      ref
          .read(routesProvider.notifier)
          .markStopForDeferredRemoval(widget.routeId, stop.id);
      // Sem pop: a parada permanece visível marcada — sai na próxima
      // otimização. (Se o produto preferir popar e mostrar a parada riscada na
      // lista do shell, é uma decisão de UX do PR-B2 — aqui ficamos no editor.)
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.bg,
        title: const Text(
          'Remover parada',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        content: Text(
          'Quer mesmo remover "${stop.streetName}" da rota?',
          style: const TextStyle(fontSize: 14, color: AppColors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Remover',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ref.read(routesProvider.notifier).removeStop(widget.routeId, stop.id);
    if (mounted && context.canPop()) context.pop();
  }

  /// Chip de cor → ColorPickerSheet; commit-on-dismiss live via updateStop
  /// (F3). Dismiss sem ação → nenhuma mudança.
  Future<void> _pickColor(Stop stop) async {
    final result = await ColorPickerSheet.show(context, current: stop.color);
    if (!mounted) return;
    switch (result) {
      case ColorPicked(:final color):
        ref
            .read(routesProvider.notifier)
            .updateStop(widget.routeId, stop.copyWith(color: color));
      case ColorCleared():
        ref
            .read(routesProvider.notifier)
            .updateStop(widget.routeId, stop.copyWith(color: null));
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observa a parada por id — mutações externas (updateStop/removeStop)
    // re-renderizam a página (F3: as sub-surfaces escrevem no provider e a
    // página reflete).
    final stop = ref.watch(
      routesProvider.select(
        (routes) => routes
            .where((r) => r.id == widget.routeId)
            .firstOrNull
            ?.stops
            .where((s) => s.id == widget.stopId)
            .firstOrNull,
      ),
    );

    if (stop == null) {
      if (!_popScheduled) {
        _popScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.canPop()) context.pop();
        });
      }
      return const Scaffold(backgroundColor: AppColors.bg, body: SizedBox());
    }

    // Configs construídos numa lista local; o ListView.builder abaixo adia a
    // INFLAÇÃO dos elementos fora da viewport (perf audit MS-A6, checklist
    // §1 — construir o config é barato, inflar/layoutar não).
    final rows = <Widget>[
      _buildChipsRow(stop),
      const SizedBox(height: 12),
      _buildAddressCard(stop),
      const SizedBox(height: 8),
      _buildAccessInstructionsButton(stop),
      const SizedBox(height: 16),
      StopNotesSection(routeId: widget.routeId, stop: stop),
      const SizedBox(height: 16),
      _EditStopRow(
        semanticsId: 'edit_stop_finder',
        icon: LucideIcons.packageSearch,
        label: 'Localizador de pacotes',
        value: _formatFinder(stop),
        onTap: () => _openPackageFinder(stop),
      ),
      PackageCountRow(
        count: stop.packagesCount,
        onChanged: (v) => ref.read(routesProvider.notifier).updateStop(
              widget.routeId,
              stop.copyWith(packagesCount: v),
            ),
      ),
      _SegmentedRow<StopOrderPolicy>(
        semanticsId: 'edit_stop_order',
        icon: LucideIcons.listOrdered,
        label: 'Ordem',
        segments: const [
          ButtonSegment(
            value: StopOrderPolicy.first,
            label: Text('Primeira'),
          ),
          ButtonSegment(
            value: StopOrderPolicy.auto,
            label: Text('Automática'),
          ),
          ButtonSegment(
            value: StopOrderPolicy.last,
            label: Text('Última'),
          ),
        ],
        selected: stop.orderPolicy,
        onChanged: (policy) => ref.read(routesProvider.notifier).updateStop(
              widget.routeId,
              stop.copyWith(orderPolicy: policy),
            ),
      ),
      _SegmentedRow<StopType>(
        semanticsId: 'edit_stop_type',
        icon: LucideIcons.tag,
        label: 'Tipo',
        segments: const [
          ButtonSegment(
            value: StopType.delivery,
            label: Text('Entrega'),
          ),
          ButtonSegment(
            value: StopType.pickup,
            label: Text('Coleta'),
          ),
        ],
        selected: stop.type,
        onChanged: (type) => ref.read(routesProvider.notifier).updateStop(
              widget.routeId,
              stop.copyWith(type: type),
            ),
      ),
      _EditStopRow(
        semanticsId: 'edit_stop_window',
        icon: LucideIcons.clock,
        label: 'Horário de chegada',
        value: _formatWindow(stop),
        onTap: () => _openArrivalWindow(stop),
      ),
      _EditStopRow(
        semanticsId: 'edit_stop_duration',
        icon: LucideIcons.timer,
        label: 'Tempo na parada',
        value: _formatTimeAtStop(stop),
        onTap: () => _openTimeAtStop(stop),
      ),
      const SizedBox(height: 16),
      const Divider(height: 1, color: AppColors.border),
      const SizedBox(height: 8),
      _ActionRow(
        semanticsId: 'edit_stop_change_address',
        icon: LucideIcons.mapPin,
        label: 'Mudar endereço',
        onTap: () => _openChangeAddress(stop),
      ),
      _ActionRow(
        semanticsId: 'edit_stop_duplicate',
        icon: LucideIcons.copy,
        label: 'Duplicar parada',
        onTap: _duplicateStop,
      ),
      _ActionRow(
        semanticsId: 'edit_stop_remove',
        icon: LucideIcons.trash2,
        label: 'Remover parada',
        color: AppColors.error,
        onTap: () => _confirmRemove(stop),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                itemCount: rows.length,
                itemBuilder: (_, index) => rows[index],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header custom (sem AppBar — idiom Á5): Ajuda à esquerda (stub D7),
  /// título central (+ badge "Adicionada" quando `?new=1`), "Concluído" à
  /// direita — que APENAS fecha (F3).
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
      child: Row(
        children: [
          Semantics(
            identifier: 'edit_stop_help',
            button: true,
            child: IconButton(
              icon: const Icon(
                LucideIcons.circleHelp,
                color: AppColors.textMuted,
                size: 22,
              ),
              onPressed: () => _stub('Ajuda'),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Flexible(
                  child: Text(
                    'Editar parada',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                ),
                if (widget.showAddedBadge) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Adicionada',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Semantics(
            identifier: 'edit_stop_done',
            button: true,
            child: TextButton(
              onPressed: () => context.pop(),
              child: const Text(
                'Concluído',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Chips de cor (T10) e ID (D7 — tela "Formato do ID" pertence à Á10).
  Widget _buildChipsRow(Stop stop) {
    return Row(
      children: [
        Semantics(
          identifier: 'edit_stop_color_chip',
          button: true,
          child: InkWell(
            onTap: () => _pickColor(stop),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (stop.color == null)
                    const Icon(
                      LucideIcons.palette,
                      size: 16,
                      color: AppColors.textMuted,
                    )
                  else
                    Container(
                      key: const Key('edit_stop_color_chip_dot'),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stopColorToken(stop.color!),
                      ),
                    ),
                  const SizedBox(width: 6),
                  const Text(
                    'Cor',
                    style: TextStyle(fontSize: 13, color: AppColors.text),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          identifier: 'edit_stop_id_chip',
          button: true,
          child: InkWell(
            onTap: () => _stub('ID de parada'),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                stop.deliveryId ?? 'Pendente',
                style: const TextStyle(fontSize: 13, color: AppColors.text),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Card endereço read-only: rua (h6) + endereço completo (muted).
  Widget _buildAddressCard(Stop stop) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
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
          ),
          const SizedBox(height: 3),
          Text(
            stop.fullAddress,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessInstructionsButton(Stop stop) {
    return Semantics(
      identifier: 'edit_stop_access_instructions',
      button: true,
      child: InkWell(
        onTap: () => _openAccessInstructions(stop),
        borderRadius: BorderRadius.circular(10),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(
                LucideIcons.pencil,
                size: 16,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'Instruções de acesso',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row padrão do editor: ícone + label + valor atual (muted) + chevron.
class _EditStopRow extends StatelessWidget {
  const _EditStopRow({
    required this.semanticsId,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String semanticsId;
  final IconData icon;
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textMuted),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 15, color: AppColors.text),
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row de ação do rodapé (Mudar endereço / Duplicar / Remover).
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.semanticsId,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final String semanticsId;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effective = color ?? AppColors.text;
    return Semantics(
      identifier: semanticsId,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 13),
          child: Row(
            children: [
              Icon(icon, size: 20, color: effective),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: effective,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Row com label à esquerda e `SegmentedButton` à direita (F16/H21 — §10.6:
/// no Spoke o segmented ocupa a metade direita da row). Single-select,
/// sempre habilitado (§13.C.1); mudança aplica live via [onChanged] (F3).
class _SegmentedRow<T> extends StatelessWidget {
  const _SegmentedRow({
    required this.semanticsId,
    required this.icon,
    required this.label,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final String semanticsId;
  final IconData icon;
  final String label;
  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: AppColors.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            // FittedBox: encolhe o segmented quando o espaço aperta (fonte de
            // teste Ahem é mais larga que a de produção) em vez de estourar.
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Semantics(
                identifier: semanticsId,
                child: SegmentedButton<T>(
                  segments: segments,
                  selected: {selected},
                  // H21: Spoke não mostra check no segment selecionado.
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    backgroundColor: AppColors.surface,
                    selectedForegroundColor: Colors.white,
                    selectedBackgroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onSelectionChanged: (selection) => onChanged(selection.first),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
