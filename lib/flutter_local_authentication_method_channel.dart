import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_local_authentication_platform_interface.dart';

/// An implementation of [FlutterLocalAuthenticationPlatform] that uses method channels.
///
/// Author: Ezequiel (Kimi) Aceto
/// Email: ezequiel.aceto@gmail.com
/// Website: https://eaceto.dev
class MethodChannelFlutterLocalAuthentication
    extends FlutterLocalAuthenticationPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_local_authentication');

  /// Checks whether biometric authentication is available on the device.
  ///
  /// Returns `true` if biometric authentication is available, `false` otherwise.
  /// This method communicates with the native platform to determine if biometric
  /// authentication methods such as fingerprint or face recognition are supported.
  ///
  /// Returns `true` if biometric authentication is available, `false` otherwise.
  ///
  /// Throws an exception if there's an issue checking the device's support for
  /// biometric authentication.
  @override
  Future<bool> canAuthenticate() async {
    return await methodChannel.invokeMethod<bool>('canAuthenticate') ?? false;
  }

  /// Requests biometric authentication using the Flutter Local Authentication plugin.
  ///
  /// This method triggers a biometric authentication prompt, allowing the user to
  /// authenticate using their fingerprint, face, or other biometric methods
  /// supported by the device. If the user successfully authenticates, the method
  /// returns `true`. If authentication fails or is canceled, it returns `false`.
  ///
  /// Note: Biometric authentication must be available on the device, and the user
  /// must have set up biometrics in their device settings for this method to work.
  ///
  /// Returns `true` if authentication succeeds, `false` otherwise.
  ///
  /// Throws an exception if there's an issue with the authentication process.
  @override
  Future<bool> authenticate() async {
    return await methodChannel.invokeMethod<bool>('authenticate') ?? false;
  }

  /// Sets the allowable reuse duration for Touch ID authentication (iOS only).
  ///
  /// On iOS, this method allows you to specify the allowable duration
  /// for reusing a previously authenticated Touch ID (fingerprint) to unlock an
  /// app or perform secure actions. This duration is specified in seconds.
  ///
  /// This method is applicable only to iOS platforms. On other platforms, it returns `0.0`.
  ///
  /// Parameters:
  ///
  /// - `duration`: The allowable reuse duration in seconds.
  ///
  /// Returns a [Future] with a `double` value representing the allowable reuse
  /// duration. If the operation is successful, it returns the specified `duration`
  /// value. If the method is not supported on the current platform, it returns `0.0`.
  ///
  /// Throws an exception if there's an issue with setting the allowable reuse
  /// duration or if it's not supported on the current platform.
  @override
  Future<double> setTouchIDAuthenticationAllowableReuseDuration(
      double duration) async {
    return await methodChannel.invokeMethod<double>(
            'setTouchIDAuthenticationAllowableReuseDuration',
            {"duration": duration}) ??
        0.0;
  }

  /// Retrieves the allowable reuse duration for Touch ID authentication (iOS only).
  ///
  /// On iOS, this method allows you to retrieve the allowable duration
  /// for reusing a previously authenticated Touch ID (fingerprint) to unlock an
  /// app or perform secure actions. This duration is specified in seconds.
  ///
  /// This method is applicable only to iOS platforms. On other platforms, it returns `0.0`.
  ///
  /// Returns a [Future] with a `double` value representing the allowable reuse
  /// duration. If the operation is successful, it returns the specified duration
  /// value previously set using [setTouchIDAuthenticationAllowableReuseDuration].
  /// If the method is not supported on the current platform or no duration has
  /// been set, it returns `0.0`.
  ///
  /// Throws an exception if there's an issue with retrieving the allowable reuse
  /// duration or if it's not supported on the current platform.
  @override
  Future<double> getTouchIDAuthenticationAllowableReuseDuration() async {
    return await methodChannel.invokeMethod<double>(
            'getTouchIDAuthenticationAllowableReuseDuration') ??
        0.0;
  }
}
