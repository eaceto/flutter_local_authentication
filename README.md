# Local Authentication

A flutter plugin that allows access to Local Authentication / Biometrics on iOS, macOS, Linux and Android (Windows Hello is a work in progress).

📖 **Documentation**: [eaceto.github.io/flutter_local_authentication](https://eaceto.github.io/flutter_local_authentication/) (setup, guides and API reference)

1. [Features](#features)
2. [Changelog](CHANGELOG.md)
3. [Usage](#usage)
  - 3.1. [Initialization](#initialization)
  - 3.2. [Localization](#localization)
  - 3.3. [Querying support and performing Local Authentication](#querying-support-and-performing-local-authentication)
4. [Considerations](#considerations)
  - 4.1. [canAuthenticate](#canauthenticate)
  - 4.2. [Supported Platforms](#supported-platforms)
5. [Next Steps](#next-steps)
6. [Publishing a new version](#publishing-a-new-version)
7. [Contribution](CONTRIBUTING.md)
8. [License](LICENSE)
9. [Code of Conduct](CODE_OF_CONDUCT.md)

---

## Features

- Detects if biometric authentication can be done in the current platform (**canAuthenticate**).

- Triggers platform's native authentication for the current user (**authenticate**).

- Read/Write macOS/iOS **touchIDAuthenticationAllowableReuseDuration** value

- Localized messages for iOS, macOS and Android

- Tells **why** the user can not authenticate (**getAvailability**), and which biometrics the device has (**getBiometryType**)

- Dismisses the prompt from the app (**cancelAuthentication**)

- Errors are an **AuthenticationException** with the same **reason** on every platform (canceled, locked out, not enrolled, ...)

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

### Authentication methods

Both _canAuthenticate_ and _authenticate_ accept an optional **method**, that defines which authenticators the user is allowed to use. Always use the same method on both calls.

- AuthenticationMethod.biometricsOnly (default): biometrics only.
- AuthenticationMethod.biometricsOrDeviceCredential: biometrics, falling back to the device PIN, pattern, passcode or password. Users without enrolled biometrics can authenticate.
- AuthenticationMethod.deviceCredentialOnly: device PIN, pattern, passcode or password only.

```Dart
    const method = AuthenticationMethod.biometricsOrDeviceCredential;

    if (await _flutterLocalAuthenticationPlugin.canAuthenticate(method: method)) {
      await _flutterLocalAuthenticationPlugin.authenticate(method: method);
    }
```

When a method is not supported by the platform _canAuthenticate_ returns **false**, _getAvailability_ returns **unsupportedMethod**, and _authenticate_ throws an _AuthenticationException_ with reason **unsupportedMethod**.

| Method                       | Android           | iOS | macOS | Linux |
| ---------------------------- | ----------------- | --- | ----- | ----- |
| biometricsOnly               | ✅                | ✅  | ✅    | ✅    |
| biometricsOrDeviceCredential | ✅                | ✅  | ✅    | ❌    |
| deviceCredentialOnly         | ✅ API 30 or newer | ✅  | ✅    | ❌    |

### Availability, biometry type and errors

```Dart
    // Why the user can, or can not, authenticate
    final availability = await _flutterLocalAuthenticationPlugin.getAvailability(method: method);
    if (availability == AuthenticationAvailability.notEnrolled) {
      // ask the user to enroll biometrics, or allow the device credential
    }

    // Label the UI: face, fingerprint, iris, multiple or none
    final biometryType = await _flutterLocalAuthenticationPlugin.getBiometryType();

    try {
      await _flutterLocalAuthenticationPlugin.authenticate(method: method);
    } on AuthenticationException catch (error) {
      if (!error.isCanceled) {
        // error.reason: lockedOut, notEnrolled, credentialNotSet, failed, ...
      }
    }

    // Dismiss the prompt, for example when the app moves to the background
    await _flutterLocalAuthenticationPlugin.cancelAuthentication();
```

## Considerations

### canAuthenticate

The function _canAuthenticate_ will return **true** in the following scenarios, depending on the authentication method.

- Android: **true** if BiometricManager returns that it can authenticate with the allowed authenticators:

  - biometricsOnly: BIOMETRIC_STRONG or BIOMETRIC_WEAK
  - biometricsOrDeviceCredential: BIOMETRIC_STRONG, BIOMETRIC_WEAK or DEVICE_CREDENTIAL
  - deviceCredentialOnly: DEVICE_CREDENTIAL

- iOS and macOS: **true** if LAContext.canEvaluatePolicy returns true for the policy:

  - biometricsOnly: deviceOwnerAuthenticationWithBiometrics
  - biometricsOrDeviceCredential and deviceCredentialOnly: deviceOwnerAuthentication (a passcode / password is set)

- linux: **true** if the method is biometricsOnly, _fprintd_ is installed and the user has enrolled fingerprints.

### Supported platforms

- iOS 15 or newer
- macOS 12 or newer
- Linux (requires libfprint)
- Android 7.0 (API 24) or newer

## Next Steps

- Add support to Windows Hello

## Publishing a new version

The package is published to [pub.dev](https://pub.dev/packages/flutter_local_authentication) by hand, from a clean checkout of `main`.

### 1. Bump the version

The version lives in four files, keep them in sync:

- `pubspec.yaml` → `version:`
- `android/build.gradle` → `version`
- `darwin/flutter_local_authentication.podspec` → `s.version`
- `CHANGELOG.md` → add a `## x.y.z` section at the top

Follow [semantic versioning](https://semver.org): a change in the public Dart API or in a minimum platform version is a major bump.

### 2. Verify

```bash
flutter analyze
flutter test

# Every platform of the example app must build
cd example
flutter build apk --debug
flutter build ios --debug --no-codesign
flutter build macos --debug
cd ..

# Checks the package, and lists exactly what will be uploaded
flutter pub publish --dry-run
```

The dry-run must report no warnings and an archive of a few hundred KB. Anything bigger means a build artifact leaked in: add it to `.pubignore` (it replaces `.gitignore` when publishing, so every rule has to be there).

### 3. Commit, tag and publish

```bash
git commit -am "Release x.y.z"
git tag vx.y.z
git push origin main vx.y.z

flutter pub publish
```

`flutter pub publish` opens the browser to sign in to pub.dev with an account that is an uploader of the package, then asks to confirm the upload. A version can not be re-published, so make sure the dry-run is clean first.

### 4. Release on GitHub

Create a [release](https://github.com/eaceto/flutter_local_authentication/releases/new) from the tag, with the `CHANGELOG.md` section as its notes. The documentation site is rebuilt by the `docs` workflow on every push to `main`.
