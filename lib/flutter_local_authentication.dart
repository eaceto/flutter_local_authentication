import 'dart:io';

import 'package:flutter_local_authentication/localization_model.dart';

import 'package:flutter/services.dart';

import 'authentication_availability.dart';
import 'authentication_exception.dart';
import 'authentication_method.dart';
import 'biometry_type.dart';
import 'flutter_local_authentication_platform_interface.dart';

export 'authentication_availability.dart';
export 'authentication_exception.dart';
export 'authentication_method.dart';
export 'biometry_type.dart';

/// A Flutter plugin for local biometric authentication.
///
/// This plugin provides a simple way to perform biometric authentication, such
/// as fingerprint or face recognition, on supported devices and platforms.
///
/// Author: Ezequiel (Kimi) Aceto
/// Email: ezequiel.aceto@gmail.com
/// Website: https://kimi.blog
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
  /// Parameters:
  ///
  /// - `method`: The authenticators the user is allowed to use. Defaults to
  ///   [AuthenticationMethod.biometricsOnly]. Use the same value when calling
  ///   [authenticate]. If the current platform does not support the requested
  ///   method, this returns `false`.
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
  Future<bool> canAuthenticate({
    AuthenticationMethod method = AuthenticationMethod.biometricsOnly,
  }) async {
    final isSupported = await FlutterLocalAuthenticationPlatform.instance
        .canAuthenticate(method: method);
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
  /// Parameters:
  ///
  /// - `method`: The authenticators the user is allowed to use. Defaults to
  ///   [AuthenticationMethod.biometricsOnly]. Pass
  ///   [AuthenticationMethod.biometricsOrDeviceCredential] to let users without
  ///   enrolled biometrics authenticate with their PIN, pattern or password.
  ///
  /// Returns `true` if authentication succeeds.
  ///
  /// Throws an [AuthenticationException] if the user is not authenticated. Its
  /// `reason` tells what happened: the user canceled, biometrics are locked out,
  /// the platform does not support the requested `method`, ...
  ///
  /// See also:
  ///
  /// - [Flutter Local Authentication Plugin](https://pub.dev/packages/flutter_local_authentication)
  ///
  /// Note: This method may not be available on all platforms or versions of
  /// Flutter. Make sure to check for platform compatibility before using it.
  Future<bool> authenticate({
    AuthenticationMethod method = AuthenticationMethod.biometricsOnly,
  }) async {
    final bool isAuthenticated;
    try {
      isAuthenticated = await FlutterLocalAuthenticationPlatform.instance
          .authenticate(method: method);
    } on AuthenticationException {
      rethrow;
    } on PlatformException catch (exception) {
      throw AuthenticationException.fromPlatformException(exception);
    }
    if (isAuthenticated == true) {
      return true;
    } else {
      throw AuthenticationException(
        reason: AuthenticationErrorReason.failed,
        message: 'Authentication failed or was canceled.',
      );
    }
  }

  /// Tells whether the user can authenticate with a method, and why not.
  ///
  /// It is the detailed version of [canAuthenticate], which returns `true` only
  /// when the availability is [AuthenticationAvailability.available]. Use it to
  /// react to the reason, for example by falling back to
  /// [AuthenticationMethod.biometricsOrDeviceCredential] when the user has no
  /// enrolled biometrics, or by asking them to enroll.
  ///
  /// Parameters:
  ///
  /// - `method`: The authenticators the user is allowed to use. Defaults to
  ///   [AuthenticationMethod.biometricsOnly].
  ///
  /// Example usage:
  ///
  /// ```dart
  /// switch (await getAvailability()) {
  ///   case AuthenticationAvailability.available:
  ///     // Offer biometric authentication
  ///   case AuthenticationAvailability.notEnrolled:
  ///     // Ask the user to enroll, or allow the device credential
  ///   default:
  ///     // Provide an alternative authentication method
  /// }
  /// ```
  Future<AuthenticationAvailability> getAvailability({
    AuthenticationMethod method = AuthenticationMethod.biometricsOnly,
  }) {
    return FlutterLocalAuthenticationPlatform.instance.getAvailability(
      method: method,
    );
  }

  /// Returns the kind of biometrics of the device.
  ///
  /// Use it to label your UI, for example "Unlock with Face ID". On Android the
  /// platform only tells which hardware the device has, and it returns
  /// [BiometryType.multiple] when there is more than one kind.
  ///
  /// Returns [BiometryType.none] when the device has no biometrics.
  Future<BiometryType> getBiometryType() {
    return FlutterLocalAuthenticationPlatform.instance.getBiometryType();
  }

  /// Dismisses the authentication prompt that is being shown, if any.
  ///
  /// The pending [authenticate] call fails with an [AuthenticationException]
  /// whose reason is [AuthenticationErrorReason.systemCanceled]. Call it, for
  /// example, when your app moves to the background.
  ///
  /// Returns `true` if there was a prompt to dismiss, `false` otherwise. It is
  /// not supported on Linux, where it always returns `false`.
  Future<bool> cancelAuthentication() {
    return FlutterLocalAuthenticationPlatform.instance.cancelAuthentication();
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
    double duration,
  ) async {
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
  Future<void> setLocalizationModel(LocalizationModel localizationModel) async {
    if (Platform.isIOS || Platform.isMacOS || Platform.isAndroid) {
      await FlutterLocalAuthenticationPlatform.instance.setLocalizationModel(
        localizationModel.toJson(),
      );
    }
  }
}
