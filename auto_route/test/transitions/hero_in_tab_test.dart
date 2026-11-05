import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../hero_box_page.dart';
import '../hero_scoped_router.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/372
  // Reported: Heroes don't fly inside a tabs router. A tab holds its own
  // stack router; its first page has a Hero (bottom left).
  // Steps: push a second page with the same Hero (top right) inside the tab.
  // Flutter gives a HeroController only to the app's root Navigator and hides
  // it from nested ones (Navigator builds its Overlay in
  // HeroControllerScope.none), so a nested Navigator flies Heroes only under a
  // HeroControllerScope of its own. That is the answer given on #1873, and
  // the same holds for the stack router of a tab.
  group('Between two pages of one tab', () {
    testWidgets('a Hero flies when the tab has a HeroControllerScope', (
      tester,
    ) async {
      await pumpRouterConfigApp(tester, _router(hasScope: true).config());
      await _pushTo(tester);
      _expectHeroInFlight(tester);
      await tester.pumpAndSettle();
      expect(find.text('to'), findsOneWidget);
    });

    testWidgets('a Hero stays put when the tab has none', (tester) async {
      await pumpRouterConfigApp(tester, _router(hasScope: false).config());
      await _pushTo(tester);
      expect(
        find.text('from'),
        findsOneWidget,
        reason: 'without a HeroController the Hero stays on its page',
      );
      await tester.pumpAndSettle();
      expect(find.text('to'), findsOneWidget);
    });
  });
}

Future<void> _pushTo(WidgetTester tester) async {
  expect(find.text('from'), findsOneWidget);
  unawaited(tester.element(find.text('from')).router.push(_kToRoute));
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

const NamedRoute<void> _kToRoute = NamedRoute('ToRoute');

const _kTabRouteName = 'TabRoute';

RootStackRouter _router({required bool hasScope}) => .build(
  routes: [
    NamedRouteDef(
      name: 'TabsHostRoute',
      path: '/',
      builder: (_, _) => const AutoTabsRouter(
        routes: [NamedRoute(_kTabRouteName), NamedRoute('OtherTabRoute')],
      ),
      children: [
        NamedRouteDef(
          name: _kTabRouteName,
          path: 'tab',
          builder: (_, _) =>
              hasScope ? const HeroScopedRouter() : const AutoRouter(),
          children: [
            NamedRouteDef(
              name: 'FromRoute',
              path: '',
              builder: (_, _) => const HeroBoxPage('from', .bottomLeft),
            ),
            NamedRouteDef(
              name: 'ToRoute',
              path: 'to',
              builder: (_, _) => const HeroBoxPage('to', .topRight),
            ),
          ],
        ),
        NamedRouteDef(
          name: 'OtherTabRoute',
          path: 'other',
          builder: (_, _) => const Text('other'),
        ),
      ],
    ),
  ],
);

void _expectHeroInFlight(WidgetTester tester) {
  expect(
    find.text('from'),
    findsNothing,
    reason: 'the source Hero should have left its page',
  );
  final position = tester.getTopLeft(find.text('to').last);
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  expect(
    position.dy,
    greaterThan(size.height / 4),
    reason: 'the Hero should still be on its way up',
  );
  expect(
    position.dx,
    lessThan(size.width / 2),
    reason: 'the Hero should still be on its way right',
  );
}
