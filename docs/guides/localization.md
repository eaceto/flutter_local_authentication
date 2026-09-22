# Localization

The texts of the native prompt are set with a `LocalizationModel`. Set it once, for example when your widget is created, and again whenever the language of your app changes. The latest model is used for every following prompt.

```dart
import 'package:flutter_local_authentication/localization_model.dart';

auth.setLocalizationModel(
  LocalizationModel(
    promptDialogTitle: 'Unlock your vault',
    promptDialogReason: 'Confirm that it is you',
    cancelButtonTitle: 'Cancel',
  ),
);
```

## Where each text is shown

| Field                | Android                     | iOS / macOS                         | Linux |
| -------------------- | --------------------------- | ----------------------------------- | ----- |
| `promptDialogTitle`  | Title of the prompt         | Not used, the system sets the title | —     |
| `promptDialogReason` | Subtitle of the prompt      | Reason shown in the prompt          | —     |
| `cancelButtonTitle`  | Negative button<sup>1</sup> | Cancel button                       | —     |

<sup>1</sup> Android does not show a negative button when the device credential is an allowed authenticator (`biometricsOrDeviceCredential` and `deviceCredentialOnly`). The system provides its own way to cancel.

## Defaults

Without a model the prompt uses the title _"Biometric Prompt"_ (Android), the reason _"Validate that you have access to this device."_ and the cancel button _"Cancel"_.

!!! warning "Android needs a title"
    Android rejects a prompt with an empty title, and an empty negative button when that button is shown. Always give `promptDialogTitle` and `cancelButtonTitle` a text.

!!! note "Face ID"
    On iOS the text of the Face ID permission alert comes from `NSFaceIDUsageDescription` in your `Info.plist`, not from the model. Localize it with an `InfoPlist.strings` file.
