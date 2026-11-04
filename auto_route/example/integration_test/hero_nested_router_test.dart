import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A Hero flies to the first page of a nested router.
// https://github.com/Milad-Akarie/auto_route_library/issues/2024
// https://github.com/Milad-Akarie/auto_route_library/issues/1873
// Headless tests: auto_route/test/transitions/hero_nested_router_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps (#2024): a page with a Hero at its bottom left pushes an empty
  // router page whose first page has the same Hero at its top right.
  // Should: the Hero flies there; its child leaves the first page.
  testWidgets('A Hero flies from a page to the first page of a nested router', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _FromRoute.page, path: '/'),
        AutoRoute(
          page: _ShellRoute.page,
          path: '/shell',
          children: [
            AutoRoute(page: _ToRoute.page, path: '', initial: true),
          ],
        ),
      ],
    );
    await pumpRouterAppWithConfig(tester, router);
    unawaited(router.push(const _ShellRoute()));
    await _pumpIntoFlight(tester);
    _expectHeroInFlight(tester);
    await tester.pumpAndSettle();
    expect(find.text('to'), findsOneWidget);
  });

  // Steps (#1873): a settings router (with its own HeroControllerScope, as
  // the comments advise) shows a page with a Hero, which pushes an account
  // shell route whose first page has the same Hero.
  // Should: the Hero flies to the account page.
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
              children: [
                AutoRoute(page: _ToRoute.page, path: '', initial: true),
              ],
            ),
          ],
        ),
      ],
    );
    await pumpRouterAppWithConfig(tester, router);
    expect(find.text('from'), findsOneWidget);
    unawaited(router.push(const _ShellRoute()));
    await _pumpIntoFlight(tester);
    _expectHeroInFlight(tester);
    await tester.pumpAndSettle();
    expect(find.text('to'), findsOneWidget);
  });
}

Future<void> _pumpIntoFlight(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

// While the Hero flies, the overlay shows its child and the first page does
// not. The runner's clock is real, so the check leaves out where the Hero is.
void _expectHeroInFlight(WidgetTester tester) {
  expect(find.text('from'), findsNothing, reason: 'the source Hero should have left its page');
  expect(find.text('to'), findsOneWidget);
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
  static PageInfo page = PageInfo(name, builder: (_) => _heroPage('from', Alignment.bottomLeft));
}

class _ToRoute extends PageRouteInfo<void> {
  const _ToRoute() : super(name);

  static const String name = 'ToRoute';
  static PageInfo page = PageInfo(name, builder: (_) => _heroPage('to', Alignment.topRight));
}

class _ShellRoute extends PageRouteInfo<void> {
  const _ShellRoute() : super(name);

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
  Widget build(BuildContext context) {
    return HeroControllerScope(controller: _controller, child: const AutoRouter());
  }
}
