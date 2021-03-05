import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_local_authentication/flutter_local_authentication.dart';

void main() {
  const MethodChannel channel = MethodChannel('flutter_local_authentication');

  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return true;
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('supportsAuthentication', () async {
    expect(await FlutterLocalAuthentication.supportsAuthentication, true);
  });
}
