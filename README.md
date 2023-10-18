# Local Authentication

A flutter plugin that allows access to Local Authentication / Biometrics on iOS, macOS, Linux and Android (Windows Hello is a work in progress).

## Features

- Detects if biometric authentication can be done in the current platform (**canAuthenticate**).

- Triggers platform's native authentication for the current user (**authenticate**).

- Read/Write macOS/iOS **touchIDAuthenticationAllowableReuseDuration** value

## Considerations

## canAuthenticate

The function _canAuthenticate_ will return **true** in the following scenarios.

- Android: **true** if BiometricManager returns that it can authenticate with one of the following allowed authenticators:

  - BiometricManager.Authenticators.BIOMETRIC_STRONG
  - BiometricManager.Authenticators.BIOMETRIC_WEAK
  - BiometricManager.Authenticators.DEVICE_CREDENTIAL

- iOS: **true** if LAContext.supportsLocalAuthentication returns true for device policy:

  - deviceOwnerAuthenticationWithBiometrics

- macOS: **true** if LAContext.supportsLocalAuthentication returns true for device policy:

  - deviceOwnerAuthentication

- linux: **true** if _fprintd-verify_ is installed and user can execute it.

## Supported platforms

- iOS 12 or newer
- macOS 10.12.2 or newer
- Linux (requires libfprint)
- Android 6.0 or newer
- Windows (work in progress)

## TODO

- localise messages
