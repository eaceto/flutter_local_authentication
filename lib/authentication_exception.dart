import 'package:flutter/services.dart';

import 'authentication_method.dart';

/// The reason why the user was not authenticated.
enum AuthenticationErrorReason {
  /// The user dismissed the prompt.
  userCanceled,

  /// The system dismissed the prompt, for example because the app moved to the
  /// background, or the app did it by calling `cancelAuthentication`.
  systemCanceled,

  /// Biometrics are locked out after too many failed attempts.
  lockedOut,

  /// The user did not enroll any biometrics.
  notEnrolled,

  /// The device has no hardware for the method, or it can not be used right now.
  notAvailable,

  /// The device has no PIN, pattern, passcode or password, and the method needs it.
  credentialNotSet,

  /// The platform does not support the requested `AuthenticationMethod`.
  unsupportedMethod,

  /// The user could not be authenticated, or the reason is unknown.
  failed,
}

/// Thrown by `authenticate` when the user was not authenticated.
///
/// It is a [PlatformException], so existing `on PlatformException` handlers keep
/// working. The [code] is the one sent by the platform (`authentication_error`
/// or [unsupportedAuthenticationMethodErrorCode]), the [message] is the
/// platform's localized description, and [reason] tells what happened in the
/// same way on every platform.
class AuthenticationException extends PlatformException {
  /// Creates an exception with the [reason] why the user was not authenticated.
  AuthenticationException({
    required this.reason,
    super.code = authenticationErrorCode,
    super.message,
    super.details,
    super.stacktrace,
  });

  /// Creates an exception from the error reported by the platform.
  factory AuthenticationException.fromPlatformException(
    PlatformException exception,
  ) {
    return AuthenticationException(
      reason: _reasonOf(exception),
      code: exception.code,
      message: exception.message,
      details: exception.details,
      stacktrace: exception.stacktrace,
    );
  }

  /// The error code used by the platforms when the user was not authenticated.
  static const String authenticationErrorCode = 'authentication_error';

  /// The reason why the user was not authenticated.
  final AuthenticationErrorReason reason;

  /// Whether the prompt was dismissed, by the user, the system or the app.
  bool get isCanceled =>
      reason == AuthenticationErrorReason.userCanceled ||
      reason == AuthenticationErrorReason.systemCanceled;

  static AuthenticationErrorReason _reasonOf(PlatformException exception) {
    if (exception.code == unsupportedAuthenticationMethodErrorCode) {
      return AuthenticationErrorReason.unsupportedMethod;
    }
    final details = exception.details;
    final name = details is Map ? details['reason'] : null;
    return AuthenticationErrorReason.values.firstWhere(
      (reason) => reason.name == name,
      orElse: () => AuthenticationErrorReason.failed,
    );
  }

  @override
  String toString() =>
      'AuthenticationException(${reason.name}, $code, $message, $details)';
}
