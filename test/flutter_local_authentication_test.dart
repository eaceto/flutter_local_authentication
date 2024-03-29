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

  @override
  Future<bool> authenticate() => Future.value(_canAuthenticate);

  @override
  Future<double> getTouchIDAuthenticationAllowableReuseDuration() =>
      Future.value(_touchIDAuthenticationAllowableReuseDuration);

  @override
  Future<double> setTouchIDAuthenticationAllowableReuseDuration(
      double duration) {
    _touchIDAuthenticationAllowableReuseDuration = duration;
    return Future.value(_touchIDAuthenticationAllowableReuseDuration);
  }

  @override
  Future<bool> canAuthenticate() => Future.value(_canAuthenticate);

  @override
  Future<void> setLocalizationModel(Map<String, dynamic> localizationModel) =>
      Future.value();
}

void main() {
  final FlutterLocalAuthenticationPlatform initialPlatform =
      FlutterLocalAuthenticationPlatform.instance;

  test('$MethodChannelFlutterLocalAuthentication is the default instance', () {
    expect(initialPlatform,
        isInstanceOf<MethodChannelFlutterLocalAuthentication>());
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
