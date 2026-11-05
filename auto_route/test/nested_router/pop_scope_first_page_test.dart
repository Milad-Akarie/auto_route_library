import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../main_router.dart';
import '../router_test_utils.dart';

// Reproduction for https://github.com/Milad-Akarie/auto_route_library/issues/2023
// Setup: a host page with an app bar and a nested router whose one page is
// wrapped in PopScope(canPop: false). The nested router is an AutoRouter or
// an AutoRouter.declarative.
// Steps: push the host, then go back: system back, Android's predictive
// back gesture, the iOS edge swipe, or the app bar's back button.
// Happens with the declarative router: the iOS swipe pops the host page
// past the PopScope. With the host as the app's first page, Flutter tells
// Android it doesn't handle back, so Android closes the app.
// Should, as for the same PopScope in a flat route: the host and its page
// stay, PopScope hears of each back the swipe doesn't block, and Flutter
// tells Android it handles back.
void main() {
  final routers = {
    'AutoRouter': () => const AutoRouter(),
    'AutoRouter.declarative': () =>
        AutoRouter.declarative(routes: (_) => [const _GuardedRoute()]),
  };

  for (final MapEntry(key: kind, value: nestedRouter) in routers.entries) {
    group('in an $kind', () {
      late RootStackRouter router;
      setUp(() {
        _popAttempts = 0;
        _nestedRouter = nestedRouter;
        router = RootStackRouter.build(
          routes: [
            AutoRoute(page: FirstRoute.page, path: '/'),
            AutoRoute(
              page: _HostRoute.page,
              path: '/host',
              children: [AutoRoute(page: _GuardedRoute.page, path: '')],
            ),
          ],
        );
        addTearDown(router.dispose);
      });

      Future<void> openHost(WidgetTester tester, {ThemeData? theme}) async {
        await tester.pumpWidget(
          MaterialApp.router(theme: theme, routerConfig: router.config()),
        );
        await tester.pumpAndSettle();
        unawaited(router.push(const _HostRoute()));
        await tester.pumpAndSettle();
        expectTopPage(router, _GuardedRoute.name);
      }

      void expectHostStays() {
        expect(router.stack.map((page) => page.name), [
          FirstRoute.name,
          _HostRoute.name,
        ]);
        expectTopPage(router, _GuardedRoute.name);
      }

      final backs = <String, (Future<void> Function(WidgetTester), ThemeData?)>{
        'system back': (systemBack, null),
        'the predictive back gesture': (predictiveBack, androidTheme),
        'the app bar back button': (tapLeadingBackButton, null),
      };

      for (final MapEntry(key: name, value: (back, theme)) in backs.entries) {
        testWidgets('$name should keep the host when its page has a PopScope', (
          tester,
        ) async {
          await openHost(tester, theme: theme);

          await back(tester);
          expectHostStays();
          expect(_popAttempts, 1);

          await back(tester);
          expectHostStays();
          expect(_popAttempts, 2);
        });
      }

      testWidgets(
        'the iOS back swipe should keep the host when its page has a PopScope',
        (tester) async {
          await openHost(tester, theme: iosTheme);

          await swipeBack(tester);

          expectHostStays();
        },
      );

      // Android only: on web Flutter never tells the platform whether it
      // handles back. Twice each way, as a comment on the issue reports the
      // second back closing the app.
      for (final MapEntry(key: name, value: back) in {
        'system back': systemBack,
        'the predictive back gesture': predictiveBack,
      }.entries) {
        testWidgets(
          'Flutter should tell Android it handles back after $name on a first '
          'page with a PopScope',
          (tester) async {
            router = RootStackRouter.build(
              routes: [
                AutoRoute(
                  page: _HostRoute.page,
                  path: '/',
                  children: [AutoRoute(page: _GuardedRoute.page, path: '')],
                ),
              ],
            );
            addTearDown(router.dispose);
            final frameworkHandlesBack = FrameworkHandlesBackRecorder()
              ..listen(tester);
            await tester.pumpWidget(
              MaterialApp.router(
                theme: androidTheme,
                routerConfig: router.config(),
              ),
            );
            await tester.pumpAndSettle();
            expectTopPage(router, _GuardedRoute.name);
            expect(frameworkHandlesBack.last, isTrue);

            for (var attempt = 1; attempt <= 2; attempt++) {
              await back(tester);
              expect(frameworkHandlesBack.last, isTrue);
              expectTopPage(router, _GuardedRoute.name);
              expect(_popAttempts, attempt);
            }
          },
          skip: kIsWeb,
        );
      }
    });
  }
}

var _popAttempts = 0;
late Widget Function() _nestedRouter;

class _HostRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'HostRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      appBar: AppBar(leading: const AutoLeadingButton()),
      body: _nestedRouter(),
    ),
  );
}

class _GuardedRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'GuardedRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _popAttempts++;
      },
      child: const Text(name),
    ),
  );
}
