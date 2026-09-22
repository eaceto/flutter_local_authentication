# Touch ID reuse duration

On **iOS and macOS**, a user who just unlocked the device with Touch ID can be considered authenticated without a new prompt. The _allowable reuse duration_ is how many seconds after the unlock this is accepted. It maps to [`LAContext.touchIDAuthenticationAllowableReuseDuration`](https://developer.apple.com/documentation/localauthentication/lacontext/touchidauthenticationallowablereuseduration).

```dart
// Accept a device unlock that happened in the last 30 seconds.
final stored = await auth.setTouchIDAuthenticationAllowableReuseDuration(30);

final current = await auth.getTouchIDAuthenticationAllowableReuseDuration();
```

- The default is `0`: the user is always prompted.
- The system caps the value at 5 minutes (`LATouchIDAuthenticationMaximumAllowableReuseDuration`). The setter returns the value that was stored.
- It applies to **any** successful Touch ID authentication on the device within the interval: a device unlock, or a previous prompt of your app. With the default of `0` every `authenticate` call prompts the user.
- It only concerns Touch ID. Face ID, Optic ID and the device credential always prompt.

Both functions are safe to call on every platform. Outside iOS and macOS the setter returns the value it was given and the getter returns `0`.
