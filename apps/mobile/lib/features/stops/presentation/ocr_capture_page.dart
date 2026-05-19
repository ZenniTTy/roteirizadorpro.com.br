import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/id.dart';
import '../../../core/services/permissions.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';

class OcrCapturePage extends ConsumerStatefulWidget {
  const OcrCapturePage({super.key, this.onConfirmed});

  /// Nullable so widget tests can assert taps without standing up a GoRouter;
  /// production falls through to `context.go('/home')`.
  final void Function(BuildContext context)? onConfirmed;

  @override
  ConsumerState<OcrCapturePage> createState() => _OcrCapturePageState();
}

class _OcrCapturePageState extends ConsumerState<OcrCapturePage> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  bool _busy = false;
  String _transcript = '';

  Future<void> _capture() async {
    final outcome = await ref.read(appPermissionsProvider).requestCamera();
    if (!mounted) return;
    if (outcome != PermissionOutcome.granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permissão da câmera necessária.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final file = await _picker.pickImage(source: ImageSource.camera);
      if (!mounted) return;
      if (file == null) return;

      final input = InputImage.fromFilePath(file.path);
      final result = await _recognizer.processImage(input);
      if (!mounted) return;
      setState(() => _transcript = result.text.trim());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirm() async {
    final text = _transcript.trim();
    if (text.isEmpty) return;

    final stop = Stop(
      id: newId(),
      lat: 0,
      lng: 0,
      label: text,
      source: StopSource.ocr,
      createdAt: DateTime.now(),
    );
    await ref.read(stopsControllerProvider.notifier).add(stop);
    if (!mounted) return;
    (widget.onConfirmed ?? (ctx) => ctx.go('/home'))(context);
  }

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasTranscript = _transcript.isNotEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Aponte para a etiqueta do pacote')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              if (_busy)
                const Center(child: CircularProgressIndicator())
              else
                Center(
                  child: IconButton.filled(
                    key: const Key('ocr-capture-button'),
                    iconSize: 42,
                    onPressed: _capture,
                    icon: const Icon(Icons.camera_alt),
                  ),
                ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  hasTranscript
                      ? 'Endereço encontrado:'
                      : 'Toque para fotografar a etiqueta',
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
                key: const Key('ocr-confirm-button'),
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
