import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../domain/route.dart' as rp_route;
import '../state/routes_provider.dart';

class ReuseStopsPage extends ConsumerStatefulWidget {
  const ReuseStopsPage({super.key});

  @override
  ConsumerState<ReuseStopsPage> createState() => _ReuseStopsPageState();
}

class _ReuseStopsPageState extends ConsumerState<ReuseStopsPage> {
  rp_route.Route? _selectedRoute;
  bool _pending = true;
  bool _skipped = true;
  bool _done = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDefaultRoute();
    });
  }

  void _initDefaultRoute() {
    final routes = ref.read(routesProvider);
    // Em produção, deve-se excluir a rota "atual/draft" sendo criada
    if (routes.isNotEmpty) {
      setState(() {
        _selectedRoute = routes.first;
      });
    }
  }

  void _showRoutePicker() {
    final routes = ref.read(routesProvider);
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Selecione uma rota',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: routes.length,
                    itemBuilder: (context, index) {
                      final r = routes[index];
                      // Display de "Quarta-feira Rota 1" etc
                      return ListTile(
                        title: Text(
                          r.displayName(),
                          style: const TextStyle(color: AppColors.text),
                        ),
                        subtitle: Text(
                          _formatDate(r.date),
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedRoute = r;
                          });
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final canCopy = _selectedRoute != null && (_pending || _skipped || _done);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Reutilizar paradas',
          style: TextStyle(
              color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Picker header
          GestureDetector(
            onTap: _showRoutePicker,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Text('De: ',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 16)),
                  Expanded(
                    child: Text(
                      _selectedRoute != null
                          ? '${_formatDate(_selectedRoute!.date)} - ${_selectedRoute!.displayName()}'
                          : 'Selecione uma rota...',
                      style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(LucideIcons.chevronDown,
                      color: AppColors.textMuted),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView(
              children: [
                _buildCategoryTile(
                  title: 'Paradas não realizadas',
                  icon: LucideIcons.circleDashed,
                  checked: _pending,
                  onChanged: (val) => setState(() => _pending = val ?? false),
                  emptyText: 'Nenhuma parada não realizada nesta rota.',
                ),
                _buildCategoryTile(
                  title: 'Paradas puladas',
                  icon: LucideIcons.skipForward,
                  checked: _skipped,
                  onChanged: (val) => setState(() => _skipped = val ?? false),
                  emptyText: 'Nenhuma parada pulada nesta rota.',
                ),
                _buildCategoryTile(
                  title: 'Paradas feitas',
                  icon: LucideIcons.checkCircle,
                  checked: _done,
                  onChanged: (val) => setState(() => _done = val ?? false),
                  emptyText: 'Nenhuma parada feita nesta rota.',
                ),
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.surface,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: canCopy
                      ? () {
                          // Simular cópia
                          showAppSnackBar(
                            context,
                            'Paradas copiadas com sucesso! (Simulação)',
                          );
                          context.go('/home');
                        }
                      : null,
                  child: Text(
                    'Copiar paradas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: canCopy ? Colors.white : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile({
    required String title,
    required IconData icon,
    required bool checked,
    required ValueChanged<bool?> onChanged,
    required String emptyText,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: Checkbox(
          value: checked,
          onChanged: onChanged,
          activeColor: AppColors.neon,
          checkColor: AppColors.neonInk,
        ),
        title: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textMuted),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(color: AppColors.text, fontSize: 16)),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(emptyText,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
