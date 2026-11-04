import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  // https://github.com/Milad-Akarie/auto_route_library/issues/734
  // Steps: log the screens a navigator observer sees, as Firebase Analytics'
  // observer does, while pushing, replacing and popping pages.
  // Reported: a '_placeHolder_' route was seen between every two transitions.
  // Should: the observer only ever sees the routes the app declared.
  testWidgets('observers only see declared routes across push, replace and pop', (tester) async {
    final seen = <String?>[];
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _PageRoute.home, path: '/'),
        AutoRoute(page: _PageRoute.other, path: '/other'),
        AutoRoute(page: _PageRoute.third, path: '/third'),
      ],
    );
    await pumpRouterApp(tester, router, observers: () => [_Recorder(seen)]);

    unawaited(router.push(const _OtherRoute()));
    await tester.pumpAndSettle();
    unawaited(router.replace(const _ThirdRoute()));
    await tester.pumpAndSettle();
    router.pop();
    await tester.pumpAndSettle();
    unawaited(router.navigatePath('/other'));
    await tester.pumpAndSettle();

    expect(seen, isNotEmpty);
    expect(seen.whereType<String>().where((name) => name.contains('laceHolder')), isEmpty);
    expect(seen.toSet(), everyElement(anyOf('HomeRoute', 'OtherRoute', 'ThirdRoute')));
  });
}

class _Recorder extends NavigatorObserver {
  _Recorder(this.seen);

  final List<String?> seen;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => seen.add(route.settings.name);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) => seen.add(newRoute?.settings.name);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => seen.add(previousRoute?.settings.name);
}

class _PageRoute {
  static PageInfo home = PageInfo('HomeRoute', builder: (_) => const Scaffold(body: Text('Home')));
  static PageInfo other = PageInfo('OtherRoute', builder: (_) => const Scaffold(body: Text('Other')));
  static PageInfo third = PageInfo('ThirdRoute', builder: (_) => const Scaffold(body: Text('Third')));
}

class _OtherRoute extends PageRouteInfo<void> {
  const _OtherRoute() : super('OtherRoute');
}

class _ThirdRoute extends PageRouteInfo<void> {
  const _ThirdRoute() : super('ThirdRoute');
}
