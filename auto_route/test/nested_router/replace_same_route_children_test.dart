import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

RootStackRouter _buildRouter({bool usersIsInitial = false}) => .build(
  routes: [
    NamedRouteDef(
      name: 'HomeRoute',
      path: '/',
      builder: (_, _) => const Scaffold(body: Text('HomeRoute')),
    ),
    NamedRouteDef(
      name: 'AppRoute',
      path: '/app',
      builder: (_, _) => const AutoRouter(),
      children: [
        NamedRouteDef(
          name: 'UsersRoute',
          path: 'users',
          initial: usersIsInitial,
          builder: (_, _) => const Text('UsersRoute'),
        ),
        NamedRouteDef(name: 'OtherRoute', path: 'other', builder: (_, _) => const Text('OtherRoute')),
      ],
    ),
  ],
);

const NamedRoute _kUsers = NamedRoute('AppRoute', children: [NamedRoute('UsersRoute')]);
const NamedRoute _kOther = NamedRoute('AppRoute', children: [NamedRoute('OtherRoute')]);

StackRouter _shell(RootStackRouter router) => router.innerRouterOf('AppRoute')!;

void main() {
  // Reported by the c3 triage chat while it wrote guard tests for go_router
  // issues. Steps: at '/', push AppRoute(children: [UsersRoute]); then replace
  // it with AppRoute(children: [OtherRoute]).
  // Reported: the shell stays on UsersRoute and the url on '/app/users',
  // while push, navigate and replaceAll open '/app/other'. Once #1363 opened
  // the new children, UsersRoute stayed in the shell under OtherRoute.
  // Should: the shell shows OtherRoute alone, as a new shell would, and the
  // url is '/app/other'.
  testWidgets('replace() with the same parent route shows only its new children', (tester) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(_kUsers));
    await tester.pumpAndSettle();
    expect(find.text('UsersRoute'), findsOneWidget);
    expect(router.urlState.path, '/app/users');

    unawaited(router.replace(_kOther));
    await tester.pumpAndSettle();
    expect(find.text('OtherRoute'), findsOneWidget);
    expect(find.text('UsersRoute'), findsNothing);
    expect(router.stack.map((page) => page.name), ['HomeRoute', 'AppRoute']);
    expect(_shell(router).stack.map((page) => page.name), ['OtherRoute']);
    expect(router.urlState.path, '/app/other');

    // The shell's router still answers for the page that holds it.
    unawaited(router.navigate(_kUsers));
    await tester.pumpAndSettle();
    expect(find.text('UsersRoute'), findsOneWidget);
    expect(router.urlState.path, '/app/users');
  });

  // Given no children, replace() opens the route's initial child, as
  // navigate() with the same route does. With no initial child, the shell
  // keeps the child it shows: there is no other child to open.
  testWidgets('replace() with the same parent route and no children opens its initial child', (tester) async {
    final router = _buildRouter(usersIsInitial: true);
    await pumpRouterApp(tester, router);
    unawaited(router.push(_kOther));
    await tester.pumpAndSettle();

    unawaited(router.replace(const NamedRoute('AppRoute')));
    await tester.pumpAndSettle();
    expect(find.text('UsersRoute'), findsOneWidget);
    expect(find.text('OtherRoute'), findsNothing);
    expect(router.stack.map((page) => page.name), ['HomeRoute', 'AppRoute']);
    expect(router.urlState.path, '/app/users');
  });

  testWidgets('replace() with the same parent route, no children and no initial child keeps the open child', (
    tester,
  ) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(_kUsers));
    await tester.pumpAndSettle();

    unawaited(router.replace(const NamedRoute('AppRoute')));
    await tester.pumpAndSettle();
    expect(find.text('UsersRoute'), findsOneWidget);
    expect(router.stack.map((page) => page.name), ['HomeRoute', 'AppRoute']);
    expect(router.urlState.path, '/app/users');
  });

  // replacePath finds the shell's own router for the path, so it replaces the
  // child there; it worked before and must keep working.
  testWidgets('replacePath() to another child of the same parent route opens it', (tester) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(_kUsers));
    await tester.pumpAndSettle();

    unawaited(router.replacePath('/app/other'));
    await tester.pumpAndSettle();
    expect(find.text('OtherRoute'), findsOneWidget);
    expect(find.text('UsersRoute'), findsNothing);
    expect(router.stack.map((page) => page.name), ['HomeRoute', 'AppRoute']);
    expect(router.urlState.path, '/app/other');
  });

  // pushAndPopUntil removes the parent route's page and puts the route back
  // over it, as replace does; the shell kept showing UsersRoute.
  testWidgets('pushAndPopUntil() with the same parent route opens its new children', (tester) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(_kUsers));
    await tester.pumpAndSettle();

    unawaited(router.pushAndPopUntil(_kOther, predicate: (route) => route.settings.name == 'HomeRoute'));
    await tester.pumpAndSettle();
    expect(find.text('OtherRoute'), findsOneWidget);
    expect(find.text('UsersRoute'), findsNothing);
    expect(router.stack.map((page) => page.name), ['HomeRoute', 'AppRoute']);
    expect(router.urlState.path, '/app/other');
  });

  testWidgets('popAndPush() with the same parent route opens its new children', (tester) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(_kUsers));
    await tester.pumpAndSettle();

    unawaited(router.popAndPush(_kOther));
    await tester.pumpAndSettle();
    expect(find.text('OtherRoute'), findsOneWidget);
    expect(find.text('UsersRoute'), findsNothing);
    expect(router.stack.map((page) => page.name), ['HomeRoute', 'AppRoute']);
    expect(router.urlState.path, '/app/other');
  });

  testWidgets('replace() inside the shell replaces its child', (tester) async {
    final router = _buildRouter();
    await pumpRouterApp(tester, router);
    unawaited(router.push(_kUsers));
    await tester.pumpAndSettle();

    unawaited(_shell(router).replace(const NamedRoute('OtherRoute')));
    await tester.pumpAndSettle();
    expect(find.text('OtherRoute'), findsOneWidget);
    expect(find.text('UsersRoute'), findsNothing);
    expect(_shell(router).stack.map((page) => page.name), ['OtherRoute']);
    expect(router.urlState.path, '/app/other');
  });
}
