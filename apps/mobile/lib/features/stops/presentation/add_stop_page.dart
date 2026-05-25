import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'add_stop_sheet.dart';

/// Transparent route wrapper for `/stops/add`. On mount, schedules a
/// post-frame callback that opens [AddStopSheet] as a Material modal bottom
/// sheet over the current route. When the sheet resolves (any dismissal —
/// submit, swipe-down, barrier tap), invokes [onSaved] (or pops the route
/// as the default behavior so deep-links to `/stops/add` clean up properly).
///
/// The wrapper is "transparent" — `build()` returns [SizedBox.shrink] so the
/// only visible UI is the sheet sitting atop whatever was below in the
/// Navigator stack.
class AddStopPage extends ConsumerStatefulWidget {
  const AddStopPage({super.key, this.onSaved});

  /// Nullable so widget tests can assert taps without standing up a real
  /// GoRouter; production falls through to `context.pop()` (or `/home` if
  /// the page was deep-linked).
  final void Function(BuildContext context)? onSaved;

  @override
  ConsumerState<AddStopPage> createState() => _AddStopPageState();
}

class _AddStopPageState extends ConsumerState<AddStopPage> {
  // Risk-2 guard: addPostFrameCallback fires on first build only by design,
  // but hot reload semantics for initState are subtle. Guard prevents a
  // double showModalBottomSheet call on rebuild.
  bool _sheetOpened = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _openSheet());
  }

  Future<void> _openSheet() async {
    if (_sheetOpened) return;
    _sheetOpened = true;

    // AddStopSheet.onSaved is intentionally NOT forwarded here — this
    // wrapper invokes onSaved exactly once below, after the sheet future
    // resolves. Forwarding would double-fire on the submit path (sheet
    // calls onSaved then closes, then this awaiter calls onSaved again).
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddStopSheet(),
    );
    if (!mounted) return;

    final cb =
        widget.onSaved ?? (ctx) => ctx.canPop() ? ctx.pop() : ctx.go('/home');
    cb(context);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
