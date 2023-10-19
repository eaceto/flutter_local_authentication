# Local Authentication

A flutter plugin that allows access to Local Authentication / Biometrics on iOS, macOS, Linux and Android (Windows Hello is a work in progress).

1. [Features](#features)
2. [Changelog](CHANGELOG.md)
3. [Usage](#usage)
   3.1. [Initialization](#initialization)
   3.2. [Localization](#localization)
   3.3. [Querying support and performing Local Authentication](#querying-support-and-performing-local-authentication)
4. [Considerations](#considerations)
   4.1. [canAuthenticate](#canauthenticate)
   4.2. [Supported Platforms](#supported-platforms)
5. [Next Steps](#next-steps)
6. [Contribution](CONTRIBUTING.md)
7. [License](LICENSE)
8. [Code of Conduct](CODE_OF_CONDUCT.md)

---

## Features

- Detects if biometric authentication can be done in the current platform (**canAuthenticate**).

- Triggers platform's native authentication for the current user (**authenticate**).

- Read/Write macOS/iOS **touchIDAuthenticationAllowableReuseDuration** value

- Localized messages for iOS, macOS and Android

## Usage

### Initialization

Initialize an instance of the plugin, which requires no input parameters.

```Dart
  final _flutterLocalAuthenticationPlugin = FlutterLocalAuthentication();
```

### Localization

At any time a localization model can be applied. The latests applied is used by the plugin when the local authentication is performed.

```Dart
    final localization = LocalizationModel(
        promptDialogTitle: "title for dialog",
        promptDialogReason: "reason for prompting biometric",
        cancelButtonTitle: "cancel"
    );
    _flutterLocalAuthenticationPlugin.setLocalizationModel(localization);
```

### Querying support and performing Local Authentication

Two functions are available for the core feature of this library:

- canAuthenticate
- authenticate

Depending on each platform the behaviour of _canAuthenticate_ can differ.

```Dart
    bool canAuthenticate;
    try {
      // Query suppor for Local Authentication
      canAuthenticate = await _flutterLocalAuthenticationPlugin.canAuthenticate();

      // Setup TouchID Allowable Reuse duration
      // It works only in iOS and macOS, but it's safe to call it even on other platforms.
      await _flutterLocalAuthenticationPlugin.setTouchIDAuthenticationAllowableReuseDuration(30);
    } on Exception catch (error) {
      debugPrint("Exception checking support. $error");
      canAuthenticate = false;
    }

    if (canAuthenticate) {
      // Perform Local Authentication

      _flutterLocalAuthenticationPlugin.authenticate().then((authenticated) {
        String result = 'Authenticated: $authenticated';
        // handle result
      }).catchError((error) {
        String result = 'Exception: $error';
        // handle error
      });
    }
```

## Considerations

### canAuthenticate

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

### Supported platforms

- iOS 12 or newer
- macOS 10.12.2 or newer
- Linux (requires libfprint)
- Android 6.0 or newer

## Next Steps

- Add support to Windows Hello
