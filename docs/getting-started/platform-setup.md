# Platform setup

## Android

**1. Use a `FlutterFragmentActivity`.** The biometric prompt needs a `FragmentActivity`. Change your `MainActivity` (`android/app/src/main/kotlin/.../MainActivity.kt`):

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity()
```

!!! warning
    With the default `FlutterActivity`, `authenticate` fails with an error whose code is `null_pointer_exception`. Any `FragmentActivity` subclass works, `FlutterFragmentActivity` is the one Flutter provides.

**2. Declare the permission** in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

!!! note "Android 9 and older"
    On Android 9 (API 28) and older the prompt is drawn by `androidx.biometric` with an AppCompat dialog. If your app runs on those versions, make the parent of `LaunchTheme` and `NormalTheme` (`android/app/src/main/res/values/styles.xml`) a `Theme.AppCompat` theme, for example `Theme.AppCompat.DayNight.NoActionBar`.

**3. Check your `minSdk`.** The plugin requires API 24 or newer. Apps created with a recent Flutter version already use `flutter.minSdkVersion`, which is enough.

## iOS

Add the reason why your app uses Face ID to `ios/Runner/Info.plist`. Without it the app crashes when Face ID is used.

```xml
<key>NSFaceIDUsageDescription</key>
<string>Authenticate to access your account.</string>
```

The minimum deployment target is **iOS 15**. In `ios/Podfile`:

```ruby
platform :ios, '15.0'
```

## macOS

No entitlements or usage descriptions are needed. The minimum deployment target is **macOS 12**. In `macos/Podfile`:

```ruby
platform :osx, '12.0'
```

## Swift Package Manager and CocoaPods

On iOS and macOS the plugin supports both **Swift Package Manager** and **CocoaPods**. Flutter picks the one your app uses, there is nothing to configure.

## Linux

The plugin uses [`fprintd`](https://fprint.freedesktop.org/) to verify fingerprints. It has to be installed, and the user needs an enrolled fingerprint:

```bash
sudo apt install fprintd   # Debian / Ubuntu
fprintd-enroll             # enroll a fingerprint for the current user
```

## Windows

Windows is not implemented yet. Calls to the plugin throw a `MissingPluginException`, so guard them:

```dart
if (!Platform.isWindows) {
  // use the plugin
}
```
