import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';
import 'disposal_tracker.dart';

/// Tracks the objects a root router creates for its app.
class _RootObjects {
  final routers = DisposalTracker<RootStackRouter>();
  final delegates = DisposalTracker<AutoRouterDelegate>();
  final providers = DisposalTracker<AutoRouteInformationProvider>();
  final histories = DisposalTracker<NavigationHistory>();

  void expectAllDisposed() {
    expect(routers.created, 1);
    expect(delegates.created, 1);
    expect(providers.created, 1);
    expect(histories.created, 1);
    expect(routers.undisposed, 0);
    expect(delegates.undisposed, 0);
    expect(providers.undisposed, 0);
    expect(histories.undisposed, 0);
  }
}

RootStackRouter _buildRouter() => .build(
  routes: [
    AutoRoute(
      path: '/',
      page: PageInfo('HomeRoute', builder: (_) => const Text('HomeRoute')),
    ),
  ],
);

/// Shows a new router through its config, then closes the app.
Future<RootStackRouter> _openAndCloseApp(WidgetTester tester) async {
  final router = _buildRouter();
  await pumpRouterConfigApp(tester, router.config());
  expect(find.text('HomeRoute'), findsOneWidget);
  await tester.pumpWidget(const SizedBox());
  return router;
}

void main() {
  // Steps: show a root router through router.config(), close the app, then
  // dispose the router.
  // Happened: the delegate, url provider and navigation history the router
  // created stayed undisposed.
  // Should: disposing the router disposes all of them.
  testWidgets(
    'Disposing a root router disposes its delegate, url provider and history',
    (tester) async {
      final objects = _RootObjects();
      final router = await _openAndCloseApp(tester);

      router.dispose();
      objects.expectAllDisposed();
    },
  );

  // Steps: as above, but dispose the router's delegate instead.
  // Should: disposing the delegate disposes the router and all it created.
  testWidgets(
    'Disposing a root router delegate disposes the router and all it created',
    (tester) async {
      final objects = _RootObjects();
      final router = await _openAndCloseApp(tester);

      router.delegate().dispose();
      objects.expectAllDisposed();
    },
  );

  // Steps: dispose the router, then its delegate, then the router again.
  // Should: the later calls do nothing and throw nothing.
  testWidgets('Disposing a root router and its delegate twice throws nothing', (
    tester,
  ) async {
    final objects = _RootObjects();
    final router = await _openAndCloseApp(tester);

    router.dispose();
    router.delegate().dispose();
    router.dispose();
    objects.expectAllDisposed();
  });
}
