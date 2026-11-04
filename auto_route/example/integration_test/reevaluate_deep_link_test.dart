import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A url the platform sends, such as one typed in the browser's address bar,
// opens its page while reevaluateListenable is set.
// https://github.com/Milad-Akarie/auto_route_library/issues/2173
// Headless tests: auto_route/test/reevaluatable_router/reevaluate_deep_link_test.dart
// and auto_route/test/web/typed_url_reevaluate_web_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: open the app with reevaluateListenable set, have the platform push
  // '/profile', a guarded route, then fire the listenable.
  // Should: ProfileRoute is on top and the url is '/profile', not '/'.
  testWidgets('A url the platform pushes opens its page with reevaluateListenable set (#2173)', (tester) async {
    final auth = ValueNotifier(0);
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
        ),
        NamedRouteDef(
          name: 'ProfileRoute',
          path: '/profile',
          guards: [AutoRouteGuard.simple((resolver, _) => resolver.next())],
          builder: (_, _) => const Scaffold(body: Text('ProfileRoute')),
        ),
      ],
    );
    await pumpRouterConfigApp(
      tester,
      router.config(
        reevaluateListenable: auth,
        // on web the browser's url would otherwise carry over from the previous test
        deepLinkBuilder: (link) => link.initial ? const DeepLink.path('/') : link,
      ),
    );

    await tester.binding.handlePushRoute('/profile');
    await tester.pumpAndSettle();
    auth.value++;
    await tester.pumpAndSettle();

    expect(router.topRoute.name, 'ProfileRoute');
    expect(find.text('ProfileRoute'), findsOneWidget);
    await expectBrowserUrl('/profile');
  });
}
