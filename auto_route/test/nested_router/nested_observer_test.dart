import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

// flutter/flutter#112196: a NavigatorObserver didn't hear the pages of a
// shell route's nested navigator.
// Steps: a host page with a nested router showing 'a' (initial) and 'b'; give
// config() an observer; navigate from a to b and push 'details' in the
// nested router.
// Should: the observer hears the pushes of the nested navigator too.
void main() {
  testWidgets('The observer given to config() hears pushes in a nested router', (tester) async {
    final pushes = <String>[];
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'ShellRoute',
          path: '/',
          initial: true,
          builder: (_, _) => const AutoRouter(),
          children: [
            NamedRouteDef(name: 'ARoute', path: 'a', initial: true, builder: (_, _) => const Text('a')),
            NamedRouteDef(name: 'BRoute', path: 'b', builder: (_, _) => const Text('b')),
            NamedRouteDef(name: 'DetailsRoute', path: 'details', builder: (_, _) => const Text('details')),
          ],
        ),
      ],
    );
    await pumpRouterConfigApp(tester, router.config(navigatorObservers: () => [_Recorder(pushes)]));
    expect(pushes, contains('ARoute'));

    unawaited(router.navigate(const NamedRoute('BRoute')));
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('DetailsRoute')));
    await tester.pumpAndSettle();

    expect(pushes, containsAllInOrder(['ARoute', 'BRoute', 'DetailsRoute']));
  });
}

class _Recorder extends AutoRouterObserver {
  new(this.pushes);

  final List<String> pushes;

  @override
  void didPush(Route<Object?> route, Route<Object?>? previousRoute) => pushes.add(route.settings.name ?? 'null');
}
