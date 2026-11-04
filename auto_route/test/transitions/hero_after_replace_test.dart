import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

class _Route extends PageRouteInfo<void> {
  const _Route(super.name);
}

/// A page whose Hero holds [label], with the tag every page here shares.
Widget _heroPage(String label) => Scaffold(
  body: Center(
    child: Hero(tag: 'hero', child: Text(label)),
  ),
);

RootStackRouter _buildRouter() => .build(
  routes: [
    AutoRoute(
      path: '/',
      page: PageInfo('ARoute', builder: (_) => _heroPage('hero A')),
    ),
    AutoRoute(
      path: '/b',
      page: PageInfo('BRoute', builder: (_) => _heroPage('hero B')),
    ),
    // As in the reports: a page with no transition either way.
    CustomRoute(
      path: '/c',
      page: PageInfo('CRoute', builder: (_) => const Scaffold(body: Text('CRoute'))),
      duration: .zero,
      reverseDuration: .zero,
    ),
  ],
);

void main() {
  // https://github.com/flutter/flutter/issues/121910: a Hero stayed
  // invisible on the first page after the page its flight went to was
  // removed and a page with no reverse transition was popped back to it.
  // Steps: ARoute and BRoute share a Hero. Push BRoute, then
  // pushAndPopUntil(CRoute) down to ARoute, so BRoute is removed. Pop CRoute.
  // Should: ARoute's Hero shows. It does on Flutter 3.47.9: the Hero is
  // hidden for the first frame of the pop, then shown.
  testWidgets('A Hero shows again after popping a page pushed over the removed page it flew to', (tester) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(const _Route('BRoute')));
    await tester.pumpAndSettle();
    unawaited(router.pushAndPopUntil(const _Route('CRoute'), predicate: (route) => route.settings.name == 'ARoute'));
    await tester.pumpAndSettle();
    expect(router.stack.map((page) => page.name), ['ARoute', 'CRoute']);

    router.pop();
    await tester.pumpAndSettle();
    expect(router.topRoute.name, 'ARoute');
    expect(find.text('hero A'), findsOneWidget, reason: 'the Hero is not offstage');
  });
}
