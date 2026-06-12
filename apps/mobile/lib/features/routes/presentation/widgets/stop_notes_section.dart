import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/stop.dart';
import '../../state/routes_provider.dart';

part 'stop_notes_section.g.dart';

/// Wrapper injetável da câmera (H17): produção usa
/// `ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1280,
///  imageQuality: 80)`; testes overridam com fake retornando XFile ou null.
/// Pode retornar null (cancelamento) ou lançar PlatformException (permissão
/// negada) — o widget trata ambos os casos sem deixar exceção vazar.
@Riverpod(keepAlive: true)
Future<XFile?> Function() cameraPicker(Ref ref) => () => ImagePicker()
    .pickImage(source: ImageSource.camera, maxWidth: 1280, imageQuality: 80);

/// Seção de notas + foto de pacote da EditStopPage (F12/H15/H17).
///
/// Contrato:
/// - TextField multiline (maxLines null) com `hintText: 'Adicionar notas'`.
/// - Pré-preenchido com [stop.notes] quando não-nulo.
/// - Digitar + unfocus → `updateStop` com `notes` novo (F3 live).
/// - Apagar tudo + unfocus → `notes == null` (não string vazia).
/// - Tap em `edit_stop_camera` → invoca [cameraPickerProvider]:
///   - XFile retornado → `packagePhotoStoreProvider.saveFor` → `updateStop`
///     com `photoPaths` atualizado.
///   - null (cancelamento) → SnackBar de cancelamento + sem mudança de estado.
///   - PlatformException(code: 'camera_access_denied') → SnackBar + estado
///     intacto, exceção não vaza (tester.takeException() == null).
/// - Thumbnails: Key('stop_photo_0') por foto presente; errorBuilder retorna
///   Key('stop_photo_placeholder_0') quando o arquivo não existe (H15).
class StopNotesSection extends ConsumerStatefulWidget {
  const StopNotesSection({
    super.key,
    required this.routeId,
    required this.stop,
  });

  final String routeId;
  final Stop stop;

  @override
  ConsumerState<StopNotesSection> createState() => _StopNotesSectionState();
}

class _StopNotesSectionState extends ConsumerState<StopNotesSection> {
  late final TextEditingController _notesController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController(text: widget.stop.notes ?? '');
    // Commit-on-unfocus (F3 live): o valor só vai pro provider quando o
    // usuário sai do campo (ou submete) — igual ao commit-on-dismiss das
    // sub-sheets.
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _commitNotes();
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Stop atual no provider (o widget.stop pode ter ficado stale após um
  /// updateStop de outra seção — sempre commitar sobre o estado vigente).
  Stop? get _currentStop => ref
      .read(routesProvider)
      .where((r) => r.id == widget.routeId)
      .firstOrNull
      ?.stops
      .where((s) => s.id == widget.stop.id)
      .firstOrNull;

  void _commitNotes() {
    final current = _currentStop;
    if (current == null) return;
    final text = _notesController.text.trim();
    final next = text.isEmpty ? null : text;
    if (next == current.notes) return;
    ref
        .read(routesProvider.notifier)
        .updateStop(widget.routeId, current.copyWith(notes: next));
  }

  Future<void> _takePhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    XFile? picked;
    try {
      picked = await ref.read(cameraPickerProvider)();
    } on PlatformException {
      // Permissão negada (camera_access_denied) ou erro do plugin — degrada
      // com toast, sem mudança de estado (H17, padrão _onRecenter).
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Não foi possível usar a câmera agora.'),
          ),
        );
      return;
    }
    if (picked == null) {
      // Cancelamento: sem mudança de estado (H17).
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Foto cancelada.')));
      return;
    }
    final store = ref.read(packagePhotoStoreProvider);
    final savedPath =
        await store.saveFor(widget.routeId, widget.stop.id, File(picked.path));
    if (!mounted) return;
    if (savedPath == null) {
      // Falha de I/O ao copiar — nunca drop silencioso (H15).
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Não foi possível salvar a foto.')),
        );
      return;
    }
    final current = _currentStop;
    if (current == null) return;
    ref.read(routesProvider.notifier).updateStop(
          widget.routeId,
          current.copyWith(photoPaths: [...current.photoPaths, savedPath]),
        );
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.stop.photoPaths;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _notesController,
                  focusNode: _focusNode,
                  maxLines: null,
                  onSubmitted: (_) => _commitNotes(),
                  decoration: const InputDecoration(
                    hintText: 'Adicionar notas',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontSize: 14, color: AppColors.text),
                ),
              ),
              Semantics(
                identifier: 'edit_stop_camera',
                button: true,
                child: IconButton(
                  icon: const Icon(
                    LucideIcons.camera,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  onPressed: _takePhoto,
                ),
              ),
            ],
          ),
          if (photos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: photos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(photos[index]),
                      key: Key('stop_photo_$index'),
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Arquivo morto (apagado fora do app) → placeholder,
                        // nunca crash (H15).
                        debugPrint(
                          '[stop_notes_section] thumbnail morta '
                          '${photos[index]}: $error',
                        );
                        return Container(
                          key: Key('stop_photo_placeholder_$index'),
                          width: 64,
                          height: 64,
                          color: AppColors.border,
                          child: const Icon(
                            LucideIcons.imageOff,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
