import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'package:roteirizador_pro/core/services/external_nav.dart';
import 'package:roteirizador_pro/features/settings/presentation/settings_page.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('SettingsPage renders all four sections + Sair CTA',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsPage())),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('NAVEGAÇÃO'), findsOneWidget);
    expect(find.textContaining('ENDEREÇO DE CASA'), findsOneWidget);
    expect(find.textContaining('PAGAMENTOS'), findsOneWidget);
    expect(find.textContaining('CONTA'), findsOneWidget);
    expect(find.text('Sair da conta'), findsOneWidget);
    expect(find.text('Waze'), findsOneWidget);
    expect(find.text('Google Maps'), findsOneWidget);
  });

  testWidgets('Default selection is Waze when no pref stored', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsPage())),
    );
    await tester.pumpAndSettle();

    final segmented = tester.widget<SegmentedButton<NavProvider>>(
      find.byType(SegmentedButton<NavProvider>),
    );
    expect(segmented.selected, {NavProvider.waze});
  });

  testWidgets('Toggling to Google Maps persists enum.name to pref key',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsPage())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Google Maps'));
    await tester.pumpAndSettle();

    final stored =
        await SharedPreferencesAsync().getString(kNavProviderPrefKey);
    expect(stored, NavProvider.googleMaps.name);
  });

  testWidgets('Settings page rehydrates the stored selection on mount',
      (tester) async {
    // Pre-seed the pref as googleMaps.
    await SharedPreferencesAsync().setString(
      kNavProviderPrefKey,
      NavProvider.googleMaps.name,
    );

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsPage())),
    );
    await tester.pumpAndSettle();

    final segmented = tester.widget<SegmentedButton<NavProvider>>(
      find.byType(SegmentedButton<NavProvider>),
    );
    expect(segmented.selected, {NavProvider.googleMaps});
  });
}
