import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/package_details.dart';
import '../../domain/place_in_vehicle.dart';

/// Tipo de retorno normalizado do [PackageFinderSheet].
///
/// - `details`: dimensão + tipo do pacote. null quando todos os chips de
///   descrição estão desmarcados.
/// - `place`: localização no veículo (Y/X/Z). null quando todos os eixos
///   estão desmarcados.
typedef PackageFinderSelection = ({
  PackageDetails? details,
  PlaceInVehicle? place,
});

/// Sheet bottom modal do localizador de pacotes (F11/H13 — MS-A6 T16).
///
/// Header: [TextButton 'Limpar' | 'Localizador de pacotes' |
/// TextButton 'Concluído'] — idiom ColorPickerSheet/ArrivalWindowSheet.
///
/// Seções (tudo INLINE na mesma sheet — H13, sem sub-navegação):
///   - ID de parada: display-only (deliveryId ?? 'Pendente').
///   - 'Descrição do pacote': chip-group dimensão (Pequeno/Médio/Grande) +
///     chip-group tipo (Caixa/Sacola/Carta). Single-select; tap no chip já
///     selecionado desseleciona (componente volta a null).
///   - 'Lugar no veículo': 3 chip-rows: Y Frente/Meio/Atrás; X Esquerda/
///     Direita (microcopy nossa corrige o typo 'Direta' do dump);
///     Z Chão/Prateleira. Mesmo toggle.
///
/// Semantics H19: cada chip com identifier `finder_chip_<enumName>`.
///
/// Retorno:
///   - 'Concluído' → `(details: ..., place: ...)` normalizado (VO com todos
///     os componentes null → null no record).
///   - 'Limpar' → `(details: null, place: null)`.
///   - Barrier dismiss → null (cancel).
class PackageFinderSheet extends StatefulWidget {
  const PackageFinderSheet({
    super.key,
    this.initialDetails,
    this.initialPlace,
    this.deliveryId,
  });

  final PackageDetails? initialDetails;
  final PlaceInVehicle? initialPlace;
  final String? deliveryId;

  /// Abre via showModalBottomSheet(useRootNavigator: true, useSafeArea: true,
  /// isScrollControlled: true) — H13.
  static Future<PackageFinderSelection?> show(
    BuildContext context, {
    PackageDetails? initialDetails,
    PlaceInVehicle? initialPlace,
    String? deliveryId,
  }) {
    return showModalBottomSheet<PackageFinderSelection>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PackageFinderSheet(
        initialDetails: initialDetails,
        initialPlace: initialPlace,
        deliveryId: deliveryId,
      ),
    );
  }

  @override
  State<PackageFinderSheet> createState() => _PackageFinderSheetState();
}

class _PackageFinderSheetState extends State<PackageFinderSheet> {
  PackageDimension? _dimension;
  PackageType? _type;
  PlaceX? _x;
  PlaceY? _y;
  PlaceZ? _z;

  @override
  void initState() {
    super.initState();
    _dimension = widget.initialDetails?.dimension;
    _type = widget.initialDetails?.type;
    _x = widget.initialPlace?.x;
    _y = widget.initialPlace?.y;
    _z = widget.initialPlace?.z;
  }

  /// Normaliza: VO com todos os componentes null vira null no record.
  PackageFinderSelection _normalized() => (
        details: _dimension == null && _type == null
            ? null
            : PackageDetails(dimension: _dimension, type: _type),
        place: _x == null && _y == null && _z == null
            ? null
            : PlaceInVehicle(x: _x, y: _y, z: _z),
      );

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pop<PackageFinderSelection>(
                      (details: null, place: null),
                    ),
                    child: const Text(
                      'Limpar',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 14),
                    ),
                  ),
                  const Flexible(
                    child: Text(
                      'Localizador de pacotes',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context)
                        .pop<PackageFinderSelection>(_normalized()),
                    child: const Text(
                      'Concluído',
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'ID de parada',
                        style: TextStyle(fontSize: 15, color: AppColors.text),
                      ),
                    ),
                    Text(
                      widget.deliveryId ?? 'Pendente',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              _sectionTitle('Descrição do pacote'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in PackageDimension.values)
                    _FinderChip(
                      semanticsId: 'finder_chip_${d.name}',
                      label: switch (d) {
                        PackageDimension.small => 'Pequeno',
                        PackageDimension.medium => 'Médio',
                        PackageDimension.large => 'Grande',
                      },
                      selected: _dimension == d,
                      onTap: () => setState(
                        () => _dimension = _dimension == d ? null : d,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in PackageType.values)
                    _FinderChip(
                      semanticsId: 'finder_chip_${t.name}',
                      label: switch (t) {
                        PackageType.box => 'Caixa',
                        PackageType.bag => 'Sacola',
                        PackageType.letter => 'Carta',
                      },
                      selected: _type == t,
                      onTap: () => setState(
                        () => _type = _type == t ? null : t,
                      ),
                    ),
                ],
              ),
              _sectionTitle('Lugar no veículo'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final y in PlaceY.values)
                    _FinderChip(
                      semanticsId: 'finder_chip_${y.name}',
                      label: switch (y) {
                        PlaceY.front => 'Frente',
                        PlaceY.middle => 'Meio',
                        PlaceY.back => 'Atrás',
                      },
                      selected: _y == y,
                      onTap: () => setState(() => _y = _y == y ? null : y),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final x in PlaceX.values)
                    _FinderChip(
                      semanticsId: 'finder_chip_${x.name}',
                      label: switch (x) {
                        PlaceX.left => 'Esquerda',
                        PlaceX.right => 'Direita',
                      },
                      selected: _x == x,
                      onTap: () => setState(() => _x = _x == x ? null : x),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final z in PlaceZ.values)
                    _FinderChip(
                      semanticsId: 'finder_chip_${z.name}',
                      label: switch (z) {
                        PlaceZ.floor => 'Chão',
                        PlaceZ.shelf => 'Prateleira',
                      },
                      selected: _z == z,
                      onTap: () => setState(() => _z = _z == z ? null : z),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chip single-select/desselecionável com Semantics identifier (H19).
class _FinderChip extends StatelessWidget {
  const _FinderChip({
    required this.semanticsId,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String semanticsId;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      identifier: semanticsId,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? Colors.white : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}
