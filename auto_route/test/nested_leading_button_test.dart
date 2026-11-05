import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'leading_button_page.dart';
import 'router_test_utils.dart';

void main() {
  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/870
  // Setup, as the reporter's: a profile page, and an addresses shell route
  // (an AutoRouter in a page) holding a list page at '' and an add page at
  // 'add'. Every page has its own Scaffold with an AppBar whose leading is an
  // AutoLeadingButton.
  late RootStackRouter router;

  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _ProfileRoute.page, path: '/', initial: true),
        AutoRoute(
          page: _AddressesShellRoute.page,
          path: '/addresses',
          children: [
            AutoRoute(page: _ListRoute.page, path: ''),
            AutoRoute(page: _AddRoute.page, path: 'add'),
          ],
        ),
      ],
    );
  });

  // Steps: from the profile page push the addresses shell, then push the add
  // page inside it.
  // Should: the list page and the add page both show a back button; the first
  // tap goes to the list page, the second to the profile page.
  testWidgets('AutoLeadingButton shows a back button on the pages of a nested router', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    expect(find.byType(BackButton), findsNothing);

    unawaited(router.push(const _AddressesShellRoute()));
    await tester.pumpAndSettle();
    expect(find.text(_ListRoute.name), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);

    unawaited(router.push(const _AddressesShellRoute(children: [_AddRoute()])));
    await tester.pumpAndSettle();
    expect(find.text(_AddRoute.name), findsOneWidget);
    expect(
      find.byType(BackButton),
      findsOneWidget,
      reason: 'after router.push(const _AddressesShellRoute(children: [_AddRo',
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(_ListRoute.name), findsOneWidget, reason: 'after tester.tap(find.byType(BackButton))');

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text(_ProfileRoute.name), findsOneWidget);
  });
}

abstract final class _ProfileRoute {
  static const String name = '_ProfileRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const LeadingButtonPage(name));
}

class _AddressesShellRoute extends PageRouteInfo<void> {
  const new({List<PageRouteInfo>? children}) : super(name, initialChildren: children);

  static const String name = '_AddressesShellRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const AutoRouter());
}

abstract final class _ListRoute {
  static const String name = '_ListRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const LeadingButtonPage(name));
}

class _AddRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_AddRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const LeadingButtonPage(name));
}
