import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'main_router.dart';

void main() {
  RootStackRouter routerWithChildPath(String path) => .build(
    routes: [
      AutoRoute(page: FirstRoute.page, path: '/', initial: true),
      AutoRoute(
        page: const EmptyShellRoute('ProfileRoute'),
        path: '/profile',
        children: [AutoRoute(page: SecondRoute.page, path: path)],
      ),
    ],
  );

  // flutter/flutter#156382: in go_router, a child route written with a
  // leading '/', as '/setting' under '/profile', built a different url than
  // 'setting'. auto_route refuses it when the routes are read, with an error
  // that names the path, so the url can't come out wrong.
  test('A child path starting with "/" is an error that names it', () {
    final router = routerWithChildPath('/setting');
    addTearDown(router.dispose);
    expect(
      () => router.routeCollection,
      throwsA(isA<FlutterError>().having((e) => e.message, 'message', 'Sub-paths can not start with a "/": /setting')),
    );
  });

  // flutter/flutter#156382, the relative path: '/profile/setting' opens it.
  test('A relative child path matches under its parent', () {
    final router = routerWithChildPath('setting');
    addTearDown(router.dispose);
    final matches = router.matcher.match('/profile/setting')!;
    expect(matches.singleOrNull?.name, 'ProfileRoute');
    expect(matches.singleOrNull?.children!.singleOrNull?.name, SecondRoute.name);
  });
}
