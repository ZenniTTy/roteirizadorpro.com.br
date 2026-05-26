import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../stops/domain/stop.dart';
import '../../stops/presentation/shared/stops_async_view.dart';
import '../../stops/state/stops_controller.dart';

/// Named-channel share screen per `prototipo/screens-b.jsx:394-451`.
///
/// Renders three explicit destinations (WhatsApp, Copy-link, QR Code) +
/// a permanently visible QR section, instead of delegating to the
/// Android share-sheet. The shape mirrors the prototype 1:1: each row
/// is a `_ShareCard` with circular icon, title, subtitle, trailing
/// affordance.
class ShareSheet extends ConsumerWidget {
  const ShareSheet({super.key, this.shareFn});

  /// Test injection point: production calls `SharePlus.instance.share`;
  /// tests pass a recording fake so they don't reach the platform channel.
  final Future<void> Function(String text, {String? subject})? shareFn;

  /// Pure-Dart formatter exposed so unit tests can verify the
  /// WhatsApp-friendly format without spinning up a widget tree.
  static String buildRouteText(List<Stop> stops) {
    final buffer = StringBuffer('Rota otimizada — Roteirizador Pro\n\n');
    for (var i = 0; i < stops.length; i++) {
      final s = stops[i];
      buffer.writeln('${i + 1}. ${s.label ?? "(sem rótulo)"}');
      if (s.isGeocoded) {
        buffer.writeln(
          '   ${s.lat.toStringAsFixed(5)}, ${s.lng.toStringAsFixed(5)}',
        );
      }
    }
    return buffer.toString().trimRight();
  }

  Future<void> Function(String text, {String? subject}) _resolveShareFn() {
    return shareFn ??
        (text, {subject}) =>
            SharePlus.instance.share(ShareParams(text: text, subject: subject));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(stopsControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Indique o app')),
      body: SafeArea(
        child: stopsAsyncView(
          async,
          screenTag: 'ShareSheet',
          data: (context, stops) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  children: [
                    const _HeaderSubtitle(),
                    const SizedBox(height: 12),
                    _WhatsAppCard(stops: stops, shareFn: _resolveShareFn()),
                    const SizedBox(height: 12),
                    const _CopyLinkCard(),
                    const SizedBox(height: 12),
                    const _QrShareCard(),
                    const _QrSectionCard(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Chrome wrapper shared by every channel row. Mirrors the prototype's
/// white card with `border: 1px AppColors.border`, 16-px radius, soft
/// `AppShadows.card`, and an internal Row(icon, body, trailing).
class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
    this.disabled = false,
  });

  final Widget icon;
  final String title;
  final Widget subtitle;
  final Widget trailing;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                subtitle,
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );

    Widget interactive = content;
    if (onTap != null) {
      interactive = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.card),
          onTap: disabled ? null : onTap,
          child: content,
        ),
      );
    }

    if (disabled) {
      return Opacity(opacity: 0.5, child: interactive);
    }
    return interactive;
  }
}

class _HeaderSubtitle extends StatelessWidget {
  const _HeaderSubtitle();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(4, 0, 4, 4),
      child: Text(
        'Passe o link para outro motoboy e ganhe um mês grátis quando ele assinar.',
        style: TextStyle(fontSize: 14, color: AppColors.textMuted),
      ),
    );
  }
}

class _WhatsAppCard extends StatelessWidget {
  const _WhatsAppCard({required this.stops, required this.shareFn});

  final List<Stop> stops;
  final Future<void> Function(String text, {String? subject}) shareFn;

  @override
  Widget build(BuildContext context) {
    return _ShareCard(
      icon: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFF25D366),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: FaIcon(
            FontAwesomeIcons.whatsapp,
            size: 22,
            color: Colors.white,
          ),
        ),
      ),
      title: 'Compartilhar no WhatsApp',
      subtitle: const Text(
        'Abre o WhatsApp com mensagem pronta',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 20,
        color: AppColors.textMuted,
      ),
      onTap: () => shareFn(
        ShareSheet.buildRouteText(stops),
        subject: 'Minha rota',
      ),
      disabled: stops.isEmpty,
    );
  }
}

class _CopyLinkCard extends StatefulWidget {
  const _CopyLinkCard();

  @override
  State<_CopyLinkCard> createState() => _CopyLinkCardState();
}

class _CopyLinkCardState extends State<_CopyLinkCard> {
  static const _downloadUrl = 'https://roteirizadorpro.com.br/download';

  bool _copied = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _onCopy() async {
    await Clipboard.setData(const ClipboardData(text: _downloadUrl));
    if (!mounted) return;
    setState(() => _copied = true);
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ShareCard(
      icon: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.link, size: 22, color: AppColors.primary),
        ),
      ),
      title: 'Copiar link de download',
      subtitle: const Text(
        'roteirizadorpro.com.br/download',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
          fontFamily: 'monospace',
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: _CopyPillButton(copied: _copied, onPressed: _onCopy),
      onTap: _onCopy,
    );
  }
}

class _CopyPillButton extends StatelessWidget {
  const _CopyPillButton({required this.copied, required this.onPressed});

  final bool copied;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final fg = copied ? AppColors.success : AppColors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: copied ? AppColors.successBg : Colors.white,
            border: Border.all(color: AppColors.border, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(copied ? Icons.check : Icons.copy, size: 14, color: fg),
              const SizedBox(width: 4),
              Text(
                copied ? 'Copiado!' : 'Copiar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QrShareCard extends StatelessWidget {
  const _QrShareCard();

  @override
  Widget build(BuildContext context) {
    return _ShareCard(
      icon: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: AppColors.primaryLight,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.qr_code_2, size: 22, color: AppColors.primary),
        ),
      ),
      title: 'Mostrar QR Code',
      subtitle: const Text(
        'Outro motoboy escaneia direto',
        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(
        Icons.expand_more,
        size: 20,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _QrSectionCard extends StatelessWidget {
  const _QrSectionCard();

  static const _downloadUrl = 'https://roteirizadorpro.com.br/download';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: _downloadUrl,
            version: QrVersions.auto,
            size: 180,
            backgroundColor: Colors.white,
          ),
          const SizedBox(height: 12),
          const Text(
            'Aponte a câmera para o código',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
