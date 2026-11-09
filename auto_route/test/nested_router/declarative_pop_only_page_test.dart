import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/2087
// Setup: Home at '/' pushes Host, which builds AutoRouter.declarative. The list
// of its routes decides its pages.
// Steps: call pop on the declarative router while its navigator shows one page.
// Should: the page that holds the router closes, as nothing can take the
// router's only page away from its list. Before, the navigator lost its page
// and left the screen blank.
void main() {
  late ValueNotifier<bool> showsSecond;
  late RootStackRouter router;

  StackRouter inner() => router.innerRouterOf('HostRoute')!;

  Future<void> openHost(WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    unawaited(router.push(const PageRouteInfo('HostRoute')));
    await tester.pumpAndSettle();
  }

  setUp(() {
    showsSecond = ValueNotifier(false);
    addTearDown(showsSecond.dispose);
    router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          page: PageInfo('HomeRoute', builder: (_) => const Text('Home')),
        ),
        AutoRoute(
          path: '/host',
          page: PageInfo(
            'HostRoute',
            builder: (_) => ValueListenableBuilder(
              valueListenable: showsSecond,
              builder: (_, isSecondShown, _) => AutoRouter.declarative(
                routes: (_) => [
                  const PageRouteInfo('ARoute'),
                  if (isSecondShown) const PageRouteInfo('BRoute'),
                ],
                onPopRoute: (_, _) => showsSecond.value = false,
              ),
            ),
          ),
          children: [
            AutoRoute(
              path: 'a',
              page: PageInfo('ARoute', builder: (_) => const Text('A')),
            ),
            AutoRoute(
              path: 'b',
              page: PageInfo('BRoute', builder: (_) => const Text('B')),
            ),
          ],
        ),
      ],
    );
  });

  testWidgets('pop on the only page of a declarative router closes its host', (
    tester,
  ) async {
    await openHost(tester);
    inner().pop();
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(router.stack.map((page) => page.name), ['HomeRoute']);
  });

  testWidgets('pop closes a dialog over the only page, and not the host', (
    tester,
  ) async {
    await openHost(tester);
    showDialog<void>(
      context: inner().navigatorKey.currentContext!,
      useRootNavigator: false,
      builder: (_) => const Text('Dialog'),
    );
    await tester.pumpAndSettle();

    inner().pop();
    await tester.pumpAndSettle();
    expect(find.text('Dialog'), findsNothing);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('pop over a second page closes that page, and not the host', (
    tester,
  ) async {
    await openHost(tester);
    showsSecond.value = true;
    await tester.pumpAndSettle();
    expect(find.text('B'), findsOneWidget);

    inner().pop();
    await tester.pumpAndSettle();
    expect(find.text('A'), findsOneWidget);
    expect(showsSecond.value, isFalse);
  });
}
