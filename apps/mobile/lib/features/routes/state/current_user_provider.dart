import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/state/auth_controller.dart';
import '../domain/user_view_model.dart';

part 'current_user_provider.g.dart';

/// Projects the authenticated user (or `null`) onto the [UserViewModel] used
/// by the drawer.
///
/// Three distinct states are exposed via [UserViewModel]:
/// - **Authenticated:** `auth.value != null` → projected name + email.
///   `hasActiveSubscription` stays `false` (no paywall plumbing — Slice 4).
/// - **Unauthenticated:** `auth.value == null` and not loading/errored →
///   [UserViewModel.empty]. The router redirect (`app.dart`) normally
///   prevents this from ever rendering, but it's the safe default.
/// - **Errored or transient loading:** `auth.hasError` or `auth.isLoading`
///   → [UserViewModel.unavailable]. Drawer can render a degraded state
///   without coercing into the "logged out" UI.
///
/// Slice 4 will plumb `hasActiveSubscription` + `planLine` from the
/// subscription endpoint.
@Riverpod(keepAlive: true)
UserViewModel currentUser(Ref ref) {
  final auth = ref.watch(authControllerProvider);

  if (auth.hasError) {
    if (kDebugMode) {
      debugPrint(
        '[currentUserProvider] AuthController in error state — drawer '
        'will render UserViewModel.unavailable. Error: ${auth.error}',
      );
    }
    return UserViewModel.unavailable();
  }
  if (auth.isLoading) {
    return UserViewModel.unavailable();
  }
  final user = auth.value;
  if (user == null) {
    return UserViewModel.empty();
  }
  return UserViewModel(
    name: user.name,
    email: user.email,
    hasActiveSubscription: false,
  );
}
