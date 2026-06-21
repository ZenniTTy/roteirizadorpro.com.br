import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/core/theme/app_theme.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_step_list.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('RouteStopStep', () {
    testWidgets('DRAFT (sem posição/ETA) → círculo vazio, sem número nem hora',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const RouteStopStep(
            streetName: 'Rua A',
            fullAddress: 'Rua A, 100',
            statusColor: AppColors.textMuted,
          ),
        ),
      );
      expect(find.text('Rua A'), findsOneWidget);
      expect(find.text('Rua A, 100'), findsOneWidget);
      // Nenhum número de posição nem hora de chegada em DRAFT.
      expect(find.text('1'), findsNothing);
      expect(find.textContaining(':'), findsNothing);
    });

    testWidgets('otimizada → número + ETA coexistem (TimeAndStopNumber)',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const RouteStopStep(
            streetName: 'Rua B',
            fullAddress: 'Rua B, 200',
            statusColor: AppColors.success,
            position: 2,
            etaTime: '14:32',
          ),
        ),
      );
      // Zero-pad 2 dígitos (Spoke v3.65.1: o disco mostra "02", não "2").
      expect(find.text('02'), findsOneWidget);
      expect(find.text('14:32'), findsOneWidget);
    });

    testWidgets('toque dispara onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(
          RouteStopStep(
            streetName: 'Rua C',
            fullAddress: 'Rua C, 300',
            statusColor: AppColors.textMuted,
            position: 1,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.tap(find.text('Rua C'));
      expect(tapped, isTrue);
    });
  });

  test('formatEta formata HH:mm 24h com zero-pad', () {
    expect(formatEta(DateTime(2026, 6, 21, 9, 5)), '09:05');
    expect(formatEta(DateTime(2026, 6, 21, 14, 32)), '14:32');
  });
}
