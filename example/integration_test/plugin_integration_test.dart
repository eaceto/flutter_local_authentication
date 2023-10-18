import 'package:flutter_local_authentication/flutter_local_authentication.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('canAuthenticate test', (WidgetTester tester) async {
    final FlutterLocalAuthentication plugin = FlutterLocalAuthentication();
    final bool canAuthenticate = await plugin.canAuthenticate();
    expect(canAuthenticate, true);
  });
}
