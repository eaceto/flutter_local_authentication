# Migrating to 2.0

Version 2.0 adds [authentication methods](guides/authentication-methods.md), makes every platform behave the same way, and updates the toolchains. Most apps only need to check the new requirements.

## New requirements

| What               | 1.x      | 2.0          |
| ------------------ | -------- | ------------ |
| Flutter            | 3.0      | **3.44**     |
| Dart               | 3.1      | **3.12**     |
| Android `minSdk`   | 19       | **24**       |
| iOS                | 12.0     | **15.0**     |
| macOS              | 10.11    | **12.0**     |

Update the `platform` line of your `ios/Podfile` and `macos/Podfile` if they target older versions. See [platform setup](getting-started/platform-setup.md).

## Behaviour changes

Calls without a `method` now mean **biometrics only on every platform**. Two platforms behaved differently in 1.x:

=== "macOS"

    `authenticate()` used to fall back to the user's password. Now it accepts biometrics only. To keep the old behaviour pass the method, in both calls:

    ```dart
    const method = AuthenticationMethod.biometricsOrDeviceCredential;
    await auth.canAuthenticate(method: method);
    await auth.authenticate(method: method);
    ```

=== "Android"

    `canAuthenticate()` used to return `true` on a device with a PIN and no enrolled biometrics, and `authenticate()` failed right after. Now `canAuthenticate()` returns `false` in that case. To let those users in, use `AuthenticationMethod.biometricsOrDeviceCredential`.

=== "iOS"

    Every `authenticate()` call prompts the user. In 1.x a second call could succeed without a prompt, because the previous authentication was reused. The cancel button now uses the `cancelButtonTitle` of your `LocalizationModel`.

## Errors

`authenticate` now throws an `AuthenticationException` with a `reason`, instead of a `PlatformException` or a plain `Exception`.

- `on PlatformException` and `on Exception` handlers keep working: `AuthenticationException` extends `PlatformException`, with the same `code`, `message` and `details`.
- The only case that changes is a platform answering "not authenticated" without an error, which was a plain `Exception` and is now an `AuthenticationException` with the reason `failed`. Code that tells errors apart with `is! PlatformException` has to be updated.

See [error handling](guides/error-handling.md).

`setLocalizationModel` returns a `Future<void>` instead of `void`. Existing calls keep compiling; you can now `await` it.

## New APIs

Nothing to migrate, but worth adopting:

- [`getAvailability`](guides/availability.md) tells why the user can not authenticate.
- [`getBiometryType`](guides/availability.md#labeling-your-ui) labels your UI.
- [`cancelAuthentication`](guides/cancel.md) dismisses the prompt.

## iOS and macOS packaging

The plugin now supports **Swift Package Manager** as well as CocoaPods, and compiles with Swift 6. There is nothing to change in your app. Its sources moved to a shared `darwin` folder, which only matters if you referenced files of the plugin by path.

## If you implement or mock the platform interface

`canAuthenticate` and `authenticate` of `FlutterLocalAuthenticationPlatform` have a new named parameter, and there are three new methods: `getAvailability`, `getBiometryType` and `cancelAuthentication`. Update your overrides:

```dart
@override
Future<bool> authenticate({
  AuthenticationMethod method = AuthenticationMethod.biometricsOnly,
}) { ... }
```
