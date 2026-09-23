# Platform behaviour

How the API maps to the native APIs of each platform.

## Android

Backed by [`androidx.biometric`](https://developer.android.com/jetpack/androidx/releases/biometric). `canAuthenticate` calls `BiometricManager.canAuthenticate` and `authenticate` shows a `BiometricPrompt`, both with the same authenticators:

| Method                         | Allowed authenticators                                      |
| ------------------------------ | ----------------------------------------------------------- |
| `biometricsOnly`               | `BIOMETRIC_STRONG` or `BIOMETRIC_WEAK`                       |
| `biometricsOrDeviceCredential` | `BIOMETRIC_STRONG`, `BIOMETRIC_WEAK` or `DEVICE_CREDENTIAL`  |
| `deviceCredentialOnly`         | `DEVICE_CREDENTIAL`                                          |

- `deviceCredentialOnly` needs Android 11 (API 30) or newer. Below that it is reported as unsupported.
- `cancelAuthentication` calls `BiometricPrompt.cancelAuthentication`.
- `getBiometryType` reads the hardware features of the device (`FEATURE_FINGERPRINT`, and `FEATURE_FACE` / `FEATURE_IRIS` on Android 10+). It returns `multiple` when there is more than one.

`getAvailability` maps the result of `BiometricManager.canAuthenticate`:

| `BiometricManager` result                                   | `AuthenticationAvailability`                                                     |
| ----------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `BIOMETRIC_SUCCESS`                                         | `available`                                                                      |
| `BIOMETRIC_ERROR_NONE_ENROLLED`                             | `notEnrolled` for `biometricsOnly`, `credentialNotSet` for the other methods     |
| `deviceCredentialOnly` below API 30                         | `unsupportedMethod`                                                              |
| Anything else (no hardware, unavailable, security update…)  | `notAvailable`                                                                   |

`authenticate` maps the error of `BiometricPrompt`:

| `BiometricPrompt` error                                                    | `AuthenticationErrorReason` |
| -------------------------------------------------------------------------- | --------------------------- |
| `ERROR_USER_CANCELED`, `ERROR_NEGATIVE_BUTTON`                             | `userCanceled`              |
| `ERROR_CANCELED`                                                           | `systemCanceled`            |
| `ERROR_LOCKOUT`, `ERROR_LOCKOUT_PERMANENT`                                 | `lockedOut`                 |
| `ERROR_NO_BIOMETRICS`                                                      | `notEnrolled`               |
| `ERROR_HW_UNAVAILABLE`, `ERROR_HW_NOT_PRESENT`, `ERROR_SECURITY_UPDATE_REQUIRED` | `notAvailable`        |
| `ERROR_NO_DEVICE_CREDENTIAL`                                               | `credentialNotSet`          |
| Anything else (timeout, vendor errors…)                                    | `failed`                    |

- The negative (cancel) button is only shown for `biometricsOnly`. Android does not allow it together with the device credential.
- `authenticate` needs the host activity to be a `FragmentActivity` (for example `FlutterFragmentActivity`). With a plain `FlutterActivity` it fails with the code `null_pointer_exception`; `canAuthenticate`, `getAvailability` and `getBiometryType` still work. See [platform setup](../getting-started/platform-setup.md#android).

## iOS and macOS

Backed by [`LocalAuthentication`](https://developer.apple.com/documentation/localauthentication). Both platforms share the same Swift code (the `darwin` folder of the plugin), so they behave in the same way.

| Method                         | `canAuthenticate` checks the policy           | `authenticate` evaluates                                        |
| ------------------------------ | --------------------------------------------- | --------------------------------------------------------------- |
| `biometricsOnly`               | `deviceOwnerAuthenticationWithBiometrics`     | `deviceOwnerAuthenticationWithBiometrics`                       |
| `biometricsOrDeviceCredential` | `deviceOwnerAuthentication`                   | `deviceOwnerAuthentication`                                     |
| `deviceCredentialOnly`         | `deviceOwnerAuthentication`                   | An access control that only accepts the `devicePasscode`        |

- `deviceOwnerAuthentication` can be evaluated as long as a passcode (iOS) or password (macOS) is set.
- With `biometricsOnly` the fallback button of the prompt is hidden.
- Every call uses a new `LAContext`, so a previous authentication is never reused, unless the [Touch ID reuse duration](../guides/touch-id-reuse.md) allows it.
- On macOS, `biometricsOrDeviceCredential` also accepts an Apple Watch when the user enabled it to unlock the Mac.
- `cancelAuthentication` invalidates the `LAContext` of the authentication in progress.
- `getBiometryType` maps `LAContext.biometryType`: `touchID` → `fingerprint`, `faceID` → `face`, `opticID` → `iris`.

`getAvailability` and `authenticate` map the `LAError` in the same way. `getAvailability` reports `notAvailable` for the errors that do not have a matching availability.

| `LAError`                                                        | Reason / availability  |
| ---------------------------------------------------------------- | ---------------------- |
| `userCancel`                                                     | `userCanceled`         |
| `systemCancel`, `appCancel`                                      | `systemCanceled`       |
| `biometryLockout`                                                | `lockedOut`            |
| `biometryNotEnrolled`                                            | `notEnrolled`          |
| `biometryNotAvailable`, `biometryNotPaired`, `biometryDisconnected` | `notAvailable`      |
| `passcodeNotSet`                                                 | `credentialNotSet`     |
| Anything else (`authenticationFailed`, `userFallback`…)          | `failed`               |


## Linux

Backed by [`fprintd`](https://fprint.freedesktop.org/), so only fingerprints are available.

| Method                         | Behaviour                                                                            |
| ------------------------------ | ------------------------------------------------------------------------------------ |
| `biometricsOnly`               | `canAuthenticate` runs `fprintd-list $USER`, `authenticate` runs `fprintd-verify`.   |
| `biometricsOrDeviceCredential` | Unsupported.                                                                         |
| `deviceCredentialOnly`         | Unsupported.                                                                         |

- `getAvailability` is `available` when `fprintd-list $USER` succeeds, and `notAvailable` otherwise.
- `getBiometryType` is `fingerprint` when `fprintd-list $USER` succeeds, and `none` otherwise.
- `cancelAuthentication` is not supported and returns `false`.

`fprintd-verify` does not show a dialog. Tell the user to touch the sensor in your own UI. When the fingerprint does not match, `authenticate` throws an `AuthenticationException` with the reason `failed`.

## Windows

Backed by the Windows Runtime [`UserConsentVerifier`](https://learn.microsoft.com/en-us/uwp/api/windows.security.credentials.ui.userconsentverifier) API.

- `canAuthenticate` and `getAvailability` check whether Windows Hello is available and configured for the current user.
- `authenticate` shows the Windows Hello verification prompt associated with the app window.
- `cancelAuthentication` cancels the verification in progress.
- `getBiometryType` returns `multiple` when Windows Hello is available, and `none` otherwise: Windows does not expose whether the configured Hello device is face, iris or fingerprint through this API.
- `authenticate` fails with `notAvailable` when the app has no Flutter view hosted in a top-level window.
- Windows selects the available Hello method itself. The three `AuthenticationMethod` values are accepted, but Windows may use a PIN or another configured Hello verifier even when the method is named `biometricsOnly`.

Availability maps as follows:

| Windows Hello availability | `AuthenticationAvailability` |
| -------------------------- | ---------------------------- |
| `Available`                 | `available`                   |
| `NotConfiguredForUser`      | `notEnrolled`                 |
| `DeviceBusy`, `DeviceNotPresent`, `DisabledByPolicy` | `notAvailable` |

Verification results map to the shared `AuthenticationErrorReason`: `Canceled` → `userCanceled`, `RetriesExhausted` → `lockedOut`, `NotConfiguredForUser` → `notEnrolled`, unavailable-device results → `notAvailable`, and other unsuccessful results → `failed`.
