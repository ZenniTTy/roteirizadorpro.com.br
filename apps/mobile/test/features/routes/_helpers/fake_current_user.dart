import 'package:roteirizador_pro/features/routes/domain/user_view_model.dart';

/// Pre-built [UserViewModel] fixtures for drawer header tests.
/// Use via: currentUserProvider.overrideWithValue(kUserWithSub)
const kUserWithSub = UserViewModel(
  name: 'Ana Silva',
  email: 'ana@example.com',
  hasActiveSubscription: true,
);

const kUserWithoutSub = UserViewModel(
  name: 'Bruno Costa',
  email: 'bruno@example.com',
  hasActiveSubscription: false,
);
