import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/stops_controller.dart';
import 'home_empty_page.dart';
import 'home_list_page.dart';

class HomeListPageOrEmpty extends ConsumerWidget {
  const HomeListPageOrEmpty({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stops = ref.watch(stopsControllerProvider);
    return stops.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) {
        debugPrint('HomeListPageOrEmpty stops error: $e');
        return const Scaffold(
          body: Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Não conseguimos carregar suas paradas. Tente reabrir o app.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
      data: (s) => s.isEmpty ? const HomeEmptyPage() : const HomeListPage(),
    );
  }
}
