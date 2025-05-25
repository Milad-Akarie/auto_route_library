import 'package:auto_route/src/router/controller/routing_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../main_router.dart';
import '../router_test_utils.dart';
import '../test_page.dart';
import 'router.dart';

void main() {
  late NestedRouter router;
  setUp(() {
    router = NestedRouter();
  });

  testWidgets('Pushing ${SecondHostRoute.name} with no children should present [$SecondNested1Route]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.push(SecondHostRoute());
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested1Route.name);
    expect(router.urlState.url, '/second');
  });

  testWidgets(
      'Navigating to ${SecondHostRoute.name} with  children[$SecondNested1Route] should present [$SecondNested1Route]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.navigate(SecondHostRoute());
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested1Route.name);
    expect(router.urlState.url, '/second');
  });

  testWidgets('Pushing ${SecondHostRoute.name} then popping-top should present [$FirstPage]',
      (WidgetTester tester) async {
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
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.push(SecondHostRoute(children: const [
      SecondNested1Route(),
      SecondNested2Route(),
    ]));
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested2Route.name);
    expect(router.urlState.url, '/second/nested2');
  });

  testWidgets(
      'Navigating to ${SecondHostRoute.name} with children[$SecondNested1Route, $SecondNested2Route]  should present [$SecondNested2Route]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.navigate(SecondHostRoute(children: const [
      SecondNested1Route(),
      SecondNested2Route(),
    ]));
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested2Route.name);
    expect(router.urlState.url, '/second/nested2');
  });

  testWidgets(
      'Navigating to $SecondHostRoute with children[$SecondNested2Route] when both routes are already at the top of their stacks should present [$SecondNested2Route]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.push(SecondHostRoute(children: const [
      SecondNested1Route(),
      SecondNested2Route(),
    ]));
    await tester.pumpAndSettle();
    router.navigate(
      SecondHostRoute(children: const [
        SecondNested2Route(),
      ]),
    );
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested2Route.name);
    expect(router.urlState.url, '/second/nested2');
  });

  testWidgets(
      'Pushing ${SecondHostRoute.name} with children[$SecondNested1Route, $SecondNested2Route] then popping-top should present [$SecondNested1Route]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.push(SecondHostRoute(
      children: const [
        SecondNested1Route(),
        SecondNested2Route(),
      ],
    ));
    await tester.pumpAndSettle();
    router.maybePopTop();
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested1Route.name);
    expect(router.urlState.url, '/second');
  });

  testWidgets('Pushing $SecondHostRoute should add a child router then popping it should remove it',
      (WidgetTester tester) async {
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
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.pushAll([
      SecondHostRoute(),
      SecondHostRoute(),
    ]);
    await tester.pumpAndSettle();
    expect(router.childControllers.length, 2);
    expect(router.urlState.url, '/second');
    router.maybePop();
    await tester.pumpAndSettle();
    expect(router.childControllers.length, 1);
    expect(router.urlState.url, '/second');
  });

  testWidgets(
    'Pushing ${SecondHostRoute.name} should show back leading in AutoLeadingButton',
    (WidgetTester tester) async {
      await pumpRouterApp(tester, router);
      router.push(SecondHostRoute());
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
    },
  );

  testWidgets(
    'Pushing ${SecondHostRoute.name}  should show back leading in Custom AutoLeadingButton',
    (WidgetTester tester) async {
      await pumpRouterApp(tester, router);
      router.push(SecondHostRoute());
      await tester.pumpAndSettle();
      expect(find.byType(BackButton), findsOneWidget);
    },
  );

  testWidgets(
      'Initializing App with ${SecondHostRoute.name} with drawer should show drawer toggle leading in AutoLeadingButton',
      (WidgetTester tester) async {
    await pumpRouterConfigApp(
      tester,
      router.config(
        deepLinkBuilder: (_) => DeepLink.single(
          SecondHostRoute(hasDrawer: true),
        ),
      ),
    );
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });

  testWidgets(
      'Initializing App with ${SecondHostRoute.name} with no drawer  should show empty leading in AutoLeadingButton',
      (WidgetTester tester) async {
    await pumpRouterConfigApp(
      tester,
      router.config(
        deepLinkBuilder: (_) => DeepLink.single(
          SecondHostRoute(hasDrawer: false),
        ),
      ),
    );
    expect(find.byIcon(Icons.menu), findsNothing);
  });

  testWidgets(
      'Initializing App with ${SecondHostRoute.name} should show drawer toggle leading in Custom AutoLeadingButton',
      (WidgetTester tester) async {
    await pumpRouterConfigApp(
      tester,
      router.config(
        deepLinkBuilder: (_) => DeepLink.single(
          SecondHostRoute(
            hasDrawer: true,
            useCustomLeading: true,
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });

  testWidgets(
      'Initializing App with ${SecondHostRoute.name} then pushing a second-nested child should show back leading in AutoLeadingButton',
      (WidgetTester tester) async {
    await pumpRouterConfigApp(
        tester,
        router.config(
          deepLinkBuilder: (_) => DeepLink.single(SecondHostRoute()),
        ));
    router.push(const SecondNested2Route());
    await tester.pumpAndSettle();
    expect(find.byType(CloseButton), findsOneWidget);
  });

  testWidgets(
      'Initializing App with ${SecondHostRoute.name} then pushing a second-nested child should show close leading in Custom AutoLeadingButton',
      (WidgetTester tester) async {
    await pumpRouterConfigApp(
      tester,
      router.config(
        deepLinkBuilder: (_) => DeepLink.single(
          SecondHostRoute(useCustomLeading: true),
        ),
      ),
    );
    router.push(const SecondNested2Route());
    await tester.pumpAndSettle();
    expect(find.byType(CloseButton), findsOneWidget);
  });

  testWidgets(
    'Obtaining topMostRouter should return SecondHostRoute router',
    (WidgetTester tester) async {
      await pumpRouterApp(tester, router);
      router.push(SecondHostRoute(children: const [SecondNested1Route()]));
      await tester.pumpAndSettle();
      expect(router.topMostRouter(), router.innerRouterOf(SecondHostRoute.name));
    },
  );

  testWidgets(
    'When root router has pageless route, Obtaining topMostRouter from any router in hierarchy should return root router',
    (WidgetTester tester) async {
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
    (WidgetTester tester) async {
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
}
