# Dismissing the prompt

`cancelAuthentication` dismisses the prompt that is being shown. The pending `authenticate` call fails with an `AuthenticationException` whose reason is `systemCanceled`.

A common use is to dismiss the prompt when the app moves to the background, so the user does not find a stale prompt when coming back:

```dart
class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final _auth = FlutterLocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _auth.cancelAuthentication();
    }
  }

  Future<void> _unlock() async {
    try {
      await _auth.authenticate();
      // Authenticated.
    } on AuthenticationException catch (error) {
      if (error.isCanceled) return; // Dismissed, nothing to report.
      // Handle the other reasons.
    }
  }
}
```

It returns `true` if there was a prompt to dismiss, and `false` otherwise. Calling it when nothing is shown is safe.

| Platform    | Behaviour                                                                            |
| ----------- | ------------------------------------------------------------------------------------ |
| Android     | Calls `BiometricPrompt.cancelAuthentication`.                                        |
| iOS / macOS | Invalidates the `LAContext` of the authentication in progress.                       |
| Linux       | Not supported, it always returns `false`. `fprintd-verify` can not be interrupted.   |
