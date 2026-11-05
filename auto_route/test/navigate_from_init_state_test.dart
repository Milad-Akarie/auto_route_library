import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'forwarder_page.dart';
import 'init_state_caller.dart';
import 'router_test_utils.dart';

void main() {
  // #729: a page that pushed another page from its initState threw "Bad
  // state: Future already completed" over and over once a later page
  // replaced itself with it.
  // Steps: a host page with a nested router of Forwarder (initial), SomeForm
  // and Finish; Forwarder pushes SomeForm from its initState; go back to
  // Forwarder, tap Next to push Finish, then tap Again, which calls
  // replaceRoute(Forwarder) on Finish.
  // Should: nothing throws, and the stack settles on Forwarder, Forwarder and
  // SomeForm, the new Forwarder having pushed SomeForm once.
  testWidgets('replace with a page that pushes from initState settles', (
    tester,
  ) async {
    final router = RootStackRouter.build(
      routes: [
        NamedRouteDef(
          name: 'NestedRoute',
          path: '/',
          initial: true,
          builder: (_, _) => const AutoRouter(),
          children: [
            NamedRouteDef(
              name: 'ForwarderRoute',
              path: '',
              initial: true,
              builder: (_, _) => const ForwarderPage(
                forwardTo: NamedRoute('SomeFormRoute'),
                next: NamedRoute('FinishRoute'),
              ),
            ),
            NamedRouteDef(
              name: 'SomeFormRoute',
              path: 'form',
              builder: (_, _) => const Scaffold(body: Text('Some Form')),
            ),
            NamedRouteDef(
              name: 'FinishRoute',
              path: 'finish',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () => unawaited(
                    context.router.replace(const NamedRoute('ForwarderRoute')),
                  ),
                  child: const Text('Again'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router);
    final nested = router.innerRouterOf<StackRouter>('NestedRoute')!;
    expect(nested.stack.map((page) => page.name), [
      'ForwarderRoute',
      'SomeFormRoute',
    ]);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(nested.stack.map((page) => page.name), ['ForwarderRoute']);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Again'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(nested.stack.map((page) => page.name), [
      'ForwarderRoute',
      'ForwarderRoute',
      'SomeFormRoute',
    ]);
    expect(find.text('Some Form'), findsOneWidget);
  });

  // #853: calling the router from a page's initState, while the page is being
  // built, threw "setState() or markNeedsBuild() called during build" from
  // the delegate's notifyListeners. The last comment's splash page left
  // itself from initState.
  // Steps: the first page is a splash page that, in its initState, calls one
  // of push, replace, replaceAll or pushAndPopUntil to the home page.
  // Should: nothing throws and the home page shows.
  final calls = <String, void Function(StackRouter)>{
    'push': (router) => unawaited(router.push(const NamedRoute('HomeRoute'))),
    'replace': (router) =>
        unawaited(router.replace(const NamedRoute('HomeRoute'))),
    'replaceAll': (router) =>
        unawaited(router.replaceAll([const NamedRoute('HomeRoute')])),
    'pushAndPopUntil': (router) => unawaited(
      router.pushAndPopUntil(
        const NamedRoute('HomeRoute'),
        predicate: (_) => false,
      ),
    ),
  };
  for (final MapEntry(key: name, value: call) in calls.entries) {
    testWidgets("$name from a page's initState shows the next page", (
      tester,
    ) async {
      final router = RootStackRouter.build(
        routes: [
          NamedRouteDef(
            name: 'SplashRoute',
            path: '/',
            initial: true,
            builder: (_, _) => InitStateCaller(call),
          ),
          NamedRouteDef(
            name: 'HomeRoute',
            path: '/home',
            builder: (_, _) => const Scaffold(body: Text('Home')),
          ),
        ],
      );
      await pumpRouterApp(tester, router);

      expect(tester.takeException(), isNull);
      expect(router.current.name, 'HomeRoute');
      expect(find.text('Home'), findsOneWidget);
    });
  }
}
