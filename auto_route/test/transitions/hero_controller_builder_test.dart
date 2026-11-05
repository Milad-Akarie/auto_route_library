import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../hero_box_page.dart';
import '../leaks/disposal_tracker.dart';
import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/372
  // https://github.com/flutter/flutter/issues/90103
  // Flutter gives a HeroController only to the app's root navigator, so a
  // Hero stays put between two pages of a nested router. Passing
  // heroControllerBuilder to the nested router turns flights on.
  // Steps: a nested router's first page has a Hero (bottom left); push a
  // second page with the same Hero (top right) inside that router.
  group('AutoRouter.heroControllerBuilder', () {
    testWidgets('flies a Hero between two pages of the nested router', (
      tester,
    ) async {
      final heroControllerBuilder = ValueNotifier<_HeroControllerBuilder?>(
        MaterialApp.createMaterialHeroController,
      );
      addTearDown(heroControllerBuilder.dispose);
      await pumpRouterApp(tester, _stackRouter(heroControllerBuilder));
      await _pushTo(tester);
      _expectHeroInFlight(tester);
      await tester.pumpAndSettle();
      expect(find.text('to'), findsOneWidget);
    });

    testWidgets('left out, a Hero stays put', (tester) async {
      final heroControllerBuilder = ValueNotifier<_HeroControllerBuilder?>(
        null,
      );
      addTearDown(heroControllerBuilder.dispose);
      await pumpRouterApp(tester, _stackRouter(heroControllerBuilder));
      await _pushTo(tester);
      _expectHeroStaysPut();
      await tester.pumpAndSettle();
      expect(find.text('to'), findsOneWidget);
    });

    testWidgets('a rebuild that sets it turns flights on', (tester) async {
      final heroControllerBuilder = ValueNotifier<_HeroControllerBuilder?>(
        null,
      );
      addTearDown(heroControllerBuilder.dispose);
      await pumpRouterApp(tester, _stackRouter(heroControllerBuilder));
      final heroControllers = DisposalTracker<HeroController>();

      heroControllerBuilder.value = MaterialApp.createMaterialHeroController;
      await tester.pump();
      expect(heroControllers.created, 1);
      await _pushTo(tester);
      _expectHeroInFlight(tester);
      await tester.pumpAndSettle();
      expect(find.text('to'), findsOneWidget);
    });

    testWidgets('a rebuild that clears it disposes the controller', (
      tester,
    ) async {
      final heroControllers = DisposalTracker<HeroController>();
      final heroControllerBuilder = ValueNotifier<_HeroControllerBuilder?>(
        MaterialApp.createMaterialHeroController,
      );
      addTearDown(heroControllerBuilder.dispose);
      await pumpRouterApp(tester, _stackRouter(heroControllerBuilder));
      // The app's own controller and the nested router's.
      final createdWithBuilder = heroControllers.created;

      heroControllerBuilder.value = null;
      await tester.pump();
      expect((createdWithBuilder, heroControllers.undisposed), (2, 1));
      await _pushTo(tester);
      _expectHeroStaysPut();
      await tester.pumpAndSettle();
      expect(find.text('to'), findsOneWidget);
    });

    testWidgets('a rebuild with another builder keeps the controller', (
      tester,
    ) async {
      final heroControllerBuilder = ValueNotifier<_HeroControllerBuilder?>(
        MaterialApp.createMaterialHeroController,
      );
      addTearDown(heroControllerBuilder.dispose);
      await pumpRouterApp(tester, _stackRouter(heroControllerBuilder));
      final heroControllers = DisposalTracker<HeroController>();

      heroControllerBuilder.value = HeroController.new;
      await tester.pump();
      expect((heroControllers.created, heroControllers.undisposed), (0, 0));
    });

    testWidgets('leaving the nested router disposes the controller', (
      tester,
    ) async {
      final heroControllerBuilder = ValueNotifier<_HeroControllerBuilder?>(
        MaterialApp.createMaterialHeroController,
      );
      addTearDown(heroControllerBuilder.dispose);
      final router = _stackRouter(heroControllerBuilder, hasHomeBelow: true);
      await pumpRouterApp(tester, router);
      // Started after the app, whose own HeroController lives until it closes.
      final heroControllers = DisposalTracker<HeroController>();
      unawaited(router.pushPath('/host'));
      await tester.pumpAndSettle();
      expect(find.text('from'), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect((heroControllers.created, heroControllers.undisposed), (1, 0));
    });
  });

  // The same steps in an AutoRouter.declarative, whose pages come from a list
  // the host page holds.
  group('AutoRouter.declarative heroControllerBuilder', () {
    testWidgets('flies a Hero between two pages of the nested router', (
      tester,
    ) async {
      final pages = ValueNotifier<List<PageRouteInfo>>(const [_kFromRoute]);
      addTearDown(pages.dispose);
      final heroControllerBuilder = ValueNotifier<_HeroControllerBuilder?>(
        MaterialApp.createMaterialHeroController,
      );
      addTearDown(heroControllerBuilder.dispose);
      await pumpRouterApp(
        tester,
        _declarativeRouter(pages, heroControllerBuilder),
      );
      expect(find.text('from'), findsOneWidget);

      pages.value = const [_kFromRoute, _kToRoute];
      await _pumpUntilFlight(tester);
      _expectHeroInFlight(tester);
      await tester.pumpAndSettle();
      expect(find.text('to'), findsOneWidget);
    });
  });
}

