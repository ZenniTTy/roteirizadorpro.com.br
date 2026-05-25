import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'add_stop_sheet.dart';

/// Transparent route wrapper for `/home/stops/add`. On mount, schedules a
/// post-frame callback that opens [AddStopSheet] as a Material modal
/// bottom sheet over the current route. When the sheet resolves, inspects
/// the returned [AddStopResult] and either pushes the matching capture
/// route (voice/ocr) or invokes [onSaved] (or pops the route as the
/// default behavior so deep-links to `/home/stops/add` clean up properly).
///
/// The wrapper is "transparent" — `build()` returns [SizedBox.shrink] so
/// the only visible UI is the sheet sitting atop whatever was below in
/// the Navigator stack.
///
/// Pushing nested-branch routes (`/home/stops/voice`, `/home/stops/ocr`)
/// happens HERE — not from inside the sheet — because of Flutter issue
/// #155746: nested-branch push from inside a modal hosted by
/// StatefulShellRoute fails silently. The sheet returns an intent
/// ([AddStopResult]); this wrapper owns the navigation context that can
/// actually push.
class AddStopPage extends StatefulWidget {
  const AddStopPage({super.key, this.onSaved});

  /// Nullable so widget tests can assert taps without standing up a real
  /// GoRouter; production falls through to `context.pop()` (or `/home` if
  /// the page was deep-linked).
  final void Function(BuildContext context)? onSaved;

  @override
  State<AddStopPage> createState() => _AddStopPageState();
}

class _AddStopPageState extends State<AddStopPage> {
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

    // useRootNavigator: true hosts the sheet on the root Navigator
    // instead of the StatefulShellRoute branch Navigator. Without this,
    // the sheet's Navigator.pop returns to the branch's stack rather
    // than the top-level route stack, which complicates pop-then-push
    // sequencing. AddStopSheet.onSaved is intentionally NOT forwarded —
    // the sheet returns an AddStopResult via Navigator.pop(result), and
    // this wrapper does the nav decision after the future resolves.
    final result = await showModalBottomSheet<AddStopResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      builder: (_) => const AddStopSheet(),
    );
    if (!mounted) return;

    // Pop the wrapper route ('/home/stops/add') BEFORE navigating anywhere
    // else. This wrapper is transparent (build returns SizedBox.shrink), so
    // leaving it on the stack would cause a black/blank screen when the
    // user navigates back from the next route (voice/ocr) — they would
    // land on the wrapper instead of /home. We always want /home to be
    // the back-target after the sheet closes, regardless of which intent
    // the sheet returned.
    //
    // GoRouter.maybeOf returns null in widget tests that mount AddStopPage
    // under a plain MaterialApp (no GoRouter). In that case, falls back
    // to onSaved callback contract (existing test fixtures).
    final router = GoRouter.maybeOf(context);
    if (router != null && router.canPop()) {
      router.pop();
    }

    switch (result) {
      case AddStopResult.voice:
        router?.push('/home/stops/voice');
      case AddStopResult.camera:
        router?.push('/home/stops/ocr');
      case AddStopResult.saved:
      case null:
        // saved → fire onSaved (HomeList rebuilds via stopsController
        //         provider already triggered inside the sheet).
        // null  → barrier-tap / swipe-down dismiss; nothing else to do
        //         (we already popped the wrapper above when router exists).
        //
        // In production the router.pop above handles the visual transition;
        // onSaved is a no-op semantic hook for tests that need a signal
        // that the wrapper resolved.
        if (!mounted) return;
        widget.onSaved?.call(context);
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
