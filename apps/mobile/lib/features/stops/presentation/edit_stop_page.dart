import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';
import 'shared/stops_async_view.dart';

class EditStopPage extends ConsumerWidget {
  const EditStopPage({super.key, required this.id, this.onSaved});

  final String id;

  /// Nullable so widget tests can assert taps without standing up a GoRouter;
  /// production falls through to `context.pop()` (or `/home/stops/$id` if the
  /// page was deep-linked).
  final void Function(BuildContext context)? onSaved;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stopsControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: stopsAsyncView(
        async,
        screenTag: 'EditStopPage',
        data: (context, stops) {
          final stop = stops.where((s) => s.id == id).firstOrNull;
          if (stop == null) {
            return Container(
              color: AppColors.bg,
              child: const SafeArea(
                child: Center(child: Text('Parada não encontrada.')),
              ),
            );
          }
          return _EditStopSheet(
            stop: stop,
            onConcluido: () async {
              if (!context.mounted) return;
              (onSaved ??
                  (ctx) => ctx.canPop()
                      ? ctx.pop()
                      : ctx.go('/home/stops/${stop.id}'))(context);
            },
            onChangeAddress: () async {
              final newLabel = await _promptAddress(context, stop.label);
              if (!context.mounted) return;
              if (newLabel == null || newLabel.isEmpty) return;
              final updated = stop.copyWith(label: newLabel);
              await ref
                  .read(stopsControllerProvider.notifier)
                  .updateStop(updated);
            },
          );
        },
      ),
    );
  }

  Future<String?> _promptAddress(BuildContext context, String? initial) {
    return showDialog<String>(
      context: context,
      builder: (_) => _AddressDialog(initial: initial),
    );
  }
}

class _AddressDialog extends StatefulWidget {
  const _AddressDialog({required this.initial});
  final String? initial;

  @override
  State<_AddressDialog> createState() => _AddressDialogState();
}

class _AddressDialogState extends State<_AddressDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mudar endereço'),
      content: TextField(
        controller: _controller,
        key: const Key('input-address'),
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Endereço',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}

class _EditStopSheet extends StatelessWidget {
  const _EditStopSheet({
    required this.stop,
    required this.onConcluido,
    required this.onChangeAddress,
  });

  final Stop stop;
  final VoidCallback onConcluido;
  final VoidCallback onChangeAddress;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.text.withValues(alpha: 0.25),
      alignment: Alignment.bottomCenter,
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x2E6C3FC5),
              blurRadius: 32,
              offset: Offset(0, -8),
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - 80,
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SheetHeader(onConcluido: onConcluido),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _ColorTagPill(),
                        const SizedBox(height: 14),
                        Text(
                          stop.label ?? 'Sem endereço',
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // TODO(slice-3): derive city/postal from geocoding result.
                        const Text(
                          'São Paulo',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // TODO(slice-3): wire gate-code editor flow.
                        _GateCodeButton(onPressed: () {}),
                        const SizedBox(height: 10),
                        const _NoteBlock(
                          text:
                              '"O destinatário não está em casa hoje. Deixe o p..."',
                        ),
                        const SizedBox(height: 16),
                        const _OptionRow(
                          icon: Icons.gps_fixed,
                          label: 'Localizador',
                          trailing: _OptionValueText('Grande, Sacola'),
                        ),
                        const _OptionRow(
                          icon: Icons.inventory_2_outlined,
                          label: 'Pacotes',
                          trailing: _PackageStepper(),
                        ),
                        const _OptionRow(
                          icon: Icons.format_list_numbered,
                          label: 'Ordem',
                          trailing: _SegmentedControl(
                            options: ['Primeira', 'Auto', 'Última'],
                            selected: 'Auto',
                          ),
                        ),
                        const _OptionRow(
                          icon: Icons.local_shipping_outlined,
                          label: 'Tipo',
                          trailing: _SegmentedControl(
                            options: ['Entrega', 'Coleta'],
                            selected: 'Entrega',
                          ),
                        ),
                        const _OptionRow(
                          icon: Icons.access_time_outlined,
                          label: 'Horário de chegada',
                          trailing: _OptionValueMuted('Qualquer momento'),
                        ),
                        const _OptionRow(
                          icon: Icons.timer_outlined,
                          label: 'Tempo na parada',
                          trailing: _OptionValueMuted('5 minutos'),
                          last: true,
                        ),
                        const SizedBox(height: 16),
                        _ActionFooter(onChangeAddress: onChangeAddress),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.onConcluido});
  final VoidCallback onConcluido;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircleIconButton(
                icon: Icons.help_outline,
                onPressed: () {},
                semanticsLabel: 'Ajuda',
              ),
              const Text(
                'Editar parada',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: onConcluido,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.all(4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Concluído',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onPressed,
    required this.semanticsLabel,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Tooltip(
            message: semanticsLabel,
            child: Icon(icon, size: 16, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

class _ColorTagPill extends StatelessWidget {
  const _ColorTagPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ColorDot(color: AppColors.warning),
          SizedBox(width: 8),
          Text(
            'Laranja',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _GateCodeButton extends StatelessWidget {
  const _GateCodeButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: Material(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.key_outlined, size: 16, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'O código do portão é 1684',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoteBlock extends StatelessWidget {
  const _NoteBlock({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final row = Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: last ? Colors.transparent : AppColors.border,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Icon(icon, size: 18, color: AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

class _OptionValueText extends StatelessWidget {
  const _OptionValueText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _OptionValueMuted extends StatelessWidget {
  const _OptionValueMuted(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
    );
  }
}

/// Display-only stepper for the slice-2 structural skeleton.
// TODO(slice-3): wire to a real pkg-count provider; convert _StepperButton
// children to InkWell-tappable buttons.
class _PackageStepper extends StatelessWidget {
  const _PackageStepper();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(label: '−'),
          SizedBox(
            width: 22,
            child: Text(
              '1',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
          _StepperButton(label: '+'),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.6,
        ),
      ),
    );
  }
}

/// Display-only segmented control for the slice-2 structural skeleton.
// TODO(slice-3): add onChanged callback + lift state to a Riverpod provider.
class _SegmentedControl extends StatelessWidget {
  const _SegmentedControl({required this.options, required this.selected});
  final List<String> options;
  final String selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) {
          final active = o == selected;
          return Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: active ? AppColors.bg : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              boxShadow: active
                  ? const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              o,
              style: TextStyle(
                color: active ? AppColors.primary : AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionFooter extends StatelessWidget {
  const _ActionFooter({required this.onChangeAddress});
  final VoidCallback onChangeAddress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _OptionRow(
            icon: Icons.search,
            label: 'Mudar endereço',
            onTap: onChangeAddress,
            trailing: const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textMuted,
            ),
          ),
          // TODO(slice-3): wire onTap to duplicate-stop flow.
          const _OptionRow(
            icon: Icons.copy_outlined,
            label: 'Duplicar parada',
            trailing: Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textMuted,
            ),
            last: true,
          ),
        ],
      ),
    );
  }
}
