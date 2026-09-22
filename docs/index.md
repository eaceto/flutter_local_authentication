# flutter_local_authentication

A Flutter plugin that gives your app access to the platform's **Local Authentication**: Face ID, Touch ID, fingerprint, face unlock and, when you allow it, the device PIN, pattern, passcode or password.

```dart
final auth = FlutterLocalAuthentication();

if (await auth.canAuthenticate()) {
  final authenticated = await auth.authenticate();
}
```

## Features

- **`canAuthenticate`**: check if the user can authenticate on the current device.
- **`authenticate`**: show the platform's native authentication prompt.
- **Authentication methods**: require biometrics, allow the device credential as a fallback, or ask for the device credential only.
- **`getAvailability`**: know *why* the user can not authenticate (not enrolled, locked out, no credential…).
- **`getBiometryType`**: label your UI with Face ID, fingerprint…
- **Typed errors**: one `AuthenticationException` with the same reasons on every platform.
- **`cancelAuthentication`**: dismiss the prompt from your app.
- **Localization** of the prompt on Android, iOS, macOS and Windows.
- **Touch ID allowable reuse duration** on iOS and macOS.

## Supported platforms

| Platform | Minimum version              | Backed by                        |
| -------- | ---------------------------- | -------------------------------- |
| Android  | Android 7.0 (API 24)         | `androidx.biometric`             |
| iOS      | iOS 15                       | `LocalAuthentication`            |
| macOS    | macOS 12                     | `LocalAuthentication`            |
| Linux    | Any, with `fprintd`          | `fprintd` (fingerprint)          |
| Windows  | Windows 10 version 1607 or newer | Windows Hello |

The plugin requires **Flutter 3.44** / **Dart 3.12** or newer.

## Where to go next

1. [Install the package](getting-started/installation.md)
2. [Set up each platform](getting-started/platform-setup.md)
3. [Follow the quick start](getting-started/quick-start.md)
4. Read about [authentication methods](guides/authentication-methods.md), [availability](guides/availability.md) and [error handling](guides/error-handling.md)
