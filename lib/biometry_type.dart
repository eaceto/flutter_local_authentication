/// The kind of biometrics of the device. Returned by `getBiometryType`.
///
/// Use it to label your UI, for example "Unlock with Face ID".
enum BiometryType {
  /// The device has no biometrics, or they can not be used.
  none,

  /// Fingerprint: Touch ID on iOS and macOS.
  fingerprint,

  /// Face recognition: Face ID on iOS.
  face,

  /// Iris recognition: Optic ID on Apple platforms.
  iris,

  /// The device has more than one kind of biometrics, and the platform does not
  /// tell which one the user will use. Only reported on Android.
  multiple,
}
