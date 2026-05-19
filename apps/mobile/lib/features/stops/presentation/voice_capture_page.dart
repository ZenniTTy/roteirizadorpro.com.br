import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../core/services/id.dart';
import '../../../core/services/permissions.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';

class VoiceCapturePage extends ConsumerStatefulWidget {
  const VoiceCapturePage({super.key, this.onConfirmed});

  /// Nullable so widget tests can assert taps without standing up a GoRouter;
  /// production falls through to `context.go('/home')`.
  final void Function(BuildContext context)? onConfirmed;

  @override
  ConsumerState<VoiceCapturePage> createState() => _VoiceCapturePageState();
}

class _VoiceCapturePageState extends ConsumerState<VoiceCapturePage> {
  final SpeechToText _speech = SpeechToText();
  bool _listening = false;
  String _transcript = '';

  Future<void> _toggleListen() async {
    if (_listening) {
      await _speech.stop();
      if (!mounted) return;
      setState(() => _listening = false);
      return;
    }

    final outcome = await ref.read(appPermissionsProvider).requestMicrophone();
    if (!mounted) return;
    if (outcome != PermissionOutcome.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão do microfone necessária.')),
      );
      return;
    }

    final ok = await _speech.initialize();
    if (!mounted || !ok) return;

    setState(() {
      _listening = true;
      _transcript = '';
    });

    await _speech.listen(
      localeId: 'pt_BR',
      onResult: (result) {
        if (!mounted) return;
        setState(() => _transcript = result.recognizedWords);
      },
    );
  }

  Future<void> _confirm() async {
    final text = _transcript.trim();
    if (text.isEmpty) return;

    final stop = Stop(
      id: newId(),
      lat: 0,
      lng: 0,
      label: text,
      source: StopSource.voice,
      createdAt: DateTime.now(),
    );
    await ref.read(stopsControllerProvider.notifier).add(stop);
    if (!mounted) return;
    (widget.onConfirmed ?? (ctx) => ctx.go('/home'))(context);
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTranscript = _transcript.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Falar endereço')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Center(
                child: IconButton.filled(
                  key: const Key('voice-mic-button'),
                  iconSize: 42,
                  onPressed: _toggleListen,
                  icon: Icon(_listening ? Icons.stop : Icons.mic),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  _listening ? 'Ouvindo...' : 'Toque para falar o endereço',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                constraints: const BoxConstraints(minHeight: 80),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  hasTranscript ? _transcript : '...',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              const Spacer(),
              FilledButton(
                key: const Key('voice-confirm-button'),
                onPressed: hasTranscript ? _confirm : null,
                child: const Text('Adicionar parada'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
