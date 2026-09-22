# API reference

Everything is exported by:

```dart
import 'package:flutter_local_authentication/flutter_local_authentication.dart';
import 'package:flutter_local_authentication/localization_model.dart'; // LocalizationModel
```

The generated [dartdoc](https://eaceto.github.io/flutter_local_authentication/api/) has the same information with links to the source.

## `FlutterLocalAuthentication`

The entry point of the plugin. It has a default constructor with no parameters.

```dart
final auth = FlutterLocalAuthentication();
```

### `canAuthenticate`

```dart
Future<bool> canAuthenticate({
  AuthenticationMethod method = AuthenticationMethod.biometricsOnly,
})
```

Checks if the user can authenticate with `method` on this device.

Returns `true` when the platform supports the method and everything it needs is set up (hardware, enrolled biometrics, a device credential). Returns `false` otherwise, including when the platform does not support the method. It never shows any UI.

### `authenticate`

```dart
Future<bool> authenticate({
  AuthenticationMethod method = AuthenticationMethod.biometricsOnly,
})
```

Shows the native prompt and completes when the user is done with it.

- **Returns** `true` when the user is authenticated.
- **Throws** an [`AuthenticationException`](#authenticationexception) in every other case. Its `reason` tells what happened.

It never returns `false`.

### `getAvailability`

```dart
Future<AuthenticationAvailability> getAvailability({
  AuthenticationMethod method = AuthenticationMethod.biometricsOnly,
})
```

The detailed version of `canAuthenticate`: tells whether the user can authenticate with `method`, and the reason why when they can not. It never shows any UI. See [availability](../guides/availability.md).

### `getBiometryType`

```dart
Future<BiometryType> getBiometryType()
```

Returns the kind of biometrics of the device, to label your UI. It tells what the device has, not what the user enrolled.

### `cancelAuthentication`

```dart
Future<bool> cancelAuthentication()
```

Dismisses the prompt that is being shown. The pending `authenticate` call throws an `AuthenticationException` with the reason `systemCanceled`. Returns `true` if there was a prompt to dismiss. Not supported on Linux, where it returns `false`. See [dismissing the prompt](../guides/cancel.md).

### `setLocalizationModel`

```dart
Future<void> setLocalizationModel(LocalizationModel localizationModel)
```

Sets the texts of the following prompts. Applies to Android, iOS, macOS and Windows, and does nothing on Linux. The returned future completes when the platform has stored the model. See [localization](../guides/localization.md).

### `setTouchIDAuthenticationAllowableReuseDuration`

```dart
Future<double> setTouchIDAuthenticationAllowableReuseDuration(double duration)
```

**iOS and macOS.** Sets for how many seconds after a Touch ID device unlock the user is authenticated without a prompt. Returns the stored value, which the system caps at 5 minutes. On other platforms it returns `duration` and does nothing. See [Touch ID reuse duration](../guides/touch-id-reuse.md).

### `getTouchIDAuthenticationAllowableReuseDuration`

```dart
Future<double> getTouchIDAuthenticationAllowableReuseDuration()
```

**iOS and macOS.** Returns the current allowable reuse duration, in seconds. On other platforms it returns `0`.

## `AuthenticationMethod`

```dart
enum AuthenticationMethod {
  biometricsOnly,
  biometricsOrDeviceCredential,
  deviceCredentialOnly,
}
```

| Value                          | Description                                                               | Supported on                              |
| ------------------------------ | ------------------------------------------------------------------------- | ----------------------------------------- |
| `biometricsOnly`               | Biometrics only. The default.                                             | Android, iOS, macOS, Linux                |
| `biometricsOrDeviceCredential` | Biometrics, falling back to the PIN, pattern, passcode or password.       | Android, iOS, macOS                       |
| `deviceCredentialOnly`         | PIN, pattern, passcode or password only.                                  | Android 11 (API 30) or newer, iOS, macOS  |

See [authentication methods](../guides/authentication-methods.md).

## `AuthenticationAvailability`

```dart
enum AuthenticationAvailability {
  available,
  notAvailable,
  notEnrolled,
  lockedOut,
  credentialNotSet,
  unsupportedMethod,
}
```

Returned by `getAvailability`. Each value is described in [availability](../guides/availability.md#why-the-user-can-not-authenticate).

## `BiometryType`

```dart
enum BiometryType { none, fingerprint, face, iris, multiple }
```

Returned by `getBiometryType`. Each value is described in [labeling your UI](../guides/availability.md#labeling-your-ui).

## `AuthenticationException`

```dart
class AuthenticationException extends PlatformException
```

Thrown by `authenticate` when the user is not authenticated.

| Member       | Description                                                                                       |
| ------------ | ------------------------------------------------------------------------------------------------- |
| `reason`     | An [`AuthenticationErrorReason`](#authenticationerrorreason): what happened, on every platform.   |
| `isCanceled` | `true` when the reason is `userCanceled` or `systemCanceled`.                                     |
| `code`       | `authentication_error` (`AuthenticationException.authenticationErrorCode`) or `unsupported_method`. |
| `message`    | The platform's localized description of the error.                                                |
| `details`    | The raw information of the platform: `reason`, native `errorCode` and `message`.                  |

## `AuthenticationErrorReason`

```dart
enum AuthenticationErrorReason {
  userCanceled,
  systemCanceled,
  lockedOut,
  notEnrolled,
  notAvailable,
  credentialNotSet,
  unsupportedMethod,
  failed,
}
```

Each value is described in [error handling](../guides/error-handling.md#reasons).

## `unsupportedAuthenticationMethodErrorCode`

```dart
const String unsupportedAuthenticationMethodErrorCode = 'unsupported_method';
```

The `code` of the `AuthenticationException` thrown by `authenticate` when the platform does not support the requested method. Its `reason` is `unsupportedMethod`.

## `LocalizationModel`

```dart
LocalizationModel({
  required String promptDialogTitle,
  required String promptDialogReason,
  required String cancelButtonTitle,
})
```

| Member                         | Description                                           |
| ------------------------------ | ----------------------------------------------------- |
| `promptDialogTitle`            | Title of the prompt (Android).                        |
| `promptDialogReason`           | Why the app asks the user to authenticate.            |
| `cancelButtonTitle`            | Title of the button that cancels the prompt.          |
| `LocalizationModel.fromJson()` | Creates a model from a `Map<String, dynamic>`.        |
| `toJson()`                     | Converts the model to a `Map<String, dynamic>`.       |

## Platform interface

`FlutterLocalAuthenticationPlatform` and `MethodChannelFlutterLocalAuthentication` are the plugin's [platform interface](https://pub.dev/packages/plugin_platform_interface). Apps do not use them directly. They are useful to **mock the plugin in tests**:

```dart
class FakeLocalAuthentication extends FlutterLocalAuthenticationPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<bool> canAuthenticate({
    AuthenticationMethod method = AuthenticationMethod.biometricsOnly,
  }) async => true;

  @override
  Future<bool> authenticate({
    AuthenticationMethod method = AuthenticationMethod.biometricsOnly,
  }) async => true;
}

void main() {
  setUp(() {
    FlutterLocalAuthenticationPlatform.instance = FakeLocalAuthentication();
  });
}
```
