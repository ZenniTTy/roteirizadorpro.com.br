import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddStopPage extends ConsumerStatefulWidget {
  const AddStopPage({super.key, this.onSaved});

  final void Function(BuildContext context)? onSaved;

  @override
  ConsumerState<AddStopPage> createState() => _AddStopPageState();
}

class _AddStopPageState extends ConsumerState<AddStopPage> {
  @override
  void initState() {
    super.initState();
    throw UnimplementedError();
  }

  // ignore: unused_element — stub body; implementer calls this from initState callback.
  Future<void> _openSheet() async {
    throw UnimplementedError();
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}
