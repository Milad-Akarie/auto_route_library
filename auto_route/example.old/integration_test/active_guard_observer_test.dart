import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/disposal_tracker.dart';

// Disposing a nested router disposes its ActiveGuardObserver, and a guard
// that finishes after that throws nothing.
// Headless test: auto_route/test/leaks/active_guard_observer_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: push HostRoute, whose page holds an AutoRouter, then go back,
  // three times.
  // Should: each visit's ActiveGuardObserver is disposed when the host leaves.
  testWidgets('leaving a nested router disposes its ActiveGuardObserver', (
    tester,
  ) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    final observers = DisposalTracker<ActiveGuardObserver>();

    for (var visit = 0; visit < 3; visit++) {
      unawaited(router.pushPath('/host'));
      await pumpUntilFound(tester, find.text('FirstChildRoute'));
      expect(find.text('FirstChildRoute'), findsOneWidget);

      await systemBack(tester);
      expect(find.text('HomeRoute'), findsOneWidget);
    }
    expect(observers.created, 3);
    expect(observers.undisposed, 0);
  });

  // Steps: in HostRoute's nested router, push SecondChildRoute, whose guard
  // waits; go back meanwhile, then let the guard through.
  // Should: the guard changes nothing and throws nothing.
  testWidgets(
    'a guard that finishes after its nested router is disposed throws nothing',
    (tester) async {
      final guard = _HeldGuard();
      final router = _buildRouter(childGuards: [guard]);
      await pumpRouterApp(tester, router);
      final observers = DisposalTracker<ActiveGuardObserver>();
      unawaited(router.pushPath('/host'));
      await pumpUntilFound(tester, find.text('FirstChildRoute'));
      final nested = router.innerRouterOf<StackRouter>('HostRoute')!;
      unawaited(nested.push(const NamedRoute('SecondChildRoute')));
      await tester.pump();
      expect(nested.activeGuardObserver.guardInProgress, isTrue);

      await systemBack(tester);
      expect(find.text('HomeRoute'), findsOneWidget);
      expect(observers.undisposed, 0);
      guard.release.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('HomeRoute'), findsOneWidget);
    },
  );
}

/// Lets the navigation through once [release] completes.
class _HeldGuard extends AutoRouteGuard {
  final release = Completer<void>();

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    await release.future;
    resolver.next();
  }
}

RootStackRouter _buildRouter({List<AutoRouteGuard> childGuards = const []}) =>
    .build(
      routes: [
        AutoRoute(path: '/', page: _page('HomeRoute')),
        AutoRoute(
          path: '/host',
          page: PageInfo('HostRoute', builder: (_) => const AutoRouter()),
          children: [
            AutoRoute(path: '', page: _page('FirstChildRoute')),
            AutoRoute(
              path: 'second',
              page: _page('SecondChildRoute'),
              guards: childGuards,
            ),
          ],
        ),
      ],
    );

PageInfo _page(String name) => .new(name, builder: (_) => _TextPage(name));

/// Shows [text] on a plain page.
class _TextPage extends StatelessWidget {
  const _TextPage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: SafeArea(child: Text(text)));
}
