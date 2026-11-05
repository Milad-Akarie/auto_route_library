import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
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
            AutoRoute(path: 'wallet', page: _page('WalletRoute'), guards: const [_SlowGuard()]),
          ],
        ),
        AutoRoute(path: '/sign-in', page: _page('SignInRoute')),
      ],
    );
  });

  // Pumps in short steps, so the shell's page leaves the tree, which disposes
  // its nested router, before the slow guard resolves.
  Future<void> pumpPastTheGuard(WidgetTester tester) async {
    for (var i = 0; i < 300; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  // https://github.com/Milad-Akarie/auto_route_library/issues/2248
  // The app returns from a sign-in in an in-app browser, which triggers a
  // reevaluation of the guards, and navigates to another page. The
  // reevaluation was still awaiting a guard of the nested router when that
  // navigation disposed it. It should stop, not fail with "A
  // NestedStackRouter was used after being disposed".
  testWidgets('a reevaluation stops when its nested router is disposed meanwhile', (tester) async {
    final reevaluate = ValueNotifier(0);
    addTearDown(reevaluate.dispose);
    await pumpRouterApp(tester, router, reevaluationNotifier: reevaluate);
    unawaited(router.push(const NamedRoute('WalletRoute')));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(router.currentPath, '/wallet');

    reevaluate.value++;
    // The reevaluation reaches the wallet's guard.
    await tester.pump(const Duration(milliseconds: 50));
    unawaited(router.replaceAll([const NamedRoute('SignInRoute')]));
    await pumpPastTheGuard(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('SignInRoute'), findsOneWidget);
    expect(router.currentPath, '/sign-in');
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2248
  // The same with a push: the wallet page is pushed in the shell's nested
  // router, and the shell is replaced while the wallet's guard runs.
  testWidgets('a push stops when its nested router is disposed while its guard runs', (tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const NamedRoute('WalletRoute')));
    await tester.pump(const Duration(milliseconds: 50));
    unawaited(router.replaceAll([const NamedRoute('SignInRoute')]));
    await pumpPastTheGuard(tester);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('SignInRoute'), findsOneWidget);
    expect(router.currentPath, '/sign-in');
  });
}

PageInfo _page(String name) => .new(name, builder: (_) => Text(name));

class _SlowGuard extends AutoRouteGuard {
  const new();

  @override
  Future<void> onNavigation(NavigationResolver resolver, StackRouter router) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    resolver.next();
  }
}
