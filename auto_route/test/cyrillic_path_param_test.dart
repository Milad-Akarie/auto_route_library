import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  late RootStackRouter router;
  setUp(() {
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _HomeRoute.page, path: '/'),
        AutoRoute(page: _FavoriteRoute.page, path: '/home/:name'),
      ],
    );
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/957
  // Call navigatePath('/home/хиты') for the route 'home/:name'. The page
  // should read the name 'хиты', and the url hold it percent-encoded once,
  // not '%2525D1%252585...' as reported.
  testWidgets('navigatePath with a Cyrillic path param reads it back and encodes it once', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.navigatePath('/home/хиты'));
    await tester.pumpAndSettle();
    expect(find.text('Favorite хиты'), findsOneWidget);
    expect(router.urlState.uri.pathSegments, ['home', 'хиты']);
    expect(router.urlState.uri.toString(), '/home/%D1%85%D0%B8%D1%82%D1%8B');
  });

  // Same steps, with the url the browser shows after the first test: it holds
  // the value encoded once, and opening it should read 'хиты' again.
  testWidgets('A deep link holding the encoded Cyrillic path param reads it back', (tester) async {
    await pumpRouterApp(tester, router, initialLink: '/home/%D1%85%D0%B8%D1%82%D1%8B');
    expect(find.text('Favorite хиты'), findsOneWidget);
    expect(router.urlState.uri.toString(), '/home/%D1%85%D0%B8%D1%82%D1%8B');
  });

  testWidgets('Pushing the route with a Cyrillic name encodes it once', (tester) async {
    await pumpRouterConfigApp(tester, router.config());
    unawaited(router.push(_FavoriteRoute(name: 'хиты')));
    await tester.pumpAndSettle();
    expect(find.text('Favorite хиты'), findsOneWidget);
    expect(router.urlState.uri.toString(), '/home/%D1%85%D0%B8%D1%82%D1%8B');
  });
}

class _HomeRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = 'HomeRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Text('Home'));
}

class _FavoriteRoute extends PageRouteInfo<void> {
  new({required String name}) : super(pageName, rawPathParams: {'name': name});

  static const String pageName = 'FavoriteRoute';
  static PageInfo page = PageInfo(
    pageName,
    builder: (data) => Text('Favorite ${data.inheritedPathParams.getString('name')}'),
  );
}
