import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/2173
// Reported for 10.0.0 and later on web, without code: with reevaluateListenable
// set, a url typed in the browser's address bar always opened '/'. A typed url
// reaches the app as its first route when the page reloads, or as a new route
// from the platform when only the part after '#' changes. Either way the app
// must open that url, also when the listenable fires and the route is guarded.
// The browser's own address bar is covered by test/web/typed_url_reevaluate_web_test.dart.
void main() {
  RootStackRouter buildRouter() => .build(
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

  testWidgets(
    'The first url opens its page with reevaluateListenable set (#2173)',
    (tester) async {
      tester.binding.platformDispatcher.defaultRouteNameTestValue = '/profile';
      addTearDown(
        tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
      );
      final auth = ValueNotifier(0);
      addTearDown(auth.dispose);
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router.config(reevaluateListenable: auth),
        ),
      );
      auth.value++;
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(router.topRoute.name, 'ProfileRoute');
      expect(router.urlState.url, '/profile');
      expect(find.text('ProfileRoute'), findsOneWidget);
    },
  );

  testWidgets(
    'A url the platform pushes opens its page with reevaluateListenable set (#2173)',
    (tester) async {
      final auth = ValueNotifier(0);
      addTearDown(auth.dispose);
      final router = buildRouter();
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(
          routerConfig: router.config(reevaluateListenable: auth),
        ),
      );
      await tester.pumpAndSettle();

      await tester.binding.handlePushRoute('/profile');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();
      auth.value++;
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(router.topRoute.name, 'ProfileRoute');
      expect(router.urlState.url, '/profile');
      expect(find.text('ProfileRoute'), findsOneWidget);
    },
  );
}
