import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';
import 'main_router.dart';

// Guard for https://github.com/Milad-Akarie/auto_route_library/issues/2126
// Setup, as in the report: a home page and a second page wrapped in a
// PopScope whose onPopInvokedWithResult records each call; the second page
// has a button that calls Navigator.maybePop(context).
// Steps: push the second page, then go back through that button, or any
// other way back. Also with the second page pushed in a nested router, and
// with PopScope(canPop: false).
// Happened (reported on auto_route 9): onPopInvokedWithResult ran twice
// for one pop.
// Should: it runs once per back, with didPop true when the page is popped
// and false when PopScope blocks it.
// Already works on dev, on every way back. The report came from auto_route
// 9, whose Navigator took pops through the deprecated onPopPage
// callback; dev uses onDidRemovePage (since upstream 7dbb9b4). That change is the
// likely fix, not a confirmed one.
void main() {
  late RootStackRouter router;
  setUp(() {
    _heard.clear();
    _canPop = true;
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, path: '/'),
        AutoRoute(page: _CountedRoute.page, path: '/counted'),
        AutoRoute(
          page: _HostRoute.page,
          path: '/host',
          children: [
            AutoRoute(page: SecondNested1Route.page, path: ''),
            AutoRoute(page: _CountedRoute.page, path: 'counted'),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
  });

  Future<void> openCountedPage(WidgetTester tester, {required bool nested, ThemeData? theme}) async {
    await tester.pumpWidget(MaterialApp.router(theme: theme, routerConfig: router.config()));
    await tester.pumpAndSettle();
    if (nested) {
      unawaited(router.push(const _HostRoute()));
      await tester.pumpAndSettle();
      unawaited(router.innerRouterOf<StackRouter>(_HostRoute.name)!.push(const _CountedRoute()));
    } else {
      unawaited(router.push(const _CountedRoute()));
    }
    await tester.pumpAndSettle();
    expect(router.topRoute.name, _CountedRoute.name);
  }

  Future<void> tapMaybePop(WidgetTester tester) async {
    await tester.tap(find.text(_kMaybePopLabel));
    await tester.pumpAndSettle();
  }

  Future<void> routerMaybePop(WidgetTester tester) async {
    await tester.element(find.text(_CountedRoute.name)).router.maybePop();
    await tester.pumpAndSettle();
  }

  final backs = <String, (Future<void> Function(WidgetTester), ThemeData?)>{
    'Navigator.maybePop': (tapMaybePop, null),
    'router.maybePop': (routerMaybePop, null),
    'system back': (systemBack, null),
    'the predictive back gesture': (predictiveBack, androidTheme),
    'the app bar back button': (tapLeadingBackButton, null),
    'the iOS back swipe': (swipeBack, iosTheme),
  };

  // The reporter's own reproduction: routes with no paths, the home page
  // initial, and a 'Next page' button that pushes the second page.
  testWidgets("the report's 'Go back' button should call onPopInvokedWithResult once", (tester) async {
    final reportRouter = RootStackRouter.build(
      routes: [
        AutoRoute(page: _ReportHomeRoute.page, initial: true),
        AutoRoute(page: _CountedRoute.page),
      ],
    );
    addTearDown(reportRouter.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: reportRouter.config()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next page'));
    await tester.pumpAndSettle();
    expect(find.text(_CountedRoute.name), findsOneWidget);

    await tapMaybePop(tester);

    expect(find.text('Page One'), findsOneWidget);
    expect(_heard, [true]);
  });

  for (final nested in [false, true]) {
    final where = nested ? 'in a nested router' : 'in a flat route';
    for (final MapEntry(key: name, value: (back, theme)) in backs.entries) {
      testWidgets('$name $where should call onPopInvokedWithResult once', (tester) async {
        await openCountedPage(tester, nested: nested, theme: theme);

        await back(tester);

        expect(find.text(_CountedRoute.name), findsNothing);
        expect(_heard, [true]);
      });

      // The iOS swipe doesn't start while PopScope blocks the page.
      if (back == swipeBack) continue;

      testWidgets('$name $where with PopScope(canPop: false) should call it once per back', (tester) async {
        _canPop = false;
        await openCountedPage(tester, nested: nested, theme: theme);

        await back(tester);
        expect(_heard, [false]);
        await back(tester);
        expect(_heard, [false, false]);

        expect(router.topRoute.name, _CountedRoute.name);
      });
    }
  }
}

const _kMaybePopLabel = 'Go back';
final _heard = <bool>[];
var _canPop = true;

class _ReportHomeRoute extends PageRouteInfo<void> {
  const _ReportHomeRoute() : super(name);

  static const String name = 'ReportHomeRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      body: Builder(
        builder: (context) => Column(
          children: [
            const Text('Page One'),
            TextButton(onPressed: () => context.router.push(const _CountedRoute()), child: const Text('Next page')),
          ],
        ),
      ),
    ),
  );
}

class _HostRoute extends PageRouteInfo<void> {
  const _HostRoute() : super(name);

  static const String name = 'HostRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

class _CountedRoute extends PageRouteInfo<void> {
  const _CountedRoute() : super(name);

  static const String name = 'CountedRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => PopScope(
      canPop: _canPop,
      onPopInvokedWithResult: (didPop, _) => _heard.add(didPop),
      child: Scaffold(
        appBar: AppBar(leading: const AutoLeadingButton()),
        body: Builder(
          builder: (context) => Column(
            children: [
              const Text(name),
              TextButton(onPressed: () => Navigator.maybePop(context), child: const Text(_kMaybePopLabel)),
            ],
          ),
        ),
      ),
    ),
  );
}
