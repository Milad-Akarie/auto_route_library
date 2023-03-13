import 'package:flutter/widgets.dart';
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
    router.push(const SecondHostRoute());
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested1Route.name);
    expect(router.urlState.url, '/second');
  });

  testWidgets(
      'Navigating to ${SecondHostRoute.name} with  children[$SecondNested1Route] should present [$SecondNested1Route]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.navigate(const SecondHostRoute());
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested1Route.name);
    expect(router.urlState.url, '/second');
  });

  testWidgets('Pushing ${SecondHostRoute.name} then popping-top should present [$FirstPage]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.push(const SecondHostRoute());
    await tester.pumpAndSettle();

    router.popTop();
    await tester.pumpAndSettle();
    expectTopPage(router, FirstRoute.name);
    expect(router.urlState.url, '/');
  });

  testWidgets(
      'Pushing ${SecondHostRoute.name} with children[$SecondNested1Route, $SecondNested2Route]  should present [$SecondNested2Route]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.push(const SecondHostRoute(children: [
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
    router.navigate(const SecondHostRoute(children: [
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
    router.push(const SecondHostRoute(children: [
      SecondNested1Route(),
      SecondNested2Route(),
    ]));
    await tester.pumpAndSettle();
    router.navigate(
      const SecondHostRoute(children: [
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
    router.push(const SecondHostRoute(
      children: [
        SecondNested1Route(),
        SecondNested2Route(),
      ],
    ));
    await tester.pumpAndSettle();
    router.popTop();
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested1Route.name);
    expect(router.urlState.url, '/second');
  });

  testWidgets('Pushing $SecondHostRoute should add a child router then popping it should remove it',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.push(const SecondHostRoute());
    await tester.pumpAndSettle();
    expect(router.childControllers.length, 1);
    expect(router.urlState.url, '/second');
    router.pop();
    await tester.pumpAndSettle();
    expect(router.childControllers.length, 0);
    expect(router.urlState.url, '/');
  });

  testWidgets(
      'Pushing $SecondHostRoute twice should add 2 child routers then popping once should remove top-child-router',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.pushAll([
      const SecondHostRoute(),
      const SecondHostRoute(),
    ]);
    await tester.pumpAndSettle();
    expect(router.childControllers.length, 2);
    expect(router.urlState.url, '/second');
    router.pop();
    await tester.pumpAndSettle();
    expect(router.childControllers.length, 1);
    expect(router.urlState.url, '/second');
  });

  testWidgets(
    'Obtaining topMostRouter should return SecondHostRoute router',
    (WidgetTester tester) async {
      await pumpRouterApp(tester, router);
      router.push(const SecondHostRoute(children: [SecondNested1Route()]));
      await tester.pumpAndSettle();
      expect(router.topMostRouter(), router.innerRouterOf(SecondHostRoute.name));
    },
  );

  testWidgets(
    'When root router has pageless route, Obtaining topMostRouter from any router in hierarchy should return root router',
    (WidgetTester tester) async {
      await pumpRouterApp(tester, router);
      router.push(const SecondHostRoute(children: [SecondNested1Route()]));
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
      router.push(const SecondHostRoute(children: [SecondNested1Route()]));
      await tester.pumpAndSettle();
      router.pushWidget(const Text('Test'));
      await tester.pumpAndSettle();
      final secondHostRouter = router.innerRouterOf(SecondHostRoute.name)!;
      expect(router.topMostRouter(ignorePagelessRoutes: true), secondHostRouter);
      expect(secondHostRouter.topMostRouter(ignorePagelessRoutes: true), secondHostRouter);
    },
  );
}
