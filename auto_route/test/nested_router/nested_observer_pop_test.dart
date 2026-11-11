import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../back_test_utils.dart';
import '../route_event_recorder.dart';
import '../router_test_utils.dart';

// #1395: a NavigatorObserver given to a nested AutoRouter heard didPush but
// never didPop on Android back.
// Steps: the root router and the nested AutoRouter of DashboardRoute each
// have an observer; the dashboard's first child 'today' is reached through a
// RedirectRoute and has no transition. Push 'details' in the nested router,
// then press back; press back again.
// Should: the first back pops 'details' and the nested observer hears
// didPop for it. The second back pops the dashboard from the root router:
// the root observer hears it, and the nested observer hears nothing more,
// since no page of its own navigator was popped. (The root observer also
// hears the nested pop: observers given to the root router are handed to
// nested routers, see nested_observer_test.dart.)
void main() {
  testWidgets('a nested router observer hears the pop of a nested page', (
    tester,
  ) async {
    final rootEvents = <String>[];
    final nestedEvents = <String>[];
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'HomeRoute',
          path: '/',
          initial: true,
          builder: (_, _) => const Scaffold(body: Text('Home')),
        ),
        NamedRouteDef(
          name: 'DashboardRoute',
          path: '/dashboard',
          builder: (_, _) => AutoRouter(
            navigatorObservers: () => [RouteEventRecorder(nestedEvents)],
          ),
          children: [
            RedirectRoute(path: '', redirectTo: 'today'),
            NamedRouteDef(
              name: 'TodayRoute',
              path: 'today',
              type: .custom(
                transitionsBuilder: TransitionsBuilders.noTransition,
              ),
              builder: (_, _) => const Scaffold(body: Text('Today')),
            ),
            NamedRouteDef(
              name: 'DetailsRoute',
              path: 'details',
              builder: (_, _) => const Scaffold(body: Text('Details')),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(
      tester,
      router,
      observers: () => [RouteEventRecorder(rootEvents)],
    );
    unawaited(router.pushPath('/dashboard'));
    await tester.pumpAndSettle();
    unawaited(router.push(const NamedRoute('DetailsRoute')));
    await tester.pumpAndSettle();
    expect(find.text('Details'), findsOneWidget);
    expect(nestedEvents, ['push TodayRoute', 'push DetailsRoute']);
    nestedEvents.clear();
    rootEvents.clear();

    await systemBack(tester);
    expect(find.text('Today'), findsOneWidget);
    expect(nestedEvents, ['pop DetailsRoute']);
    nestedEvents.clear();
    rootEvents.clear();

    await systemBack(tester);
    expect(find.text('Home'), findsOneWidget);
    expect(rootEvents, ['pop DashboardRoute']);
    expect(nestedEvents, isEmpty);
  });
}
