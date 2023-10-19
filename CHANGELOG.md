## 1.2.0

- Add GitHub actions for publishing releases to pub.dev automatically

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
