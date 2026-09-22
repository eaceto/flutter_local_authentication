# Installation

## Requirements

- Flutter **3.44** or newer
- Dart **3.12** or newer

## Add the dependency

```bash
flutter pub add flutter_local_authentication
```

Or add it to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_local_authentication: ^2.1.0
```

Then run `flutter pub get`.

## Import it

```dart
import 'package:flutter_local_authentication/flutter_local_authentication.dart';
```

This import gives you `FlutterLocalAuthentication` and `AuthenticationMethod`. To localize the prompt also import the localization model:

```dart
import 'package:flutter_local_authentication/localization_model.dart';
```

Next: [set up each platform](platform-setup.md). Android and iOS need a small change before the plugin works.
