import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// AutoRouter.declarative carries the key it is given.
// Found by DCM's avoid-unused-parameters while moving the package to
// very_good_analysis; no upstream issue.
// Headless test: auto_route/test/nested_router/declarative_router_key_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('declarative router key', () {
    // Steps: HostRoute builds AutoRouter.declarative with a GlobalKey.
    // Should: the key finds the declarative router.
    testWidgets('AutoRouter.declarative carries the key it is given', (
      tester,
    ) async {
      final hostKey = GlobalKey();
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'HostRoute',
              builder: (_) => AutoRouter.declarative(
                key: hostKey,
                routes: (_) => [const NamedRoute('HomeRoute')],
              ),
            ),
            children: [
              AutoRoute(
                path: '',
                page: PageInfo(
                  'HomeRoute',
                  builder: (_) =>
                      const Scaffold(body: SafeArea(child: Text('HomeRoute'))),
                ),
              ),
            ],
          ),
        ],
      );
      await pumpRouterApp(tester, router);
      expect(find.text('HomeRoute'), findsOneWidget);
      expect(find.byKey(hostKey), findsOneWidget);
    });
  });
}
