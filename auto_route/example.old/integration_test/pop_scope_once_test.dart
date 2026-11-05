import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';
import 'support/pages.dart';

// PopScope's onPopInvokedWithResult runs once per back.
// https://github.com/Milad-Akarie/auto_route_library/issues/2126
// Headless test: auto_route/test/pop_scope_once_test.dart
//
// Setup, as in the report: a home page and a second page wrapped in a
// PopScope that records each call, with a button that calls
// Navigator.maybePop(context).
// Steps: push the second page, in a flat route or in a nested router, then
// go back. Again with PopScope(canPop: false), going back twice.
// Reported: onPopInvokedWithResult ran twice for one pop.
// Should: it runs once per back, with didPop true when the page is popped
// and false when PopScope blocks it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('pop scope once', () {
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
    });

    Future<void> openCountedPage(
      WidgetTester tester, {
      required bool isNested,
      ThemeData? theme,
    }) async {
      await pumpRouterApp(tester, router, theme: theme);
      if (isNested) {
        unawaited(router.push(const _HostRoute()));
        await tester.pumpAndSettle();
        unawaited(
          router
              .innerRouterOf<StackRouter>(_HostRoute.name)!
              .push(const _CountedRoute()),
        );
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

    Future<void> tapAppBarBack(WidgetTester tester) async {
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
    }

    final iosTheme = ThemeData(platform: .iOS);
    final backs = <String, (Future<void> Function(WidgetTester), ThemeData?)>{
      'Navigator.maybePop': (tapMaybePop, null),
      'system back': (systemBack, null),
      'the app bar back button': (tapAppBarBack, null),
      'the iOS back swipe': (swipeBack, iosTheme),
    };

    // The reporter's own reproduction: routes with no paths, the home page
    // initial, and a 'Next page' button that pushes the second page.
    testWidgets(
      "the report's 'Go back' button calls onPopInvokedWithResult once",
      (tester) async {
        final reportRouter = RootStackRouter.build(
          routes: [
            AutoRoute(page: _ReportHomeRoute.page, initial: true),
            AutoRoute(page: _CountedRoute.page),
          ],
        );
        await pumpRouterConfigApp(tester, reportRouter.config());
        await tester.tap(find.text('Next page'));
        await tester.pumpAndSettle();
        expect(find.text(_CountedRoute.name), findsOneWidget);

        await tapMaybePop(tester);

        expect(find.text('Page One'), findsOneWidget);
        expect(_heard, [true]);
      },
    );

    for (final isNested in [false, true]) {
      final where = isNested ? 'in a nested router' : 'in a flat route';
      for (final MapEntry(key: name, value: (back, theme)) in backs.entries) {
        testWidgets(
          '$name $where calls onPopInvokedWithResult once',
          (tester) async {
            await openCountedPage(tester, isNested: isNested, theme: theme);

            await back(tester);

            expect(find.text(_CountedRoute.name), findsNothing);
            expect(_heard, [true]);
          },
        );

        // The iOS swipe doesn't start while PopScope blocks the page.
        if (back == swipeBack) continue;

        testWidgets(
          '$name $where with PopScope(canPop: false) calls it once per back',
          (tester) async {
            _canPop = false;
            await openCountedPage(tester, isNested: isNested, theme: theme);

            await back(tester);
            expect(_heard, [false]);
            await back(tester);
            expect(_heard, [false, false]);

            expect(router.topRoute.name, _CountedRoute.name);
          },
        );
      }
    }
  });
}

const _kMaybePopLabel = 'Go back';
final _heard = <bool>[];
var _canPop = true;

class _ReportHomeRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'ReportHomeRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      body: Builder(
        builder: (context) => Column(
          children: [
            const Text('Page One'),
            TextButton(
              onPressed: () => context.router.push(const _CountedRoute()),
              child: const Text('Next page'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HostRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'HostRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

class _CountedRoute extends PageRouteInfo<void> {
  const new() : super(name);

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
              TextButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text(_kMaybePopLabel),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
