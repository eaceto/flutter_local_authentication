# Quick start

## 1. Create the plugin

```dart
final auth = FlutterLocalAuthentication();
```

The object is cheap to create and has no state of its own. Keep one instance around, for example as a field of your `State`.

## 2. Check that the user can authenticate

```dart
bool canAuthenticate;
try {
  canAuthenticate = await auth.canAuthenticate();
} on Exception catch (error) {
  debugPrint('Could not check the support for Local Authentication. $error');
  canAuthenticate = false;
}
```

`canAuthenticate` is `false` when the device has no biometric hardware, or when the user did not enroll any biometrics. In that case hide the option, or [allow the device credential](../guides/authentication-methods.md). To know the exact reason use [`getAvailability`](../guides/availability.md).

## 3. Authenticate

```dart
try {
  await auth.authenticate();
  // The user is authenticated.
} on AuthenticationException catch (error) {
  // The user canceled, is locked out, failed to authenticate...
  debugPrint('Not authenticated: ${error.reason.name}');
}
```

`authenticate` returns `true` when the user is authenticated, and **throws** an `AuthenticationException` otherwise. Its `reason` tells what happened. See [error handling](../guides/error-handling.md).

## Complete example

```dart
import 'package:flutter/material.dart';
import 'package:flutter_local_authentication/flutter_local_authentication.dart';

class UnlockButton extends StatefulWidget {
  const UnlockButton({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  State<UnlockButton> createState() => _UnlockButtonState();
}

class _UnlockButtonState extends State<UnlockButton> {
  static const _method = AuthenticationMethod.biometricsOrDeviceCredential;

  final _auth = FlutterLocalAuthentication();
  bool _canAuthenticate = false;

  @override
  void initState() {
    super.initState();
    _checkSupport();
  }

  Future<void> _checkSupport() async {
    final canAuthenticate = await _auth.canAuthenticate(method: _method);
    if (!mounted) return;
    setState(() => _canAuthenticate = canAuthenticate);
  }

  Future<void> _unlock() async {
    try {
      await _auth.authenticate(method: _method);
      widget.onUnlocked();
    } on AuthenticationException catch (error) {
      if (error.isCanceled || !mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not verify your identity')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _canAuthenticate ? _unlock : null,
      child: const Text('Unlock'),
    );
  }
}
```

A runnable app lives in the [`example`](https://github.com/eaceto/flutter_local_authentication/tree/main/example) folder of the repository.
