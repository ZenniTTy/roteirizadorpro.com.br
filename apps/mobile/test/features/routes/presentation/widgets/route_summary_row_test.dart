import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roteirizador_pro/features/routes/presentation/widgets/route_summary_row.dart';

void main() {
  testWidgets('formata "Xh Ymin · N paradas · Z,Z km"', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: RouteSummaryRow(
            durationMinutes: 75, stopsCount: 12, distanceMeters: 5200),
      ),
    ));
    expect(find.textContaining('1h 15min'), findsOneWidget);
    expect(find.textContaining('12 paradas'), findsOneWidget);
    expect(find.textContaining('5,2 km'), findsOneWidget);
  });

  testWidgets('< 60 min mostra só minutos; 1 parada é singular',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: RouteSummaryRow(
            durationMinutes: 18, stopsCount: 1, distanceMeters: 800),
      ),
    ));
    expect(find.textContaining('18 min'), findsOneWidget);
    expect(find.textContaining('1 parada'), findsOneWidget);
    expect(find.textContaining('paradas'), findsNothing);
  });

  testWidgets('é display puro — sem InkWell/GestureDetector (G4)',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: RouteSummaryRow(
            durationMinutes: 18, stopsCount: 2, distanceMeters: 800),
      ),
    ));
    expect(find.byType(InkWell), findsNothing);
    expect(find.byType(GestureDetector), findsNothing);
  });
}
