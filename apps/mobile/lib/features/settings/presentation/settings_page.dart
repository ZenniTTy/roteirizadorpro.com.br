import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Placeholder Settings screen for the home BottomNav target.
///
/// The real ScreenSettings (per prototipo/screens-b.jsx:347) lands in
/// Task 33 of the slice 2 plan and brings the nav-provider toggle, home
/// address, paywall section, and Sair da conta. This stub is here so the
/// BottomNav "Configurações" tab has somewhere to go without 404-ing the
/// user in the meantime.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.settings_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Em breve',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'A tela de Configurações chega no próximo update.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
