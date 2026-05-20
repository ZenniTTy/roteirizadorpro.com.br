import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/external_nav.dart';
import '../../auth/state/auth_controller.dart';
import '../../stops/presentation/shared/home_bottom_nav.dart';

/// Replaces the placeholder from `bb71d16`. Per `prototipo/screens-b.jsx:347-391`
/// Settings is part of the home family (HomeBottomNav with the
/// `settings` tab active), holds the nav-provider toggle that
/// `OptimizeRoutePage` reads via `kNavProviderPrefKey`, and stubs
/// future-slice rows (Endereço de casa for slice 5, Pagamentos for
/// slice 4). Sair fires the existing slice-1 `AuthController.signOut`.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key, this.onSignedOut});

  /// Callback injection for widget tests; production routing happens via
  /// GoRouter's auth listener that catches the AuthController going
  /// `AsyncData(null)`.
  final void Function(BuildContext context)? onSignedOut;

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  NavProvider _selected = NavProvider.waze; // ADR-0017: Waze default.

  @override
  void initState() {
    super.initState();
    _hydrate();
  }

  Future<void> _hydrate() async {
    final raw = await SharedPreferencesAsync().getString(kNavProviderPrefKey);
    if (!mounted) return;
    setState(() {
      _selected = raw == NavProvider.googleMaps.name
          ? NavProvider.googleMaps
          : NavProvider.waze;
    });
  }

  Future<void> _select(NavProvider p) async {
    setState(() => _selected = p);
    await SharedPreferencesAsync().setString(kNavProviderPrefKey, p.name);
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    (widget.onSignedOut ?? (ctx) => ctx.go('/login'))(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      bottomNavigationBar: const HomeBottomNav(active: HomeNavTab.settings),
      body: SafeArea(
        child: ListView(
          children: [
            const _SectionHeader('Aplicativo de navegação'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SegmentedButton<NavProvider>(
                segments: const [
                  ButtonSegment(
                    value: NavProvider.waze,
                    label: Text('Waze'),
                    icon: Icon(Icons.directions),
                  ),
                  ButtonSegment(
                    value: NavProvider.googleMaps,
                    label: Text('Google Maps'),
                    icon: Icon(Icons.map_outlined),
                  ),
                ],
                selected: {_selected},
                onSelectionChanged: (s) => _select(s.first),
              ),
            ),
            const Divider(height: 32),
            const _SectionHeader('Endereço de casa'),
            const ListTile(
              leading: Icon(Icons.home_outlined),
              title: Text('Configurar — em breve'),
              subtitle: Text('Disponível no slice 5 (Sentido casa)'),
              enabled: false,
            ),
            const Divider(height: 32),
            const _SectionHeader('Indicações'),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Indicar para um amigo'),
              subtitle: const Text('Compartilhe sua rota com outros motoboys'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go('/share'),
            ),
            const Divider(height: 32),
            const _SectionHeader('Pagamentos'),
            const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Pix Split — em breve'),
              subtitle: Text('Disponível no slice 4 (Paywall)'),
              enabled: false,
            ),
            const Divider(height: 32),
            const _SectionHeader('Conta'),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Sair da conta',
                style:
                    TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
