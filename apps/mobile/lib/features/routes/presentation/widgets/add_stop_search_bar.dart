import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import '../../state/place_autocomplete_provider.dart';
import '../../state/search_query_provider.dart';

class AddStopSearchBar extends ConsumerStatefulWidget {
  const AddStopSearchBar({super.key, this.hintText});

  /// Placeholder shown inside the input. Defaults to the legacy add-stop
  /// copy when null so existing call sites are unaffected. The Partida /
  /// Destino sub-pickers pass their own per-[PickerMode] text.
  final String? hintText;

  @override
  ConsumerState<AddStopSearchBar> createState() => _AddStopSearchBarState();
}

class _AddStopSearchBarState extends ConsumerState<AddStopSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onShowStub(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature em breve...')),
    );
  }

  void _onClear() {
    _controller.clear();
    ref.read(searchQueryProvider.notifier).setQuery('');
    ref.read(placeAutocompleteProvider.notifier).search('');
  }

  @override
  Widget build(BuildContext context) {
    // Spoke parity §11.4 amendment 3: OCR + Voice icons disappear when the
    // user is actively typing — visual cue that secondary methods are not
    // needed in "typing mode".
    final query = ref.watch(searchQueryProvider);
    final showShortcuts = query.isEmpty;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText:
                            widget.hintText ?? 'Digite o endereço da parada',
                        hintStyle: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).setQuery(val);
                        ref
                            .read(placeAutocompleteProvider.notifier)
                            .search(val);
                      },
                    ),
                  ),
                  if (showShortcuts) ...[
                    IconButton(
                      icon: const Icon(
                        LucideIcons.scanLine,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => _onShowStub('Ler etiqueta de endereço'),
                      tooltip: 'Ler etiqueta de endereço',
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.mic,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      onPressed: () => _onShowStub('Dite o endereço'),
                      tooltip: 'Dite o endereço',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(LucideIcons.x, color: AppColors.text),
            onPressed: _onClear,
            tooltip: 'Limpar',
          ),
        ],
      ),
    );
  }
}
