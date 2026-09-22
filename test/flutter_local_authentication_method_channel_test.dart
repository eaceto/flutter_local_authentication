import 'package:flutter/services.dart';
import 'package:flutter_local_authentication/authentication_availability.dart';
import 'package:flutter_local_authentication/authentication_method.dart';
import 'package:flutter_local_authentication/biometry_type.dart';
import 'package:flutter_local_authentication/flutter_local_authentication_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFlutterLocalAuthentication platform =
      MethodChannelFlutterLocalAuthentication();
  const MethodChannel channel = MethodChannel('flutter_local_authentication');

  double testTouchIDAuthenticationAllowableReuseDuration = 0.0;
  final List<MethodCall> log = <MethodCall>[];
  String? availabilityAnswer;
  String? biometryTypeAnswer;

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case "canAuthenticate":
              return true;
            case "authenticate":
              if (methodCall.arguments["method"] == "deviceCredentialOnly") {
                throw PlatformException(
                  code: unsupportedAuthenticationMethodErrorCode,
                );
              }
              return true;
            case "getAvailability":
              return availabilityAnswer;
            case "getBiometryType":
              return biometryTypeAnswer;
            case "cancelAuthentication":
              return true;
            case "setTouchIDAuthenticationAllowableReuseDuration":
              {
                testTouchIDAuthenticationAllowableReuseDuration =
                    methodCall.arguments["duration"];
                return testTouchIDAuthenticationAllowableReuseDuration;
              }
            case "getTouchIDAuthenticationAllowableReuseDuration":
              return testTouchIDAuthenticationAllowableReuseDuration;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('canAuthenticate', () async {
    expect(await platform.canAuthenticate(), true);
  });

  test('authenticate', () async {
    expect(await platform.authenticate(), true);
  });

  test('sends biometricsOnly by default', () async {
    await platform.canAuthenticate();
    await platform.authenticate();

    expect(log.map((call) => call.arguments), [
      {'method': 'biometricsOnly'},
      {'method': 'biometricsOnly'},
    ]);
  });

  test('sends the requested authentication method', () async {
    await platform.canAuthenticate(
      method: AuthenticationMethod.deviceCredentialOnly,
    );
    await platform.authenticate(
      method: AuthenticationMethod.biometricsOrDeviceCredential,
    );

    expect(log.map((call) => '${call.method}:${call.arguments['method']}'), [
      'canAuthenticate:deviceCredentialOnly',
      'authenticate:biometricsOrDeviceCredential',
    ]);
  });

  test('surfaces the unsupported method error', () async {
    expect(
      () => platform.authenticate(
        method: AuthenticationMethod.deviceCredentialOnly,
      ),
      throwsA(
        isA<PlatformException>().having(
          (e) => e.code,
          'code',
          unsupportedAuthenticationMethodErrorCode,
        ),
      ),
    );
  });

  test('getAvailability parses the platform answer', () async {
    availabilityAnswer = 'credentialNotSet';
    expect(
      await platform.getAvailability(
        method: AuthenticationMethod.biometricsOrDeviceCredential,
      ),
      AuthenticationAvailability.credentialNotSet,
    );
    expect(log.last.arguments, {'method': 'biometricsOrDeviceCredential'});

    for (final availability in AuthenticationAvailability.values) {
      availabilityAnswer = availability.name;
      expect(await platform.getAvailability(), availability);
    }
  });

  test('getAvailability treats an unknown answer as notAvailable', () async {
    availabilityAnswer = 'somethingNew';
    expect(
      await platform.getAvailability(),
      AuthenticationAvailability.notAvailable,
    );

    availabilityAnswer = null;
    expect(
      await platform.getAvailability(),
      AuthenticationAvailability.notAvailable,
    );
  });

  test('getBiometryType parses the platform answer', () async {
    for (final biometryType in BiometryType.values) {
      biometryTypeAnswer = biometryType.name;
      expect(await platform.getBiometryType(), biometryType);
    }

    biometryTypeAnswer = 'somethingNew';
    expect(await platform.getBiometryType(), BiometryType.none);
  });

  test('cancelAuthentication', () async {
    expect(await platform.cancelAuthentication(), true);
    expect(log.last.method, 'cancelAuthentication');
  });

  test('set_get_TouchIDAuthenticationAllowableReuseDuration', () async {
    expect(
      await platform.setTouchIDAuthenticationAllowableReuseDuration(30.0),
      30.0,
    );
    expect(
      await platform.getTouchIDAuthenticationAllowableReuseDuration(),
      30.0,
    );
  });
}
