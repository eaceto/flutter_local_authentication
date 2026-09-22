# Availability and biometry type

## Why the user can not authenticate

`canAuthenticate` answers `true` or `false`. `getAvailability` answers the same question and tells **why not**, so your app can react:

```dart
final availability = await auth.getAvailability(
  method: AuthenticationMethod.biometricsOnly,
);

switch (availability) {
  case AuthenticationAvailability.available:
    // Offer biometric authentication.
  case AuthenticationAvailability.notEnrolled:
    // Ask the user to enroll, or allow the device credential.
  case AuthenticationAvailability.lockedOut:
    // Biometrics are locked, the device credential still works.
  default:
    // Offer another way in.
}
```

| `AuthenticationAvailability` | Meaning                                                                            |
| ---------------------------- | ---------------------------------------------------------------------------------- |
| `available`                  | The user can authenticate. `canAuthenticate` is `true` only in this case.          |
| `notAvailable`               | The device has no hardware for the method, or it can not be used right now.        |
| `notEnrolled`                | The user did not enroll any biometrics.                                            |
| `lockedOut`                  | Biometrics are locked out. Reported on iOS and macOS only.<sup>1</sup>             |
| `credentialNotSet`           | The device has no PIN, pattern, passcode or password, and the method needs it.     |
| `unsupportedMethod`          | The platform does not support the method.                                          |

<sup>1</sup> Android only reports a lockout when authenticating, as the `lockedOut` reason of the [`AuthenticationException`](error-handling.md).

### Falling back to the device credential

This is the most common use: prefer biometrics, and let users without them in with their PIN or password.

```dart
Future<AuthenticationMethod?> pickMethod(FlutterLocalAuthentication auth) async {
  final biometrics = await auth.getAvailability();
  if (biometrics == AuthenticationAvailability.available) {
    return AuthenticationMethod.biometricsOnly;
  }

  const fallback = AuthenticationMethod.biometricsOrDeviceCredential;
  if (await auth.canAuthenticate(method: fallback)) return fallback;

  return null; // Local Authentication is not available.
}
```

## Labeling your UI

`getBiometryType` tells which kind of biometrics the device has, to show the right text and icon:

```dart
final label = switch (await auth.getBiometryType()) {
  BiometryType.face => 'Unlock with Face ID',
  BiometryType.fingerprint => 'Unlock with your fingerprint',
  BiometryType.iris => 'Unlock with Optic ID',
  BiometryType.multiple => 'Unlock with biometrics',
  BiometryType.none => 'Unlock',
};
```

| `BiometryType` | iOS / macOS | Android                                   | Linux                  |
| -------------- | ----------- | ----------------------------------------- | ---------------------- |
| `fingerprint`  | Touch ID    | Fingerprint sensor                        | Fingerprint (`fprintd`) |
| `face`         | Face ID     | Face unlock hardware (Android 10+)        | —                      |
| `iris`         | Optic ID    | Iris scanner (Android 10+)                | —                      |
| `multiple`     | —           | More than one kind of hardware            | —                      |
| `none`         | No biometrics | No biometric hardware                   | No fingerprint available |

!!! note "It is about the hardware"
    The type tells what the device **has**, not what the user enrolled. On Android the system also decides which biometrics the prompt uses, so `multiple` is returned when there is more than one. Use `getAvailability` to know if the user can actually authenticate.
