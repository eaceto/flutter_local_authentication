## 0.0.3 

* Implements 'authenticate' operation in all platforms
  1. Android using Biometrics API
  2. macOS and iOS using Local Authentication 
      * macOS uses LAPolicy **deviceOwnerAuthentication**
      * iOS uses LAPolicy **deviceOwnerAuthenticationWithBiometrics** 

  3. Linux using libfprint (fprintd-verify)

## 0.0.2

* Implements 'supports' operation on Android using Biometrics API

## 0.0.1

* Implements 'supports' operation on macOS
* Implements 'supports' operation on Linux
* Implements 'supports' operation on iOS
