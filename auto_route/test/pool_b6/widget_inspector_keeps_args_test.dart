import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../details_args.dart';
import '../router_test_utils.dart';

// https://github.com/Milad-Akarie/auto_route_library/issues/1997
// Setup, as in the report: auto_route 8.3.0, VS Code. It failed on Windows
// only, not on Android, and the maintainer could not reproduce it. The
// reporter says "complex nested navigation", and the trace ends in
// StackRouter._pushAllGuarded, which builds the pages of a router as it
// starts. So the page with a required argument sits inside a nested router:
// ShellRoute shows an AutoRouter over NestedHomeRoute and DetailsRoute.
// Steps: push DetailsRoute with args inside the shell, then turn the
// inspector on. The select button turns on the binding's inspector override,
// which the test does directly; that makes WidgetsApp wrap its tree in a
// WidgetInspector.
// Reported: the error says PostRouteArgs can not be null because the page has
// a required parameter, thrown from RootStackRouter._pageBuilder, as if the
// Router had been mounted again.
// Should: the stack stays Shell, then Details inside it, and Details still
// shows its args.
// Found: on this Flutter the wrapper does mount the Router again (a new
// RouterState), and the nested page and its args stay. The second test
// mounts the app anew under another parent, which is the same remount
// without the inspector, with the nested page open.
// remounted_app_keeps_args_test.dart covers the same remount for a page that
// is not nested.
void main() {
  late int detailsBuilds;

  RootStackRouter buildRouter() {
    detailsBuilds = 0;
    return RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'ShellRoute',
          path: '/',
          initial: true,
          builder: (_, _) => const AutoRouter(),
          children: [
            NamedRouteDef(
              name: 'NestedHomeRoute',
              path: '',
              initial: true,
              builder: (_, _) => const Scaffold(body: Text('Nested home')),
            ),
            NamedRouteDef(
              name: 'DetailsRoute',
              path: 'details',
              builder: (_, data) {
                detailsBuilds++;
                return Scaffold(
                  body: Text('Details ${data.argsAs<DetailsArgs>().id}'),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Future<void> pushDetails(WidgetTester tester, RootStackRouter router) async {
    unawaited(
      router
          .innerRouterOf<StackRouter>('ShellRoute')!
          .push(const NamedRoute('DetailsRoute', args: DetailsArgs(id: 7))),
    );
    await tester.pumpAndSettle();
    expect(find.text('Details 7'), findsOneWidget);
  }

  State<Router<Object?>> routerState(WidgetTester tester) =>
      tester.state(find.byWidgetPredicate((widget) => widget is Router));

  void expectNestedPageKept(RootStackRouter router) {
    expect(
      router
          .innerRouterOf<StackRouter>('ShellRoute')!
          .stack
          .map((page) => page.name),
      ['NestedHomeRoute', 'DetailsRoute'],
    );
    expect(find.text('Details 7'), findsOneWidget);
  }

  testWidgets(
    'Turning the widget inspector on keeps a nested page and its args',
    (tester) async {
      addTearDown(
        () =>
            WidgetsBinding
                    .instance
                    .debugShowWidgetInspectorOverrideNotifier
                    .value =
                false,
      );
      final router = buildRouter();
      await pumpRouterConfigApp(tester, router.config());
      await pushDetails(tester, router);
      final buildsBefore = detailsBuilds;
      final routerBefore = routerState(tester);

      WidgetsBinding.instance.debugShowWidgetInspectorOverrideNotifier.value =
          true;
      await tester.pumpAndSettle();

      expect(find.byType(WidgetInspector), findsOneWidget);
      expect(tester.takeException(), isNull);
      expectNestedPageKept(router);
      expect(
        routerState(tester),
        isNot(same(routerBefore)),
        reason: 'the inspector mounted the Router again, as the report needs',
      );
      expect(detailsBuilds, buildsBefore);
    },
  );

  testWidgets('An app mounted anew keeps a nested page and its args', (
    tester,
  ) async {
    final router = buildRouter();
    final config = router.config();
    await pumpRouterConfigApp(tester, config);
    await pushDetails(tester, router);
    final buildsBefore = detailsBuilds;
    final routerBefore = routerState(tester);

    await tester.pumpWidget(
      Padding(
        padding: const .only(top: 100),
        child: MaterialApp.router(routerConfig: config),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      routerState(tester),
      isNot(same(routerBefore)),
      reason: 'the Router was mounted again',
    );
    expect(tester.takeException(), isNull);
    expectNestedPageKept(router);
    expect(detailsBuilds, greaterThanOrEqualTo(buildsBefore));
  });
}
