import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'back_test_utils.dart';
import 'router_test_utils.dart';

// Reported as https://github.com/Milad-Akarie/auto_route_library/issues/1936
// Setup, from the report's router (no steps were given): Android; an initial
// 'Welcome' page with a guard that lets everyone in, then CustomRoutes that
// are fullscreen dialogs with slideBottom, a non-opaque one with no
// transition and a duration of 0, and a slideRight one.
// Assumed steps: open each CustomRoute page from Welcome, press system back.
// Happened: back closed the app on every page.
// Should: while the page is on top Flutter tells Android it handles back, and
// the press shows Welcome again.
void main() {
  final pages = ['Create', 'Preview', 'Settings'];
  for (final name in pages) {
    testWidgets(
      'system back leaves the $name custom route',
      (tester) async {
        final router = RootStackRouter.build(
          routes: [
            AutoRoute(
              page: _page('Welcome'),
              path: '/',
              initial: true,
              guards: const [_OpenGuard()],
            ),
            CustomRoute(
              page: _page('Create'),
              path: '/create',
              fullscreenDialog: true,
              transitionsBuilder: TransitionsBuilders.slideBottom,
              duration: const Duration(milliseconds: 400),
              reverseDuration: const Duration(milliseconds: 400),
            ),
            CustomRoute(
              page: _page('Preview'),
              path: '/preview',
              opaque: false,
              fullscreenDialog: true,
              transitionsBuilder: TransitionsBuilders.noTransition,
              duration: .zero,
              reverseDuration: .zero,
            ),
            CustomRoute(
              page: _page('Settings'),
              path: '/settings',
              fullscreenDialog: true,
              transitionsBuilder: TransitionsBuilders.slideRight,
              duration: const Duration(milliseconds: 200),
              reverseDuration: const Duration(milliseconds: 200),
            ),
          ],
        );
        addTearDown(router.dispose);
        final handlesBack = FrameworkHandlesBackRecorder()..listen(tester);
        await tester.pumpWidget(
          MaterialApp.router(
            theme: androidTheme,
            routerConfig: router.config(),
          ),
        );
        await tester.pumpAndSettle();
        final atStart = handlesBack.isHandlingBack;
        unawaited(router.push(NamedRoute(name)));
        await tester.pumpAndSettle();
        expect(handlesBack.isHandlingBack, isTrue);

        await systemBack(tester);

        expectCurrentPage(router, 'Welcome');
        expect((atStart, handlesBack.isHandlingBack), (false, false));
      },
      skip: kIsWeb,
      // Android only: on web Flutter never tells the platform whether it
      // handles back.
    );
  }
}

class _OpenGuard extends AutoRouteGuard {
  const new();

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) =>
      resolver.next();
}

PageInfo _page(String name) =>
    .new(name, builder: (_) => Scaffold(body: Text(name)));
