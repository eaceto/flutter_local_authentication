import 'dart:io';

import 'package:flutter_local_authentication/localization_model.dart';

import 'flutter_local_authentication_platform_interface.dart';

/// A Flutter plugin for local biometric authentication.
///
/// This plugin provides a simple way to perform biometric authentication, such
/// as fingerprint or face recognition, on supported devices and platforms.
///
/// Author: Ezequiel (Kimi) Aceto
/// Email: ezequiel.aceto@gmail.com
/// Website: https://eaceto.dev
class FlutterLocalAuthentication {
  /// Checks whether biometric authentication is supported on the device.
  ///
  /// This method queries the device's capabilities to determine whether biometric
  /// authentication methods, such as fingerprint or face recognition, are available
  /// and supported. It returns `true` if biometric authentication is supported,
  /// and `false` otherwise.
  ///
  /// Note: The availability of biometric authentication can vary by device and
  /// platform, and the user must have set up biometrics in their device settings
  /// for this method to return `true`.
  ///
  /// Returns `true` if biometric authentication is supported, `false` otherwise.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// bool isBiometricSupported = await canAuthenticate();
  /// if (isBiometricSupported) {
  ///   // Display biometric authentication option
  /// } else {
  ///   // Provide an alternative authentication method
  /// }
  /// ```
  ///
  /// Throws an exception if there's an issue checking the device's support for
  /// biometric authentication.
  ///
  /// See also:
  ///
  /// - [Flutter Local Authentication Plugin](https://pub.dev/packages/flutter_local_authentication)
  ///
  /// Note: This method may not be available on all platforms or versions of
  /// Flutter. Make sure to check for platform compatibility before using it.
  Future<bool> canAuthenticate() async {
    final isSupported =
        await FlutterLocalAuthenticationPlatform.instance.canAuthenticate();
    return isSupported == true;
  }

  /// Requests biometric authentication using the Flutter Local Authentication plugin.
  ///
  /// This method triggers a biometric authentication prompt, allowing the user to
  /// authenticate using their fingerprint, face, or other biometric methods
  /// supported by the device. If the user successfully authenticates, the method
  /// returns `true`. If authentication fails or is canceled, it throws an error.
  ///
  /// Note: Biometric authentication must be supported on the device, and the user
  /// must have set up biometrics in their device settings for this method to work.
  ///
  /// Returns `true` if authentication succeeds.
  ///
  /// Throws an exception if there's an issue with the authentication process.
  ///
  /// See also:
  ///
  /// - [Flutter Local Authentication Plugin](https://pub.dev/packages/flutter_local_authentication)
  ///
  /// Note: This method may not be available on all platforms or versions of
  /// Flutter. Make sure to check for platform compatibility before using it.
  Future<bool> authenticate() async {
    final isAuthenticated =
        await FlutterLocalAuthenticationPlatform.instance.authenticate();
    if (isAuthenticated == true) {
      return true;
    } else {
      throw Exception('Authentication failed or was canceled.');
    }
  }

  /// Sets the allowable reuse duration for Touch ID authentication (iOS/macOS only).
  ///
  /// On iOS and macOS, this method allows you to specify the allowable duration
  /// for reusing a previously authenticated Touch ID (fingerprint) to unlock an
  /// app or perform secure actions. This duration is specified in seconds.
  ///
  /// This method is applicable only to iOS and macOS platforms. On other
  /// platforms, it throws an error indicating that the method is not supported.
  ///
  /// Parameters:
  ///
  /// - `duration`: The allowable reuse duration in seconds.
  ///
  /// Returns a [Future] with a `double` value representing the allowable reuse
  /// duration. If the operation is successful, it returns the specified `duration`
  /// value. If the method is not supported on the current platform, it throws an error.
  ///
  /// Example usage (iOS/macOS):
  ///
  /// ```dart
  /// double allowableReuseDuration = 30.0; // 30 seconds
  /// double result = await setTouchIDAuthenticationAllowableReuseDuration(allowableReuseDuration);
  /// // Allowable reuse duration set successfully
  /// ```
  ///
  /// Throws an exception if there's an issue with setting the allowable reuse
  /// duration.
  ///
  /// Note: This method may not be available on all versions of iOS or macOS, so
  /// it's important to check for platform compatibility before using it.
  Future<double> setTouchIDAuthenticationAllowableReuseDuration(
      double duration) async {
    if (Platform.isIOS || Platform.isMacOS) {
      return await FlutterLocalAuthenticationPlatform.instance
          .setTouchIDAuthenticationAllowableReuseDuration(duration);
    }
    return Future.value(duration);
  }

  /// Retrieves the allowable reuse duration for Touch ID authentication (iOS/macOS only).
  ///
  /// On iOS and macOS, this method allows you to retrieve the allowable duration
  /// for reusing a previously authenticated Touch ID (fingerprint) to unlock an
  /// app or perform secure actions. This duration is specified in seconds.
  ///
  /// This method is applicable only to iOS and macOS platforms. On other
  /// platforms, it throws an error indicating that the method is not supported.
  ///
  /// Returns a [Future] with a `double` value representing the allowable reuse
  /// duration. If the operation is successful, it returns the specified duration
  /// value previously set using [setTouchIDAuthenticationAllowableReuseDuration].
  ///
  /// Example usage (iOS/macOS):
  ///
  /// ```dart
  /// double allowableReuseDuration = await getTouchIDAuthenticationAllowableReuseDuration();
  /// // Allowable reuse duration retrieved successfully
  /// print("Allowable reuse duration: $allowableReuseDuration seconds");
  /// ```
  ///
  /// Throws an exception if there's an issue with retrieving the allowable reuse
  /// duration.
  ///
  /// Note: This method may not be available on all versions of iOS or macOS, so
  /// it's important to check for platform compatibility before using it.
  Future<double> getTouchIDAuthenticationAllowableReuseDuration() async {
    if (Platform.isIOS || Platform.isMacOS) {
      return await FlutterLocalAuthenticationPlatform.instance
          .getTouchIDAuthenticationAllowableReuseDuration();
    }
    return Future.value(0.0);
  }

  /// Sets the [LocalizationModel] for the Flutter Local Authentication plugin.
  ///
  /// This method allows you to specify a [LocalizationModel] to customize
  /// the localized strings used in the biometric authentication prompts.
  ///
  /// Parameters:
  ///
  /// - `localizationModel`: A [LocalizationModel] containing the customized
  ///   strings for localization.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// LocalizationModel customLocalization = LocalizationModel(
  ///   promptDialogTitle: 'Custom Title',
  ///   promptDialogReason: 'Custom Reason',
  ///   cancelButtonTitle: 'Custom Cancel',
  /// );
  ///
  /// flutterLocalAuthentication.setLocalizationModel(customLocalization);
  /// ```
  ///
  /// Note: If you do not set a [LocalizationModel], the plugin will use
  /// default localized strings in English.
  void setLocalizationModel(LocalizationModel localizationModel) async {
    if (Platform.isIOS || Platform.isMacOS || Platform.isAndroid) {
      await FlutterLocalAuthenticationPlatform.instance.setLocalizationModel(localizationModel.toJson());
    }
  }

  Future<void> setBiometricsRequired(
      bool biometricsRequired) async {
    if (Platform.isIOS) {
      return await FlutterLocalAuthenticationPlatform.instance
          .setBiometricsRequired(biometricsRequired);
    }
  }
}
