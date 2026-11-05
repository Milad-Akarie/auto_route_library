import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/disposal_tracker.dart';

// Disposing a root router, or its delegate, disposes the delegate, url
// provider and navigation history the router created.
// Headless test: auto_route/test/leaks/root_router_dispose_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  for (final disposeDelegate in [false, true]) {
    final disposed = disposeDelegate ? 'its delegate' : 'the router';
    // Steps: show a root router through router.config(), close the app, then
    // dispose the router, or its delegate.
    // Should: the router, its delegate, url provider and navigation history
    // are all disposed.
    testWidgets('disposing $disposed disposes all the root router created', (
      tester,
    ) async {
      final notifiers = DisposalTracker<ChangeNotifier>();
      final router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: PageInfo(
              'HomeRoute',
              builder: (_) => const _TextPage('HomeRoute'),
            ),
          ),
        ],
      );
      await pumpRouterAppWithConfig(tester, router);
      expect(find.text('HomeRoute'), findsOneWidget);
      final created = <ChangeNotifier>[
        router,
        router.delegate(),
        router.routeInfoProvider(),
        router.navigationHistory,
      ];
      expect(created.where(notifiers.isUndisposed), hasLength(4));
      await tester.pumpWidget(const SizedBox());

      if (disposeDelegate) {
        router.delegate().dispose();
      } else {
        router.dispose();
      }
      expect(created.where(notifiers.isUndisposed), isEmpty);
    });
  }
}

/// Shows [text] on a plain page.
class _TextPage extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: SafeArea(child: Text(text)));
}
