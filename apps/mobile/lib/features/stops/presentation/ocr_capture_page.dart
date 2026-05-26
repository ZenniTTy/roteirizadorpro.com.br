import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/id.dart';
import '../../../core/services/permissions.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/stop.dart';
import '../state/stops_controller.dart';

class OcrCapturePage extends ConsumerStatefulWidget {
  const OcrCapturePage({
    super.key,
    this.onConfirmed,
    this.onClose,
    this.initialTranscript,
  });

  /// Nullable so widget tests can assert without standing up a GoRouter;
  /// production falls through to `context.pop()` (or `/home` if deep-linked).
  final void Function(BuildContext context)? onConfirmed;

  /// Symmetric close callback; production falls through to pop/go('/home').
  final void Function(BuildContext context)? onClose;

  /// Seed for the recognized-text state — exercises the result-card branch
  /// in widget tests without standing up a real camera + ML Kit pipeline.
  @visibleForTesting
  final String? initialTranscript;

  @override
  ConsumerState<OcrCapturePage> createState() => _OcrCapturePageState();
}

class _OcrCapturePageState extends ConsumerState<OcrCapturePage> {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  bool _busy = false;
  late String _transcript = widget.initialTranscript ?? '';

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

    // TODO(slice-3): geocode `text` via Nominatim before persisting; this
    // currently saves at the Null Island sentinel (0,0). The map preview in
    // StopDetail already handles ungeocoded stops by showing a placeholder.
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
    (widget.onConfirmed ??
        (ctx) => ctx.canPop() ? ctx.pop() : ctx.go('/home'))(context);
  }

  Future<void> _editTranscript() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _EditTranscriptDialog(initial: _transcript),
    );
    if (!mounted) return;
    if (result == null) return;
    setState(() => _transcript = result.trim());
  }

  @override
  void dispose() {
    _recognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = _transcript.isNotEmpty;
    final topPad = MediaQuery.of(context).padding.top;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E1A),
      body: Stack(
        children: [
          const _ViewfinderBackground(),
          const _MockPackageLabel(),
          const _ScanFrame(),
          Positioned(
            top: topPad + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                _FrostedCloseButton(onPressed: _handleClose),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Aponte para a etiqueta do pacote',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!hasResult)
            Positioned(
              bottom: bottomPad + 50,
              left: 0,
              right: 0,
              child: Center(
                child: _CaptureButton(
                  busy: _busy,
                  onPressed: _busy ? null : _capture,
                ),
              ),
            ),
          if (hasResult)
            Positioned(
              left: 16,
              right: 16,
              bottom: bottomPad + 110,
              child: _ResultCard(
                transcript: _transcript,
                onEdit: _editTranscript,
                onConfirm: _confirm,
              ),
            ),
        ],
      ),
    );
  }

  void _handleClose() {
    (widget.onClose ??
        (ctx) => ctx.canPop() ? ctx.pop() : ctx.go('/home'))(context);
  }
}

class _ViewfinderBackground extends StatelessWidget {
  const _ViewfinderBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1730), Color(0xFF0E0E1A)],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _MockPackageLabel extends StatelessWidget {
  const _MockPackageLabel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.rotate(
        angle: -math.pi / 60, // -3 degrees
        child: Container(
          width: 240,
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Inline literal: this is a mock "paper" color, not a brand token.
            color: const Color(0xFFD4C9A8),
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [
              BoxShadow(
                color: Color(0x80000000),
                blurRadius: 60,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: const DefaultTextStyle(
            style: TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFF3A2F1A),
              fontSize: 9,
              height: 1.6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DESTINATÁRIO:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
                Text('MARIA SOUZA'),
                Text('R. HADDOCK LOBO, 1500'),
                Text('APTO 1201 · JARDINS'),
                Text('SÃO PAULO · SP'),
                Text('CEP 01414-002'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanFrame extends StatelessWidget {
  const _ScanFrame();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 280,
        height: 220,
        child: CustomPaint(painter: _ScanFramePainter()),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  const _ScanFramePainter();

  static const double _radius = 16;
  static const double _dashOn = 8;
  static const double _dashOff = 6;
  static const double _bracketLen = 28;
  static const double _bracketStroke = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final dashed = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(_radius)));
    _drawDashedPath(canvas, path, dashed);

    final bracket = Paint()
      ..color = AppColors.accent
      ..strokeWidth = _bracketStroke
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    void corner(Offset h1, Offset h2, Offset v1, Offset v2) {
      canvas.drawLine(h1, h2, bracket);
      canvas.drawLine(v1, v2, bracket);
    }

    corner(
      const Offset(0, 0),
      const Offset(_bracketLen, 0),
      const Offset(0, 0),
      const Offset(0, _bracketLen),
    );
    corner(
      Offset(size.width - _bracketLen, 0),
      Offset(size.width, 0),
      Offset(size.width, 0),
      Offset(size.width, _bracketLen),
    );
    corner(
      Offset(0, size.height),
      Offset(_bracketLen, size.height),
      Offset(0, size.height - _bracketLen),
      Offset(0, size.height),
    );
    corner(
      Offset(size.width - _bracketLen, size.height),
      Offset(size.width, size.height),
      Offset(size.width, size.height - _bracketLen),
      Offset(size.width, size.height),
    );
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final next =
            (distance + (draw ? _dashOn : _dashOff)).clamp(0.0, metric.length);
        if (draw) {
          canvas.drawPath(
            metric.extractPath(distance, next),
            paint,
          );
        }
        distance = next;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(_ScanFramePainter oldDelegate) => false;
}

class _FrostedCloseButton extends StatelessWidget {
  const _FrostedCloseButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Material(
            color: Colors.white.withValues(alpha: 0.15),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: const Tooltip(
                message: 'Fechar',
                child: Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({required this.busy, required this.onPressed});
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: Material(
        color: Colors.white,
        shape: CircleBorder(
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.3),
            width: 4,
          ),
        ),
        child: InkWell(
          key: const Key('ocr-capture-button'),
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: busy
              ? const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 3,
                    ),
                  ),
                )
              : const Icon(
                  Icons.camera_alt,
                  color: AppColors.primary,
                  size: 28,
                ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.transcript,
    required this.onEdit,
    required this.onConfirm,
  });

  final String transcript;
  final VoidCallback onEdit;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 40,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Endereço encontrado:',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            transcript,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: TextButton(
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text(
                      'Editar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: FilledButton(
                    key: const Key('ocr-confirm-button'),
                    onPressed: onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    child: const Text(
                      'Confirmar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditTranscriptDialog extends StatefulWidget {
  const _EditTranscriptDialog({required this.initial});
  final String initial;

  @override
  State<_EditTranscriptDialog> createState() => _EditTranscriptDialogState();
}

class _EditTranscriptDialogState extends State<_EditTranscriptDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar endereço'),
      content: TextField(
        controller: _controller,
        key: const Key('ocr-edit-input'),
        autofocus: true,
        maxLines: null,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
