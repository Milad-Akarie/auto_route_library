import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1882
// Steps: Layout at '/' is a shell with meta showBottomNav: true; its children
// are Home at '' (meta true) and Profile at 'profile' (meta false). On Home,
// call navigatePath('/profile') and read the top route's meta after the first frame.
// Reported: the meta of the parent was read, not Profile's, until about 100 ms
// later; the bottom bar showed on Profile. The maintainer's fixes (7.9.1,
// 7.9.2) were confirmed by the reporter.
// Should: topRouteMatch.meta is Profile's right after the call.
void main() {
  testWidgets("top route meta is the destination's right after navigatePath "
      'to a nested route', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(
          path: '/',
          meta: const {'showBottomNav': true},
          page: PageInfo('LayoutRoute', builder: (_) => const AutoRouter()),
          children: [
            AutoRoute(
              path: '',
              meta: const {'showBottomNav': true},
              page: PageInfo('HomeRoute', builder: (_) => const Text('Home')),
            ),
            AutoRoute(
              path: 'profile',
              meta: const {'showBottomNav': false},
              page: PageInfo(
                'ProfileRoute',
                builder: (_) => const Text('Profile'),
              ),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    expect(router.topMatch.meta['showBottomNav'], true);

    unawaited(router.navigatePath('/profile'));
    await tester.pump();
    expect(
      router.topMatch.meta['showBottomNav'],
      false,
      reason: 'after the first frame',
    );
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsOneWidget);
    expect(router.topMatch.meta['showBottomNav'], false);
  });
}
