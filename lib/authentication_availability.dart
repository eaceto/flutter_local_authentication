/// Whether the user can authenticate with an `AuthenticationMethod`, and the
/// reason why when they can not.
///
/// Returned by `getAvailability`. `canAuthenticate` is `true` only when the
/// availability is [available].
enum AuthenticationAvailability {
  /// The user can authenticate.
  available,

  /// The device has no hardware for the method, or it can not be used right now.
  notAvailable,

  /// The user did not enroll any biometrics.
  notEnrolled,

  /// Biometrics are locked out after too many failed attempts.
  ///
  /// Reported on iOS and macOS. Android only reports a lockout when authenticating.
  lockedOut,

  /// The device has no PIN, pattern, passcode or password, and the method needs it.
  credentialNotSet,

  /// The platform does not support the method.
  unsupportedMethod,
}
