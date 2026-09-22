## 2.0.0

- Add `AuthenticationMethod` (biometricsOnly, biometricsOrDeviceCredential, deviceCredentialOnly) as an optional `method` parameter of `canAuthenticate` and `authenticate`, on Android, iOS, macOS and Linux. Users without enrolled biometrics can authenticate with their device credential (thanks @tmpfs for the idea in #6)
- Unsupported methods make `canAuthenticate` return false, and `authenticate` fail with the `unsupported_method` error code
- Add `getAvailability`, that tells why the user can not authenticate (`notEnrolled`, `lockedOut`, `credentialNotSet`, `notAvailable`, `unsupportedMethod`)
- Add `getBiometryType` (`face`, `fingerprint`, `iris`, `multiple`, `none`)
- Add `cancelAuthentication`, to dismiss the prompt from the app
- `authenticate` throws an `AuthenticationException` (a `PlatformException`) with a `reason` that is the same on every platform: `userCanceled`, `systemCanceled`, `lockedOut`, `notEnrolled`, `notAvailable`, `credentialNotSet`, `unsupportedMethod`, `failed`
- iOS / macOS: add Swift Package Manager support, next to CocoaPods
- iOS / macOS: share one Swift implementation in the `darwin` folder
- Fix `.pubignore`, so build outputs are no longer included in the published package
- Android: accept any `FragmentActivity` as host, instead of requiring `FlutterFragmentActivity`. A plain `FlutterActivity` no longer crashes the app at startup: `authenticate` fails with a descriptive error, and the other methods work
- **Behaviour change**: the default method is biometricsOnly on every platform
  - macOS: `authenticate` no longer falls back to the user's password by default
  - Android: `canAuthenticate` no longer returns true when only a device credential is set, which made `authenticate` fail afterwards
- iOS / macOS: every authentication prompts the user. A previous successful authentication is not reused, except for the Touch ID allowable reuse duration
- Fix `setLocalizationModel` never completing on Android, iOS and macOS, and make it return a `Future<void>` so it can be awaited
- iOS / macOS: the cancel button uses the `cancelButtonTitle` of the localization model, and the fallback button is hidden when the method is biometricsOnly
- iOS / macOS: compiles with Swift 6 (language mode 6, strict concurrency)
- Builds against the latest toolchains: Android Gradle Plugin 9.1 / Gradle 9.3 / Kotlin 2.4 (compileSdk 36, Java 17), Xcode 27
- Migrates the Android plugin to built-in Kotlin
- Minimum Android SDK is now 24 (was 19)
- Minimum iOS version is now 15.0 (was 12.0)
- Minimum macOS version is now 12.0 (was 10.11)
- Requires:
  - sdk: '^3.12.0'
  - flutter: '>=3.44.0'

## 1.2.0

- Add GitHub actions for publishing releases to pub.dev automatically
- Downgraded Flutter SDK
- Requires:
  - sdk: '>=3.1.0 <4.0.0'
  - flutter: '3.0.0'

## 1.1.0

- Add a localization model for messages shown to the user

## 1.0.0

- Implemented 'setTouchIDAuthenticationAllowableReuseDuration' for iOS and macOS
- Implemented 'getTouchIDAuthenticationAllowableReuseDuration' for iOS and macOS
- touchIDAuthenticationAllowableReuseDuration defaults to 0 [Docs](https://developer.apple.com/documentation/localauthentication/lacontext/1622329-touchidauthenticationallowablere/)
- Requires:
  - sdk: '>=3.1.3 <4.0.0'
- Minimun iOS version 12.0
- Improved documentation

## 0.0.3

- Implements 'authenticate' operation in all platforms

  1. Android using Biometrics API
  2. macOS and iOS using Local Authentication

     - macOS uses LAPolicy **deviceOwnerAuthentication**
     - iOS uses LAPolicy **deviceOwnerAuthenticationWithBiometrics**

  3. Linux using libfprint (fprintd-verify)

## 0.0.2

- Implements 'supports' operation on Android using Biometrics API

## 0.0.1

- Implements 'supports' operation on macOS
- Implements 'supports' operation on Linux
- Implements 'supports' operation on iOS
