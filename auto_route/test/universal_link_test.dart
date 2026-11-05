import 'package:auto_route/auto_route.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'main_router.dart';
import 'no_op.dart';
import 'router_test_utils.dart';

// Sends a link the way the engine does when the platform opens one, and
// returns the app's answer: whether it handled the link.
Future<bool?> sendPlatformLink(WidgetTester tester, String location) async {
  const codec = JSONMethodCodec();
  final reply = await tester.binding.defaultBinaryMessenger
      .handlePlatformMessage(
        SystemChannels.navigation.name,
        codec.encodeMethodCall(
          MethodCall('pushRouteInformation', {
            'location': location,
            'state': null,
          }),
        ),
        ignoreArgument,
      );
  await tester.pumpAndSettle();
  return reply == null ? null : codec.decodeEnvelope(reply) as bool?;
}

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/2055
  // Since Flutter 3.24.2, the iOS engine sends a universal link to the app and
  // opens it in the browser instead when the app answers that it didn't
  // handle it. Send '/second-route' as the engine does: the app should answer
  // true and show the page.
  testWidgets(
    'A link from the platform is answered as handled and opens its page',
    (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(page: FirstRoute.page, path: '/', initial: true),
          AutoRoute(page: SecondRoute.page, path: '/second-route'),
        ],
      );
      await pumpRouterConfigApp(tester, router.config());
      expect(
        await sendPlatformLink(tester, 'https://example.com/second-route'),
        isTrue,
      );
      expectCurrentPage(router, SecondRoute.name);
    },
  );
}
