import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support/app.dart';
import 'support/pages.dart';

// A link from the platform is answered as handled and opens its page.
// https://github.com/Milad-Akarie/auto_route_library/issues/2055
// Headless test: auto_route/test/universal_link_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('universal link', () {
    // Steps: send 'https://example.com/second-route' to the app on the
    // navigation channel, as the iOS engine does for a universal link.
    // Should: the app answers true, so the engine doesn't open the link in the
    // browser, and shows the second page.
    testWidgets(
      'A link from the platform is answered as handled and opens its page',
      (tester) async {
        final router = buildSimpleRouter();
        await pumpRouterAppWithConfig(tester, router);
        const codec = JSONMethodCodec();
        final reply = await tester.binding.defaultBinaryMessenger
            .handlePlatformMessage(
              SystemChannels.navigation.name,
              codec.encodeMethodCall(
                const MethodCall('pushRouteInformation', {
                  'location': 'https://example.com/second-route',
                  'state': null,
                }),
              ),
              null,
            );
        await tester.pumpAndSettle();
        expect(reply == null ? null : codec.decodeEnvelope(reply), isTrue);
        expectCurrentPage(router, SecondRoute.name);
      },
    );
  });
}
