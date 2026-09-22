# Error handling

`authenticate` returns `true` when the user is authenticated. In **every other case it throws** an `AuthenticationException`, so a call without a `try` / `catch` is a bug.

Windows uses the system Windows Hello verifier and reports the same `AuthenticationException` reasons as the other platforms.

```dart
try {
  await auth.authenticate(method: method);
  // Authenticated.
} on AuthenticationException catch (error) {
  switch (error.reason) {
    case AuthenticationErrorReason.userCanceled:
    case AuthenticationErrorReason.systemCanceled:
      break; // Nothing to report, the prompt was dismissed.
    case AuthenticationErrorReason.lockedOut:
      showMessage('Too many attempts. Unlock your device and try again.');
    case AuthenticationErrorReason.notEnrolled:
    case AuthenticationErrorReason.credentialNotSet:
      showMessage('Set up biometrics or a screen lock in the device settings.');
    default:
      showMessage('Could not verify your identity.');
  }
}
```

## Reasons

The `reason` tells what happened in the same way on every platform.

| `AuthenticationErrorReason` | Meaning                                                                                           |
| --------------------------- | ------------------------------------------------------------------------------------------------- |
| `userCanceled`              | The user dismissed the prompt.                                                                    |
| `systemCanceled`            | The system dismissed the prompt (the app moved to the background), or the app did with [`cancelAuthentication`](cancel.md). |
| `lockedOut`                 | Biometrics are locked out after too many failed attempts.                                         |
| `notEnrolled`               | The user did not enroll any biometrics.                                                           |
| `notAvailable`              | The device has no hardware for the method, or it can not be used right now.                       |
| `credentialNotSet`          | The device has no PIN, pattern, passcode or password, and the method needs it.                    |
| `unsupportedMethod`         | The platform does not support the [`AuthenticationMethod`](authentication-methods.md).            |
| `failed`                    | The user could not be authenticated, or the reason is unknown.                                    |

`error.isCanceled` is `true` for both `userCanceled` and `systemCanceled`.

How the native errors map to each reason is listed in [platform behaviour](../reference/platforms.md).

## It is also a `PlatformException`

`AuthenticationException` extends `PlatformException`, so `on PlatformException` handlers keep working, and the raw information of the platform is still there:

| Member    | Value                                                                                                          |
| --------- | -------------------------------------------------------------------------------------------------------------- |
| `code`    | `authentication_error`, or `unsupported_method` (`unsupportedAuthenticationMethodErrorCode`).                  |
| `message` | The platform's localized description of the error.                                                             |
| `details` | On Android, iOS and macOS a map with the `reason`, the native `errorCode` and the `message`.                   |

The native `errorCode` is a [`BiometricPrompt` error](https://developer.android.com/reference/androidx/biometric/BiometricPrompt#constants_1) on Android, and an [`LAError` code](https://developer.apple.com/documentation/localauthentication/laerror-swift.struct/code) on iOS and macOS.

Two other codes mean that something is wrong in the integration, and are reported with the reason `failed`:

| Code                     | Platforms | Meaning                                                                                      |
| ------------------------ | --------- | -------------------------------------------------------------------------------------------- |
| `invalid_arguments`      | All       | The method is unknown to the native side: the Dart and native code are out of sync.          |
| `null_pointer_exception` | Android   | The host activity is not a `FragmentActivity`. See [platform setup](../getting-started/platform-setup.md#android). |

## Avoid the error in the first place

Most reasons can be known before showing the prompt. Use [`getAvailability`](availability.md) to decide what to offer to the user.
