import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// A back or close button on the host page pops the nested page first.
// https://github.com/Milad-Akarie/auto_route_library/issues/2309
// Headless test: auto_route/test/nested_router/router_widget_test.dart
//
// Steps: push _ButtonsHostRoute (a BackButton and a CloseButton above a
// nested router that shows SecondNested1Route), push SecondNested3Route into
// that nested router, then press the host page's button twice.
// Before the fix: the press did nothing; SecondNested3Route stayed on screen.
// Should: the first press pops SecondNested3Route and keeps the host page;
// the second pops the host page. The reporter expected the first press to
// close the host page; the fork pops the nested page first, the order system
// back uses (see nested_back_test.dart).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(path: '/', page: FirstRoute.page),
        AutoRoute(
          path: '/host',
          page: _ButtonsHostRoute.page,
          children: [
            AutoRoute(path: '', page: SecondNested1Route.page),
            AutoRoute(path: 'nested3', page: SecondNested3Route.page),
          ],
        ),
      ],
    );
  });

  Future<void> pushSubRoute(WidgetTester tester) async {
    unawaited(router.push(const _ButtonsHostRoute()));
    await tester.pumpAndSettle();
    unawaited(router.innerRouterOf<StackRouter>(_ButtonsHostRoute.name)!.push(const SecondNested3Route()));
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested3Route.name);
  }

  for (final button in [BackButton, CloseButton]) {
    testWidgets('$button on the host page pops the nested page, then the host page', (tester) async {
      await pumpRouterApp(tester, router);
      await pushSubRoute(tester);

      await tester.tap(find.byType(button));
      await tester.pumpAndSettle();

      expect(router.current.name, _ButtonsHostRoute.name);
      expectTopPage(router, SecondNested1Route.name);

      await tester.tap(find.byType(button));
      await tester.pumpAndSettle();

      expectTopPage(router, FirstRoute.name);
    });
  }
}

/// Hosts a nested stack router under a row with a BackButton and a
/// CloseButton, as in the #2309 report.
class _ButtonsHostRoute extends PageRouteInfo<void> {
  const _ButtonsHostRoute() : super(name);

  static const String name = 'ButtonsHostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Row(children: [BackButton(), CloseButton()]),
            Expanded(child: AutoRouter()),
          ],
        ),
      ),
    ),
  );
}
