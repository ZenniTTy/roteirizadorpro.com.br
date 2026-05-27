import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/state/auth_controller.dart';
import '../domain/user_view_model.dart';

part 'current_user_provider.g.dart';

/// Projects the authenticated user (or `null`) onto the [UserViewModel] used
/// by the drawer. Slice 2 maps name/email straight from [AuthUserDto];
/// `hasActiveSubscription` stays `false` (no paywall plumbing yet — Slice 4)
/// and `planLine` stays `null` until subscription metadata exists.
@Riverpod(keepAlive: true)
UserViewModel currentUser(Ref ref) {
  final auth = ref.watch(authControllerProvider);
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
