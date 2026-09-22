import 'package:flutter/services.dart';
import 'package:flutter_local_authentication/flutter_local_authentication.dart';
import 'package:flutter_local_authentication/flutter_local_authentication_method_channel.dart';
import 'package:flutter_local_authentication/flutter_local_authentication_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterLocalAuthenticationPlatform
    with MockPlatformInterfaceMixin
    implements FlutterLocalAuthenticationPlatform {
  final _canAuthenticate = true;
  double _touchIDAuthenticationAllowableReuseDuration = 0.0;
  AuthenticationMethod? lastMethod;

  /// What [authenticate] does: returns the value, or throws it when it is an exception.
  Object authenticateOutcome = true;

  @override
  Future<bool> authenticate({
    AuthenticationMethod method = AuthenticationMethod.biometricsOnly,
  }) async {
    lastMethod = method;
    final outcome = authenticateOutcome;
    if (outcome is Exception) throw outcome;
    return outcome as bool;
  }

  @override
  Future<AuthenticationAvailability> getAvailability({
    AuthenticationMethod method = AuthenticationMethod.biometricsOnly,
  }) {
    lastMethod = method;
    return Future.value(AuthenticationAvailability.notEnrolled);
  }

  @override
  Future<BiometryType> getBiometryType() => Future.value(BiometryType.face);

  @override
  Future<bool> cancelAuthentication() => Future.value(true);

  @override
  Future<double> getTouchIDAuthenticationAllowableReuseDuration() =>
      Future.value(_touchIDAuthenticationAllowableReuseDuration);

  @override
  Future<double> setTouchIDAuthenticationAllowableReuseDuration(
    double duration,
  ) {
    _touchIDAuthenticationAllowableReuseDuration = duration;
    return Future.value(_touchIDAuthenticationAllowableReuseDuration);
  }

  @override
  Future<bool> canAuthenticate({
    AuthenticationMethod method = AuthenticationMethod.biometricsOnly,
  }) {
    lastMethod = method;
    return Future.value(_canAuthenticate);
  }

  @override
  Future<void> setLocalizationModel(Map<String, dynamic> localizationModel) =>
      Future.value();
}

