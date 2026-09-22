# Authentication methods

An `AuthenticationMethod` defines **which authenticators the user is allowed to use**. Both `canAuthenticate` and `authenticate` accept it as an optional `method` parameter.

| Method                         | The user authenticates with                                                  |
| ------------------------------ | ---------------------------------------------------------------------------- |
| `biometricsOnly` (default)     | Biometrics only.                                                             |
| `biometricsOrDeviceCredential` | Biometrics, falling back to the device PIN, pattern, passcode or password.   |
| `deviceCredentialOnly`         | The device PIN, pattern, passcode or password only.                          |

```dart
const method = AuthenticationMethod.biometricsOrDeviceCredential;

if (await auth.canAuthenticate(method: method)) {
  await auth.authenticate(method: method);
}
```

!!! tip "Use the same method for both calls"
    `canAuthenticate(method: x)` tells you if `authenticate(method: x)` can work. Checking with one method and authenticating with another gives you an answer about a different prompt.

## Choosing a method

- **Users without enrolled biometrics must be able to get in** → `biometricsOrDeviceCredential`. `canAuthenticate` is `true` as long as the device has a PIN, pattern, passcode or password.
- **Only a biometric match is acceptable** → `biometricsOnly`. Offer another way in (for example your app's own password) when `canAuthenticate` is `false`.
- **You want the device credential and never biometrics** → `deviceCredentialOnly`.

## Platform support

| Method                         | Android            | iOS | macOS | Linux |
| ------------------------------ | ------------------ | --- | ----- | ----- |
| `biometricsOnly`               | ✅                 | ✅  | ✅    | ✅    |
| `biometricsOrDeviceCredential` | ✅                 | ✅  | ✅    | ❌    |
| `deviceCredentialOnly`         | ✅ API 30 or newer | ✅  | ✅    | ❌    |

When a method is **not supported** on the current platform:

- `canAuthenticate` returns `false`.
- `getAvailability` returns `unsupportedMethod`.
- `authenticate` throws an `AuthenticationException` with the reason `unsupportedMethod`.

Because `canAuthenticate` already covers this case, checking it before authenticating is enough. No `Platform` checks are needed.

```dart
Future<AuthenticationMethod?> pickMethod(FlutterLocalAuthentication auth) async {
  const preferred = [
    AuthenticationMethod.biometricsOrDeviceCredential,
    AuthenticationMethod.biometricsOnly,
  ];
  for (final method in preferred) {
    if (await auth.canAuthenticate(method: method)) return method;
  }
  return null; // Local Authentication is not available.
}
```

How each method maps to the native APIs is described in [platform behaviour](../reference/platforms.md).
