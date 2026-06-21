// Pós-ADR-0052: o kebab "Opções da rota" deixou de ser um botão solto DENTRO da
// PreConfirmView e voltou para a barra de busca da moldura compartilhada do
// shell (_SheetSearchRow), mantida nos 3 estados (fiel ao Spoke). A presença do
// kebab no estado otimizado é verificada no shell montado em PRE-CONFIRM —
// confirma o item #3 do refactor (busca + kebab preservados, não kebab solto).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/routes/domain/optimization_state.dart';
import 'package:roteirizador_pro/features/routes/domain/route.dart' as domain;
import 'package:roteirizador_pro/features/routes/domain/route_state.dart';
import 'package:roteirizador_pro/features/routes/domain/stop.dart' as domain;
import 'package:roteirizador_pro/features/routes/presentation/route_shell_page.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/pre_confirm_view.dart';
import 'package:roteirizador_pro/features/routes/state/active_route_provider.dart';
import 'package:roteirizador_pro/features/routes/state/current_user_provider.dart';
import 'package:roteirizador_pro/features/routes/state/routes_provider.dart';

import '../../_helpers/fake_current_user.dart';
import '../../../../_helpers/shared_prefs_async.dart';

class _SeededActiveRouteId extends ActiveRouteId {
  _SeededActiveRouteId(this._seed);
  final String _seed;
  @override
  String? build() => _seed;
}

domain.Stop _stop(String id) => domain.Stop(
      id: id,
      lat: -23.5,
      lng: -46.6,
      streetName: 'Rua $id',
      fullAddress: 'Rua $id, 1',
      deliveryId: 'A1',
    );

void main() {
  useInMemorySharedPreferencesAsync();

  testWidgets(
      'no estado otimizado (PRE-CONFIRM) a barra de busca do shell mantém o '
      'kebab "Opções da rota" (não kebab solto na view)', (tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const preConfirmState = RouteState(
      optimization: OptimizationState.optimized,
      confirmed: false,
      started: false,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(kUserWithoutSub),
          routesProvider.overrideWithValue([
            domain.Route(
              id: 'r-pc',
              date: DateTime(2026, 5, 27),
              routeState: preConfirmState,
              stops: [_stop('a')],
            ),
          ]),
          activeRouteIdProvider
              .overrideWith(() => _SeededActiveRouteId('r-pc')),
        ],
        child: MaterialApp(
          theme:
              AppTheme.light().copyWith(splashFactory: NoSplash.splashFactory),
          home: const RouteShellPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // PreConfirmView (body) está na árvore...
    expect(find.byType(PreConfirmView), findsOneWidget);
    // ...e o kebab vive na barra de busca da moldura (não solto na view).
    expect(find.bySemanticsLabel('Opções da rota'), findsOneWidget);
    // A barra de busca permanece no estado otimizado.
    expect(find.text('Adicionar parada...'), findsOneWidget);
  });
}