void main() {
  final FlutterLocalAuthenticationPlatform initialPlatform =
      FlutterLocalAuthenticationPlatform.instance;

  test('$MethodChannelFlutterLocalAuthentication is the default instance', () {
    expect(
      initialPlatform,
      isInstanceOf<MethodChannelFlutterLocalAuthentication>(),
    );
  });

  test('canAuthenticate', () async {
    FlutterLocalAuthentication flutterLocalAuthenticationPlugin =
        FlutterLocalAuthentication();
    MockFlutterLocalAuthenticationPlatform fakePlatform =
        MockFlutterLocalAuthenticationPlatform();
    FlutterLocalAuthenticationPlatform.instance = fakePlatform;

    expect(await flutterLocalAuthenticationPlugin.canAuthenticate(), true);
  });

  test('authenticate', () async {
    FlutterLocalAuthentication flutterLocalAuthenticationPlugin =
        FlutterLocalAuthentication();
    MockFlutterLocalAuthenticationPlatform fakePlatform =
        MockFlutterLocalAuthenticationPlatform();
    FlutterLocalAuthenticationPlatform.instance = fakePlatform;

    expect(await flutterLocalAuthenticationPlugin.authenticate(), true);
  });

  test('authentication method defaults to biometricsOnly', () async {
    FlutterLocalAuthentication flutterLocalAuthenticationPlugin =
        FlutterLocalAuthentication();
    MockFlutterLocalAuthenticationPlatform fakePlatform =
        MockFlutterLocalAuthenticationPlatform();
    FlutterLocalAuthenticationPlatform.instance = fakePlatform;

    await flutterLocalAuthenticationPlugin.canAuthenticate();
    expect(fakePlatform.lastMethod, AuthenticationMethod.biometricsOnly);

    fakePlatform.lastMethod = null;
    await flutterLocalAuthenticationPlugin.authenticate();
    expect(fakePlatform.lastMethod, AuthenticationMethod.biometricsOnly);
  });

  test('authentication method is forwarded to the platform', () async {
    FlutterLocalAuthentication flutterLocalAuthenticationPlugin =
        FlutterLocalAuthentication();
    MockFlutterLocalAuthenticationPlatform fakePlatform =
        MockFlutterLocalAuthenticationPlatform();
    FlutterLocalAuthenticationPlatform.instance = fakePlatform;

    await flutterLocalAuthenticationPlugin.canAuthenticate(
      method: AuthenticationMethod.biometricsOrDeviceCredential,
    );
    expect(
      fakePlatform.lastMethod,
      AuthenticationMethod.biometricsOrDeviceCredential,
    );

    await flutterLocalAuthenticationPlugin.authenticate(
      method: AuthenticationMethod.deviceCredentialOnly,
    );
    expect(fakePlatform.lastMethod, AuthenticationMethod.deviceCredentialOnly);
  });

  group('authenticate errors', () {
    late FlutterLocalAuthentication plugin;
    late MockFlutterLocalAuthenticationPlatform fakePlatform;

    setUp(() {
      plugin = FlutterLocalAuthentication();
      fakePlatform = MockFlutterLocalAuthenticationPlatform();
      FlutterLocalAuthenticationPlatform.instance = fakePlatform;
    });

    Future<AuthenticationException> failure() async {
      try {
        await plugin.authenticate();
      } on AuthenticationException catch (exception) {
        return exception;
      }
      fail('authenticate did not throw');
    }

    test('maps the reason sent by the platform', () async {
      fakePlatform.authenticateOutcome = PlatformException(
        code: 'authentication_error',
        message: 'Canceled by user.',
        details: {'reason': 'userCanceled', 'errorCode': 10},
      );

      final exception = await failure();
      expect(exception.reason, AuthenticationErrorReason.userCanceled);
      expect(exception.isCanceled, true);
      expect(exception.code, 'authentication_error');
      expect(exception.message, 'Canceled by user.');
      expect(exception.details['errorCode'], 10);
    });

    test('is still a PlatformException', () async {
      fakePlatform.authenticateOutcome = PlatformException(
        code: 'authentication_error',
        details: {'reason': 'lockedOut'},
      );

      expect(plugin.authenticate(), throwsA(isA<PlatformException>()));
    });

    test('maps the unsupported method error code', () async {
      fakePlatform.authenticateOutcome = PlatformException(
        code: unsupportedAuthenticationMethodErrorCode,
      );

      final exception = await failure();
      expect(exception.reason, AuthenticationErrorReason.unsupportedMethod);
      expect(exception.code, unsupportedAuthenticationMethodErrorCode);
    });

    test(
      'falls back to failed when the reason is missing or unknown',
      () async {
        fakePlatform.authenticateOutcome = PlatformException(
          code: 'authentication_error',
        );
        expect((await failure()).reason, AuthenticationErrorReason.failed);

        fakePlatform.authenticateOutcome = PlatformException(
          code: 'authentication_error',
          details: {'reason': 'somethingNew'},
        );
        expect((await failure()).reason, AuthenticationErrorReason.failed);
      },
    );

    test('throws failed when the platform answers false', () async {
      fakePlatform.authenticateOutcome = false;

      final exception = await failure();
      expect(exception.reason, AuthenticationErrorReason.failed);
      expect(exception.isCanceled, false);
    });
  });

  test('getAvailability', () async {
    FlutterLocalAuthentication flutterLocalAuthenticationPlugin =
        FlutterLocalAuthentication();
    MockFlutterLocalAuthenticationPlatform fakePlatform =
        MockFlutterLocalAuthenticationPlatform();
    FlutterLocalAuthenticationPlatform.instance = fakePlatform;

    expect(
      await flutterLocalAuthenticationPlugin.getAvailability(
        method: AuthenticationMethod.deviceCredentialOnly,
      ),
      AuthenticationAvailability.notEnrolled,
    );
    expect(fakePlatform.lastMethod, AuthenticationMethod.deviceCredentialOnly);
  });

  test('getBiometryType and cancelAuthentication', () async {
    FlutterLocalAuthentication flutterLocalAuthenticationPlugin =
        FlutterLocalAuthentication();
    FlutterLocalAuthenticationPlatform.instance =
        MockFlutterLocalAuthenticationPlatform();

    expect(
      await flutterLocalAuthenticationPlugin.getBiometryType(),
      BiometryType.face,
    );
    expect(await flutterLocalAuthenticationPlugin.cancelAuthentication(), true);
  });

  test('touchIDAuthenticationAllowableReuseDuration', () async {
    FlutterLocalAuthentication flutterLocalAuthenticationPlugin =
        FlutterLocalAuthentication();
    MockFlutterLocalAuthenticationPlatform fakePlatform =
        MockFlutterLocalAuthenticationPlatform();
    FlutterLocalAuthenticationPlatform.instance = fakePlatform;

    double stored = await flutterLocalAuthenticationPlugin
        .setTouchIDAuthenticationAllowableReuseDuration(30.0);

    expect(stored, 30.0);

    stored = await flutterLocalAuthenticationPlugin
        .setTouchIDAuthenticationAllowableReuseDuration(45.0);

    expect(stored, 45.0);
  });
}
