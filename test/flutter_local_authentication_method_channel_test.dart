import 'package:flutter/services.dart';
import 'package:flutter_local_authentication/flutter_local_authentication_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelFlutterLocalAuthentication platform =
      MethodChannelFlutterLocalAuthentication();
  const MethodChannel channel = MethodChannel('flutter_local_authentication');

  double testTouchIDAuthenticationAllowableReuseDuration = 0.0;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case "canAuthenticate":
            return true;
          case "authenticate":
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
      },
    );
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

  test('set_get_TouchIDAuthenticationAllowableReuseDuration', () async {
    expect(await platform.setTouchIDAuthenticationAllowableReuseDuration(30.0),
        30.0);
    expect(
        await platform.getTouchIDAuthenticationAllowableReuseDuration(), 30.0);
  });
}
