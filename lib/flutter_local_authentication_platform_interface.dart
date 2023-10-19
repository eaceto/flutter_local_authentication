import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_local_authentication_method_channel.dart';

/// An abstract platform interface for the Flutter Local Authentication plugin.
///
/// This platform interface defines the methods that must be implemented by
/// platform-specific classes to provide biometric authentication functionality.
///
/// Author: Ezequiel (Kimi) Aceto
/// Email: ezequiel.aceto@gmail.com
/// Website: https://eaceto.dev
abstract class FlutterLocalAuthenticationPlatform extends PlatformInterface {
  FlutterLocalAuthenticationPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterLocalAuthenticationPlatform _instance =
      MethodChannelFlutterLocalAuthentication();

  /// The default instance of [FlutterLocalAuthenticationPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterLocalAuthentication].
  static FlutterLocalAuthenticationPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterLocalAuthenticationPlatform] when
  /// they register themselves.
  static set instance(FlutterLocalAuthenticationPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Checks whether biometric authentication is available on the device.
  ///
  /// Returns `true` if biometric authentication is available, `false` otherwise.
  Future<bool> canAuthenticate() {
    throw UnimplementedError('canAuthenticate() has not been implemented.');
  }

  /// Requests biometric authentication using the Flutter Local Authentication plugin.
  ///
  /// This method triggers a biometric authentication prompt, allowing the user to
  /// authenticate using their fingerprint, face, or other biometric methods
  /// supported by the device. If the user successfully authenticates, the method
  /// returns `true`. If authentication fails or is canceled, it returns `false`.
  Future<bool> authenticate() {
    throw UnimplementedError('authenticate() has not been implemented.');
  }

  /// Sets the allowable reuse duration for Touch ID authentication (iOS only).
  ///
  /// On iOS, this method allows you to specify the allowable duration
  /// for reusing a previously authenticated Touch ID (fingerprint) to unlock an
  /// app or perform secure actions. This duration is specified in seconds.
  Future<double> setTouchIDAuthenticationAllowableReuseDuration(
      double duration) {
    throw UnimplementedError(
        'setTouchIDAuthenticationAllowableReuseDuration() has not been implemented.');
  }

  /// Retrieves the allowable reuse duration for Touch ID authentication (iOS only).
  ///
  /// On iOS, this method allows you to retrieve the allowable duration
  /// for reusing a previously authenticated Touch ID (fingerprint) to unlock an
  /// app or perform secure actions. This duration is specified in seconds.
  Future<double> getTouchIDAuthenticationAllowableReuseDuration() {
    throw UnimplementedError(
        'getTouchIDAuthenticationAllowableReuseDuration() has not been implemented.');
  }

  Future<void> setLocalizationModel(
      Map<String, dynamic> localizationModel) async {
    throw UnimplementedError(
        'setLocalizationModel() has not been implemented.');
  }
}
