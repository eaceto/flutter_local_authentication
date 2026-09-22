/// The authenticators a user is allowed to use to prove their identity.
///
/// Pass one of these values to `canAuthenticate` and `authenticate`. Always use
/// the same value for both calls, so the availability check matches the prompt
/// that is shown to the user.
///
/// Not every platform supports every method. When a method is not supported,
/// `canAuthenticate` returns `false` and `authenticate` fails with a
/// `PlatformException` whose code is [unsupportedAuthenticationMethodErrorCode].
enum AuthenticationMethod {
  /// Biometrics only (Face ID, Touch ID, fingerprint, face unlock, ...).
  ///
  /// Supported on Android, iOS, macOS and Linux. This is the default.
  biometricsOnly,

  /// Biometrics, falling back to the device credential (PIN, pattern, passcode
  /// or password). Users without enrolled biometrics can still authenticate.
  ///
  /// Supported on Android, iOS and macOS.
  biometricsOrDeviceCredential,

  /// Device credential only (PIN, pattern, passcode or password).
  ///
  /// Supported on Android 11 (API 30) or newer, iOS and macOS.
  deviceCredentialOnly,
}

/// Error code of the `PlatformException` thrown by `authenticate` when the
/// requested [AuthenticationMethod] is not supported by the current platform.
const String unsupportedAuthenticationMethodErrorCode = 'unsupported_method';
