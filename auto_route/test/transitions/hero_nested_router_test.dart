import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/2024
  // A page with a Hero (bottom left) pushes an empty router page; that
  // router's first page has the same Hero (top right).
  // Should: the Hero flies from the first page to the nested one. Before, the
  // nested router added its first page one frame after it was built, so
  // Flutter found no destination Hero when it started the flight, and the
  // source Hero stayed where it was while the new page slid in.
  group('A Hero flies to the first page of a nested router', () {
    late RootStackRouter router;
    setUp(() {
      router = RootStackRouter.build(
        routes: [
          AutoRoute(page: _FromRoute.page, path: '/', initial: true),
          AutoRoute(
            page: _ShellRoute.page,
            path: '/shell',
            children: [AutoRoute(page: _ToRoute.page, path: '', initial: true)],
          ),
        ],
      );
    });

    testWidgets('when the nested router page is pushed without children', (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.push(const _ShellRoute()));
      await _pumpUntilFlight(tester);
      _expectHeroInFlight(tester);
      await tester.pumpAndSettle();
      expect(find.text('to'), findsOneWidget);
    });

    testWidgets('when the nested router page is pushed with its first page', (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.push(const _ShellRoute(children: [_ToRoute()])));
      await _pumpUntilFlight(tester);
      _expectHeroInFlight(tester);
      await tester.pumpAndSettle();
      expect(find.text('to'), findsOneWidget);
    });

    testWidgets('when the nested router page is opened by its path', (tester) async {
      await pumpRouterConfigApp(tester, router.config());
      unawaited(router.pushPath('/shell'));
      await _pumpUntilFlight(tester);
      _expectHeroInFlight(tester);
      await tester.pumpAndSettle();
      expect(find.text('to'), findsOneWidget);
    });
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/1873
  // The page of a settings router (it has its own HeroControllerScope, as the
  // comments advise) pushes an account router page, a shell whose first page
  // has the same Hero.
  // Should: the Hero flies to the account page like it does to a plain page.
  testWidgets('A Hero flies from a nested router page to the first page of a shell route', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _HeroShellRoute.page,
          path: '/',
          children: [
            AutoRoute(page: _FromRoute.page, path: '', initial: true),
            AutoRoute(
              page: _ShellRoute.page,
              path: 'account',
              children: [AutoRoute(page: _ToRoute.page, path: '', initial: true)],
            ),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    expect(find.text('from'), findsOneWidget);

    unawaited(router.push(const _ShellRoute()));
    await _pumpUntilFlight(tester);
    _expectHeroInFlight(tester);
    await tester.pumpAndSettle();
    expect(find.text('to'), findsOneWidget);
  });

  // https://github.com/flutter/flutter/issues/192043
  // go_router 18.0.0: Heroes stopped flying between two pages that both live
  // in a ShellRoute, though they flew in 17.5.0. Here the shell is a page with
  // its own HeroControllerScope and a nested router, holding both pages.
  // Steps: push the second page inside the shell.
  // Should: the Hero flies, as it does between two pages of the root router.
  testWidgets('A Hero flies between two pages of a shell route (flutter/flutter#192043)', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          page: _HeroShellRoute.page,
          path: '/',
          children: [
            AutoRoute(page: _FromRoute.page, path: '', initial: true),
            AutoRoute(page: _ToRoute.page, path: 'to'),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    expect(find.text('from'), findsOneWidget);

    unawaited(router.innerRouterOf<StackRouter>(_HeroShellRoute.name)!.push(const _ToRoute()));
    await _pumpUntilFlight(tester);
    _expectHeroInFlight(tester);
    await tester.pumpAndSettle();
    expect(find.text('to'), findsOneWidget);
  });

  // The flight a plain page gets, so the checks above mean something.
  testWidgets('A Hero flies between two pages of the same router', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _FromRoute.page, path: '/', initial: true),
        AutoRoute(page: _ToRoute.page, path: '/to'),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const _ToRoute()));
    await _pumpUntilFlight(tester);
    _expectHeroInFlight(tester);
    await tester.pumpAndSettle();
  });

  // A guard needs a context, so a guarded first page is still added one frame
  // later; the page must still open.
  testWidgets('The guarded first page of a nested router still opens', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _FromRoute.page, path: '/', initial: true),
        AutoRoute(
          page: _ShellRoute.page,
          path: '/shell',
          children: [
            AutoRoute(
              page: _ToRoute.page,
              path: '',
              initial: true,
              guards: [AutoRouteGuard.simple((resolver, _) => resolver.next())],
            ),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(const _ShellRoute()));
    await tester.pumpAndSettle();
    expect(find.text('to'), findsOneWidget);
    expect(router.topRoute.name, _ToRoute.name);
  });
}

Future<void> _pumpUntilFlight(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

// While the Hero flies, its child is shown by the overlay and not by the
// first page; the Hero's end page is at its place on the second page only at
// the end.
void _expectHeroInFlight(WidgetTester tester) {
  expect(find.text('from'), findsNothing, reason: 'the source Hero should have left its page');
  final position = tester.getTopLeft(find.text('to').last);
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  expect(position.dy, greaterThan(size.height / 4), reason: 'the Hero should still be on its way up');
  expect(position.dx, lessThan(size.width / 2), reason: 'the Hero should still be on its way right');
}

Widget _heroPage(String name, Alignment alignment) {
  return Scaffold(
    body: Align(
      alignment: alignment,
      child: Hero(
        tag: 'box',
        child: SizedBox(width: 50, height: 50, child: Text(name)),
      ),
    ),
  );
}

class _FromRoute extends PageRouteInfo<void> {
  const _FromRoute() : super(name);

  static const String name = 'FromRoute';
  static PageInfo page = PageInfo(name, builder: (_) => _heroPage('from', .bottomLeft));
}

class _ToRoute extends PageRouteInfo<void> {
  const _ToRoute() : super(name);

  static const String name = 'ToRoute';
  static PageInfo page = PageInfo(name, builder: (_) => _heroPage('to', .topRight));
}

class _ShellRoute extends PageRouteInfo<void> {
  const _ShellRoute({List<PageRouteInfo>? children}) : super(name, initialChildren: children);

  static const String name = 'ShellRoute';
  static PageInfo page = const PageInfo.emptyShell(name);
}

class _HeroShellRoute extends PageRouteInfo<void> {
  const _HeroShellRoute() : super(name);

  static const String name = 'HeroShellRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const _HeroShell());
}

class _HeroShell extends StatefulWidget {
  const _HeroShell();

  @override
  State<_HeroShell> createState() => _HeroShellState();
}

class _HeroShellState extends State<_HeroShell> {
  final _controller = HeroController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HeroControllerScope(controller: _controller, child: const AutoRouter());
  }
}
