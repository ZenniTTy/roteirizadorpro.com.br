/// UI projection used by the drawer header.
/// NOT the same as AuthUserDto — this is a flat view model for the drawer.
class UserViewModel {
  const UserViewModel({
    required this.name,
    required this.email,
    required this.hasActiveSubscription,
    this.planLine,
  });
  final String name;
  final String email;
  final bool hasActiveSubscription;

  /// Optional third line shown below the email in the header card.
  /// Example (Spoke): "Standard • Renova-se em ter. 09 de jun."
  /// Slice 2 stub renders nothing; Slice 4 plumbs the real subscription
  /// status into this field.
  final String? planLine;

  /// Empty sentinel used as the Slice 2 default before AuthController state
  /// is plumbed into the drawer. Always non-subscriber so the "Assinar" CTA
  /// renders by default during development.
  factory UserViewModel.empty() => const UserViewModel(
        name: '',
        email: '',
        hasActiveSubscription: false,
      );
}
