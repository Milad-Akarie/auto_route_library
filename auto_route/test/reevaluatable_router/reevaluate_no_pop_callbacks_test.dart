import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

class _Observer extends AutoRouterObserver {
  final events = <String>[];

  @override
  void didPop(Route<Object?> route, Route<Object?>? previousRoute) =>
      events.add('didPop ${route.settings.name ?? 'null'}');

  @override
  void didRemove(Route<Object?> route, Route<Object?>? previousRoute) =>
      events.add('didRemove ${route.settings.name ?? 'null'}');

  @override
  void didReplace({Route<Object?>? newRoute, Route<Object?>? oldRoute}) => events.add('didReplace');
}

class _EditPage extends StatefulWidget {
  const new({required this.onPop});

  final VoidCallback onPop;

  @override
  State<_EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<_EditPage> {
  static int inits = 0;

  @override
  void initState() {
    super.initState();
    inits++;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (_, _) => widget.onPop(),
      child: const Scaffold(body: Text('EditRoute')),
    );
  }
}

void main() {
  // https://github.com/flutter/flutter/issues/189578
  // In go_router, onExit ran for a pushed route each time refreshListenable
  // fired, as if the user had left it.
  // Steps: push EditRoute, which holds a PopScope with an unsaved-changes
  // callback, and an observer on the router; fire reevaluateListenable three
  // times while EditRoute is on top.
  // Should: no pop callback, no didPop, didRemove or didReplace, and
  // EditRoute's state is kept.
  testWidgets('A reevaluation calls no pop callback for the page on top (flutter/flutter#189578)', (tester) async {
    final user = ValueNotifier(0);
    addTearDown(user.dispose);
    final observer = _Observer();
    var popCallbacks = 0;
    _EditPageState.inits = 0;
    final router = RootStackRouter.build(
      guards: [AutoRouteGuard.simple((resolver, _) => resolver.next())],
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
        ),
        NamedRouteDef(
          name: 'EditRoute',
          path: '/edit',
          builder: (_, _) => _EditPage(onPop: () => popCallbacks++),
        ),
      ],
    );
    await pumpRouterApp(tester, router, reevaluationNotifier: user, observers: () => [observer]);
    unawaited(router.pushPath('/edit'));
    await tester.pumpAndSettle();
    observer.events.clear();

    for (var i = 0; i < 3; i++) {
      user.value++;
      await tester.pumpAndSettle();
    }

    expect(popCallbacks, 0);
    expect(observer.events, isEmpty);
    expect(_EditPageState.inits, 1);
    expectTopPage(router, 'EditRoute');
  });
}
