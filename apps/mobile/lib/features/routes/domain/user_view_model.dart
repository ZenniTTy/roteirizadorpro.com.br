/// UI projection used by the drawer header.
/// NOT the same as AuthUserDto — this is a flat view model for the drawer.
class UserViewModel {
  const UserViewModel({
    required this.name,
    required this.email,
    required this.hasActiveSubscription,
    this.planLine,
    this.isUnavailable = false,
  });
  final String name;
  final String email;
  final bool hasActiveSubscription;

  /// Optional third line shown below the email in the header card.
  /// Example (Spoke): "Standard • Renova-se em ter. 09 de jun."
  /// Slice 2 stub renders nothing; Slice 4 plumbs the real subscription
  /// status into this field.
  final String? planLine;

  /// `true` when the controller is in an error/loading state and the
  /// drawer should render a degraded state instead of mimicking the
  /// logged-out UI. See [UserViewModel.unavailable].
  final bool isUnavailable;

  /// Empty sentinel used as the unauthenticated default. Always
  /// non-subscriber so the "Assinar" CTA renders during development.
  factory UserViewModel.empty() => const UserViewModel(
        name: '',
        email: '',
        hasActiveSubscription: false,
      );

  /// Used when the underlying [AuthController] is in `AsyncLoading` or
  /// `AsyncError` — distinguishes "we don't know yet / something broke"
  /// from "definitely logged out". The drawer should render a clear
  /// "Sessão indisponível" affordance instead of empty strings.
  factory UserViewModel.unavailable() => const UserViewModel(
        name: 'Sessão indisponível',
        email: 'Toque em "Sair" e entre novamente',
        hasActiveSubscription: false,
        isUnavailable: true,
      );
}
