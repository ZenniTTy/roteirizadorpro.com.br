import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom-sheet UI for adding a stop.
///
/// Stub — all method bodies throw [UnimplementedError].
/// Implementation is authored by the implementer agent (Phase 2, MS-15a).
class AddStopSheet extends ConsumerStatefulWidget {
  const AddStopSheet({super.key, this.onSaved});

  final void Function(BuildContext context)? onSaved;

  @override
  ConsumerState<AddStopSheet> createState() => _AddStopSheetState();
}

class _AddStopSheetState extends ConsumerState<AddStopSheet> {
  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }

  void _selectMethod(String method) {
    throw UnimplementedError();
  }

  Future<void> _onMethodTap(String method) async {
    throw UnimplementedError();
  }

  Future<void> _onAddStop() async {
    throw UnimplementedError();
  }

  @override
  void dispose() {
    super.dispose();
  }
}

/// Private button widget used by [AddStopSheet] for the three input-method
/// shortcuts (Teclado / Voz / Câmera).
///
/// Stub — build() throws [UnimplementedError].
class _MethodButton extends StatelessWidget {
  const _MethodButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}
