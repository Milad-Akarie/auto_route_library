import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import '../test_page.dart';
import 'router.dart';

void main() {
  late NestedRouter router;
  setUp(() {
    router = NestedRouter();
  });

  testWidgets('Pushing ${SecondHostRoute.name} with no children should present [$SecondNested1Route]', (tester) async {
    await pumpRouterApp(tester, router);
    router.push(SecondHostRoute());
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested1Route.name);
    expect(router.urlState.url, '/second');
  });

  testWidgets(
    'Navigating to ${SecondHostRoute.name} with  children[$SecondNested1Route] should present [$SecondNested1Route]',
    (tester) async {
      await pumpRouterApp(tester, router);
      router.navigate(SecondHostRoute());
      await tester.pumpAndSettle();
      expectTopPage(router, SecondNested1Route.name);
      expect(router.urlState.url, '/second');
    },
  );

  testWidgets('Pushing ${SecondHostRoute.name} then popping-top should present [$FirstPage]', (tester) async {
    await pumpRouterApp(tester, router);
    router.push(SecondHostRoute());
    await tester.pumpAndSettle();

    router.maybePopTop();
    await tester.pumpAndSettle();
    expectTopPage(router, FirstRoute.name);
    expect(router.urlState.url, '/');
  });

  testWidgets(
    'Pushing ${SecondHostRoute.name} with children[$SecondNested1Route, $SecondNested2Route]  should present [$SecondNested2Route]',
    (tester) async {
      await pumpRouterApp(tester, router);
      router.push(SecondHostRoute(children: const [SecondNested1Route(), SecondNested2Route()]));
      await tester.pumpAndSettle();
      expectTopPage(router, SecondNested2Route.name);
      expect(router.urlState.url, '/second/nested2');
    },
  );

  testWidgets(
    'Navigating to ${SecondHostRoute.name} with children[$SecondNested1Route, $SecondNested2Route]  should present [$SecondNested2Route]',
    (tester) async {
      await pumpRouterApp(tester, router);
      router.navigate(SecondHostRoute(children: const [SecondNested1Route(), SecondNested2Route()]));
      await tester.pumpAndSettle();
      expectTopPage(router, SecondNested2Route.name);
      expect(router.urlState.url, '/second/nested2');
    },
  );

  testWidgets(
    'Navigating to $SecondHostRoute with children[$SecondNested2Route] when both routes are already at the top of their stacks should present [$SecondNested2Route]',
    (tester) async {
      await pumpRouterApp(tester, router);
      router.push(SecondHostRoute(children: const [SecondNested1Route(), SecondNested2Route()]));
      await tester.pumpAndSettle();
      router.navigate(SecondHostRoute(children: const [SecondNested2Route()]));
      await tester.pumpAndSettle();
      expectTopPage(router, SecondNested2Route.name);
      expect(router.urlState.url, '/second/nested2');
    },
  );

  testWidgets(
    'Pushing ${SecondHostRoute.name} with children[$SecondNested1Route, $SecondNested2Route] then popping-top should present [$SecondNested1Route]',
    (tester) async {
      await pumpRouterApp(tester, router);
      router.push(SecondHostRoute(children: const [SecondNested1Route(), SecondNested2Route()]));
      await tester.pumpAndSettle();
      router.maybePopTop();
      await tester.pumpAndSettle();
      expectTopPage(router, SecondNested1Route.name);
      expect(router.urlState.url, '/second');
    },
  );

  testWidgets('Pushing $SecondHostRoute should add a child router then popping it should remove it', (tester) async {
    await pumpRouterApp(tester, router);
    router.push(SecondHostRoute());
    await tester.pumpAndSettle();
    expect(router.childControllers.length, 1);
    expect(router.urlState.url, '/second');
    router.maybePop();
    await tester.pumpAndSettle();
    expect(router.childControllers.length, 0);
    expect(router.urlState.url, '/');
  });

  testWidgets(
    'Pushing $SecondHostRoute twice should add 2 child routers then popping once should remove top-child-router',
    (tester) async {
      await pumpRouterApp(tester, router);
      router.pushAll([SecondHostRoute(), SecondHostRoute()]);
      await tester.pumpAndSettle();
      expect(router.childControllers.length, 2);
      expect(router.urlState.url, '/second');
      router.maybePop();
      await tester.pumpAndSettle();
      expect(router.childControllers.length, 1);
      expect(router.urlState.url, '/second');
    },
  );

  testWidgets('Pushing ${SecondHostRoute.name} should show back leading in AutoLeadingButton', (tester) async {
    await pumpRouterApp(tester, router);
    router.push(SecondHostRoute());
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('Pushing ${SecondHostRoute.name}  should show back leading in Custom AutoLeadingButton', (tester) async {
    await pumpRouterApp(tester, router);
    router.push(SecondHostRoute());
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets(
    'Initializing App with ${SecondHostRoute.name} with drawer should show drawer toggle leading in AutoLeadingButton',
    (tester) async {
      await pumpRouterConfigApp(
        tester,
        router.config(deepLinkBuilder: (_) => DeepLink.single(SecondHostRoute(hasDrawer: true))),
      );
      expect(find.byIcon(Icons.menu), findsOneWidget);
    },
  );

  testWidgets(
    'Initializing App with ${SecondHostRoute.name} with no drawer  should show empty leading in AutoLeadingButton',
    (tester) async {
      await pumpRouterConfigApp(
        tester,
        router.config(deepLinkBuilder: (_) => DeepLink.single(SecondHostRoute(hasDrawer: false))),
      );
      expect(find.byIcon(Icons.menu), findsNothing);
    },
  );

  testWidgets(
    'Initializing App with ${SecondHostRoute.name} should show drawer toggle leading in Custom AutoLeadingButton',
    (tester) async {
      await pumpRouterConfigApp(
        tester,
        router.config(
          deepLinkBuilder: (_) => DeepLink.single(SecondHostRoute(hasDrawer: true, useCustomLeading: true)),
        ),
      );
      expect(find.byIcon(Icons.menu), findsOneWidget);
    },
  );

  testWidgets(
    'Initializing App with ${SecondHostRoute.name} then pushing a second-nested child should show back leading in AutoLeadingButton',
    (tester) async {
      await pumpRouterConfigApp(tester, router.config(deepLinkBuilder: (_) => DeepLink.single(SecondHostRoute())));
      router.push(const SecondNested2Route());
      await tester.pumpAndSettle();
      expect(find.byType(CloseButton), findsOneWidget);
    },
  );

  testWidgets(
    'Initializing App with ${SecondHostRoute.name} then pushing a second-nested child should show close leading in Custom AutoLeadingButton',
    (tester) async {
      await pumpRouterConfigApp(
        tester,
        router.config(deepLinkBuilder: (_) => DeepLink.single(SecondHostRoute(useCustomLeading: true))),
      );
      router.push(const SecondNested2Route());
      await tester.pumpAndSettle();
      expect(find.byType(CloseButton), findsOneWidget);
    },
  );

  testWidgets('Obtaining topMostRouter should return SecondHostRoute router', (tester) async {
    await pumpRouterApp(tester, router);
    router.push(SecondHostRoute(children: const [SecondNested1Route()]));
    await tester.pumpAndSettle();
    expect(router.topMostRouter(), router.innerRouterOf(SecondHostRoute.name));
  });

  testWidgets(
    'When root router has pageless route, Obtaining topMostRouter from any router in hierarchy should return root router',
    (tester) async {
      await pumpRouterApp(tester, router);
      router.push(SecondHostRoute(children: const [SecondNested1Route()]));
      await tester.pumpAndSettle();
      final secondHostRouter = router.innerRouterOf(SecondHostRoute.name)!;
      expect(router.topMostRouter(), secondHostRouter);
      router.pushWidget(const Text('Test'));
      await tester.pumpAndSettle();
      expect(router.topMostRouter(), router);
      expect(secondHostRouter.topMostRouter(), router);
    },
  );

  testWidgets(
    'When root router has pageless route, Obtaining topMostRouter with ignorePagelessRoutes: true from any router in hierarchy should return SecondHostRoute',
    (tester) async {
      await pumpRouterApp(tester, router);
      router.push(SecondHostRoute(children: const [SecondNested1Route()]));
      await tester.pumpAndSettle();
      router.pushWidget(const Text('Test'));
      await tester.pumpAndSettle();
      final secondHostRouter = router.innerRouterOf(SecondHostRoute.name)!;
      expect(router.topMostRouter(ignorePagelessRoutes: true), secondHostRouter);
      expect(secondHostRouter.topMostRouter(ignorePagelessRoutes: true), secondHostRouter);
    },
  );

  // Reproduction for https://github.com/Milad-Akarie/auto_route_library/pull/2086
  // Steps: push SecondHostRoute (its nested router shows SecondNested1Route),
  // remove that last nested page so the nested router has no pages left,
  // then call maybePop on the nested router (what a back press does).
  // Happens: maybePop returns false and SecondHostRoute stays on screen, so a
  // back press would close the app.
  // Should happen: the nested router has nothing to pop, so the parent pops
  // SecondHostRoute, maybePop returns true and the root shows FirstRoute.
  testWidgets('maybePop on a nested router with no pages left should pop the parent router', (tester) async {
    await pumpRouterApp(tester, router);
    router.push(SecondHostRoute());
    await tester.pumpAndSettle();
    final nested = router.innerRouterOf<StackRouter>(SecondHostRoute.name)!;
    nested.removeLast();
    await tester.pumpAndSettle();
    expect(nested.stack, isEmpty);

    final popped = await nested.maybePop();
    await tester.pumpAndSettle();

    expect(popped, isTrue);
    expectTopPage(router, FirstRoute.name);
    expect(router.childControllers, isEmpty);
  });

  // Reproduction for https://github.com/Milad-Akarie/auto_route_library/issues/2309
  // Steps: push SecondHostRoute (it holds a nested AutoRouter), then push a
  // second page into that nested router, then call maybePop on the root router.
  // Happens: maybePop returns true but nothing pops; SecondNested2Route stays
  // on screen.
  // Should happen: the first maybePop returns true and pops SecondNested2Route
  // from the nested router; the second returns true and pops SecondHostRoute.
  // The reporter expected the first call to pop SecondHostRoute at once. This
  // test expects the nested page first instead, the same order system back
  // uses (see back_gesture_test.dart) and the one Flutter's
  // NavigatorPopHandler is built for. Popping the host at once would also
  // override a PopScope the app puts on the host page.
  testWidgets('root maybePop with a child pushed in a nested router should pop the child, then the host route', (
    tester,
  ) async {
    await pumpRouterApp(tester, router);
    router.push(SecondHostRoute());
    await tester.pumpAndSettle();
    router.innerRouterOf<StackRouter>(SecondHostRoute.name)!.push(const SecondNested2Route());
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested2Route.name);

    expect(await router.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested1Route.name);
    expect(router.urlState.url, '/second');

    expect(await router.maybePop(), isTrue);
    await tester.pumpAndSettle();
    expectTopPage(router, FirstRoute.name);
    expect(router.childControllers, isEmpty);
  });

  // Guard for the #2309 fix (https://github.com/Milad-Akarie/auto_route_library/issues/2309):
  // the fix lets a blocked root pop reach the nested router, and it must not
  // override a PopScope the app puts on the host page.
  // Steps: push a host route whose page is PopScope(canPop: false) around an
  // AutoRouter that shows one page, then call maybePop on the root router.
  // Should happen: the host page's PopScope blocks the pop; the host route
  // and its nested page stay on screen.
  testWidgets('root maybePop should respect a PopScope on the host page when the nested router has one page', (
    tester,
  ) async {
    final router = _PopScopeHostRouter();
    await pumpRouterApp(tester, router);
    router.push(const _PopScopeHostRoute());
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested1Route.name);

    await router.maybePop();
    await tester.pumpAndSettle();

    expect(router.current.name, _PopScopeHostRoute.name);
    expectTopPage(router, SecondNested1Route.name);
  });

  // Regression of the #2154 fix (navigate() waits for the route it opens).
  // Steps: navigate to SecondHostRoute, push SecondNested2Route in its inner router, then
  // navigate to SecondHostRoute with children [SecondNested1Route].
  // Happened: the inner router was only updated once the host page was popped.
  // Should: the inner router shows SecondNested1Route right away.
  testWidgets('navigate() to an open host route should update its nested router right away', (tester) async {
    await pumpRouterApp(tester, router);
    router.navigate(SecondHostRoute());
    await tester.pumpAndSettle();
    router.innerRouterOf<StackRouter>(SecondHostRoute.name)!.push(const SecondNested2Route());
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested2Route.name);

    router.navigate(SecondHostRoute(children: const [SecondNested1Route()]));
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested1Route.name);
  });
}

class _PopScopeHostRouter extends MainRouter {
  @override
  final List<AutoRoute> routes = [
    AutoRoute(path: '/', page: FirstRoute.page),
    AutoRoute(
      path: '/host',
      page: _PopScopeHostRoute.page,
      children: [AutoRoute(path: '', page: SecondNested1Route.page)],
    ),
  ];
}

class _PopScopeHostRoute extends PageRouteInfo<void> {
  const _PopScopeHostRoute() : super(_PopScopeHostRoute.name);

  static const String name = 'PopScopeHostRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const PopScope(canPop: false, child: AutoRouter()));
}