typedef _HeroControllerBuilder = HeroController Function();

const NamedRoute<void> _kFromRoute = NamedRoute('FromRoute');
const NamedRoute<void> _kToRoute = NamedRoute('ToRoute');

/// The two Hero pages of the nested router.
List<NamedRouteDef> _heroPages() => [
  NamedRouteDef(
    name: _kFromRoute.routeName,
    path: '',
    builder: (_, _) => const HeroBoxPage('from', .bottomLeft),
  ),
  NamedRouteDef(
    name: _kToRoute.routeName,
    path: 'to',
    builder: (_, _) => const HeroBoxPage('to', .topRight),
  ),
];

/// A router whose host page holds a nested [AutoRouter] built with the
/// current [heroControllerBuilder]. The host is the first page, or, when
/// [hasHomeBelow] is true, a page at `/host` above a plain home page.
RootStackRouter _stackRouter(
  ValueListenable<_HeroControllerBuilder?> heroControllerBuilder, {
  bool hasHomeBelow = false,
}) => .build(
  routes: [
    if (hasHomeBelow)
      NamedRouteDef(
        name: 'HomeRoute',
        path: '/',
        builder: (_, _) => const Text('home'),
      ),
    NamedRouteDef(
      name: 'HostRoute',
      path: hasHomeBelow ? '/host' : '/',
      builder: (_, _) => ValueListenableBuilder(
        valueListenable: heroControllerBuilder,
        builder: (_, builder, _) => AutoRouter(heroControllerBuilder: builder),
      ),
      children: _heroPages(),
    ),
  ],
);

/// A router whose first page holds an [AutoRouter.declarative] showing
/// [pages], built with the current [heroControllerBuilder].
RootStackRouter _declarativeRouter(
  ValueListenable<List<PageRouteInfo>> pages,
  ValueListenable<_HeroControllerBuilder?> heroControllerBuilder,
) => .build(
  routes: [
    NamedRouteDef(
      name: 'HostRoute',
      path: '/',
      builder: (_, _) => ListenableBuilder(
        listenable: Listenable.merge([pages, heroControllerBuilder]),
        builder: (_, _) => AutoRouter.declarative(
          routes: (_) => pages.value,
          heroControllerBuilder: heroControllerBuilder.value,
        ),
      ),
      children: _heroPages(),
    ),
  ],
);

Future<void> _pushTo(WidgetTester tester) async {
  expect(find.text('from'), findsOneWidget);
  unawaited(tester.element(find.text('from')).router.push(_kToRoute));
  await _pumpUntilFlight(tester);
}

Future<void> _pumpUntilFlight(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void _expectHeroStaysPut() {
  expect(
    find.text('from'),
    findsOneWidget,
    reason: 'without a HeroController the Hero stays on its page',
  );
}

// While the Hero flies, its child is shown by the overlay and not by the
// first page; the Hero's end page is at its place on the second page only at
// the end.
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
