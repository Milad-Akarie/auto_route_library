import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A navigation stops when its nested router is disposed while a guard runs.
// https://github.com/Milad-Akarie/auto_route_library/issues/2248
// Headless test: auto_route/test/reevaluatable_router/disposed_nested_router_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('disposed nested router', () {
    late RootStackRouter router;
    setUp(() {
      router = RootStackRouter.build(
        routes: [
          AutoRoute(
            path: '/',
            page: const EmptyShellRoute('ShellRoute'),
            initial: true,
            children: [
              AutoRoute(path: '', page: _page('FeedRoute')),
              AutoRoute(
                path: 'wallet',
                page: _page('WalletRoute'),
                guards: const [_SlowGuard()],
              ),
            ],
          ),
          AutoRoute(path: '/sign-in', page: _page('SignInRoute')),
        ],
      );
    });

    // Waits in real time, so the slow guard resolves.
    Future<void> waitForTheGuard(WidgetTester tester) async {
      await Future<void>.delayed(
        _SlowGuard.delay + const Duration(milliseconds: 500),
      );
      await tester.pumpAndSettle();
    }

    // Steps: open the wallet page, behind a slow guard, in the shell's nested
    // router. Trigger a reevaluation of the guards, as returning from a
    // sign-in does, then replace every page with the sign-in page while the
    // wallet's guard is still running.
    // Should: the sign-in page shows, with no "A NestedStackRouter was used
    // after being disposed" error.
    testWidgets(
      'a reevaluation stops when its nested router is disposed meanwhile',
      (tester) async {
        final reevaluate = ValueNotifier(0);
        await pumpRouterApp(tester, router, reevaluationNotifier: reevaluate);
        unawaited(router.push(const NamedRoute('WalletRoute')));
        await waitForTheGuard(tester);
        expect(find.text('WalletRoute'), findsOneWidget);

        reevaluate.value++;
        await tester.pump(const Duration(milliseconds: 100));
        unawaited(router.replaceAll([const NamedRoute('SignInRoute')]));
        await tester.pumpAndSettle();
        await waitForTheGuard(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('SignInRoute'), findsOneWidget);
        expect(router.currentPath, '/sign-in');
        await expectBrowserUrl('/sign-in');
      },
    );

    // Steps: push the wallet page and replace every page with the sign-in
    // page while the wallet's guard is still running.
    // Should: the sign-in page shows, with no error.
    testWidgets(
      'a push stops when its nested router is disposed while its guard runs',
      (tester) async {
        await pumpRouterApp(tester, router);
        unawaited(router.push(const NamedRoute('WalletRoute')));
        await tester.pump(const Duration(milliseconds: 100));
        unawaited(router.replaceAll([const NamedRoute('SignInRoute')]));
        await tester.pumpAndSettle();
        await waitForTheGuard(tester);
        expect(tester.takeException(), isNull);
        expect(find.text('SignInRoute'), findsOneWidget);
        expect(router.currentPath, '/sign-in');
      },
    );
  });
}

PageInfo _page(String name) => .new(
  name,
  builder: (_) => Scaffold(body: Center(child: Text(name))),
);

class _SlowGuard extends AutoRouteGuard {
  const new();

  static const delay = Duration(seconds: 2);

  @override
  Future<void> onNavigation(
    NavigationResolver resolver,
    StackRouter router,
  ) async {
    await Future<void>.delayed(delay);
    resolver.next();
  }
}
