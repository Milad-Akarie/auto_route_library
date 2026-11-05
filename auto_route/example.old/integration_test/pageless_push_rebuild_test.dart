import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// Navigator.push of a page outside the router doesn't rebuild the page
// underneath.
// Guards https://github.com/Milad-Akarie/auto_route_library/issues/2211
// Headless test: auto_route/test/simple_router/pageless_push_rebuild_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('pageless push rebuild', () {
    // Steps: on HomeRoute, tap a button that calls
    // Navigator.push(context, MaterialPageRoute(...)) for a page the router
    // doesn't know, then go back.
    // Should: HomeRoute isn't built again.
    testWidgets(
      'Navigator.push of a page outside the router does not rebuild the page '
      'underneath',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              path: '/',
              page: PageInfo('HomeRoute', builder: (_) => const _HomePage()),
            ),
          ],
        );
        await pumpRouterApp(tester, router);
        _HomePage.builds = 0;

        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        expect(find.text('Not registered'), findsOneWidget);
        expect(_HomePage.builds, 0);

        await systemBack(tester);
        expect(find.text('Open'), findsOneWidget);
        expect(_HomePage.builds, 0);
      },
    );
  });
}

class _HomePage extends StatelessWidget {
  const new();

  /// How many times a [_HomePage] has been built.
  static int builds = 0;

  @override
  Widget build(BuildContext context) {
    builds++;
    return Scaffold(
      body: SafeArea(
        child: TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  const Scaffold(body: SafeArea(child: Text('Not registered'))),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    );
  }
}
