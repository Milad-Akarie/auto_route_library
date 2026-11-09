import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A platform link right after a cold start leaves no home page below it when
// includePrefixMatches is false.
// https://github.com/Milad-Akarie/auto_route_library/issues/2167
// Headless test: auto_route/test/platform_link_over_initial_prefix_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('platform link over the launch page', () {
    // Steps: routes '/login' and an initial '/', with
    // `config(includePrefixMatches: false)`. The app opens at '/', then the
    // platform sends '/login', the order iOS uses at a cold start.
    // Should: the stack holds only the login page.
    testWidgets('the link takes the place of the first page', (tester) async {
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(path: '/login', page: _page('LoginRoute')),
          AutoRoute(path: '/', initial: true, page: _page('MainRoute')),
        ],
      );
      await pumpRouterConfigApp(
        tester,
        router.config(includePrefixMatches: false),
      );
      expect(find.text('MainRoute'), findsOneWidget);

      const codec = JSONMethodCodec();
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.navigation.name,
        codec.encodeMethodCall(
          const MethodCall('pushRouteInformation', {
            'location': '/login',
            'state': null,
          }),
        ),
        null,
      );
      await tester.pumpAndSettle();
      expect(find.text('LoginRoute'), findsOneWidget);
      expect(router.stack.map((page) => page.name), ['LoginRoute']);
      // On the web the browser opens the app at its url, so no route comes
      // after the first one this way.
    }, skip: kIsWeb);
  });
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
