import 'package:flutter_test/flutter_test.dart';

import '../router_test_utils.dart';
import '../test_page.dart';
import 'router.dart';

void main() {
  late AppRouter router;

  setUp(() {
    router = AppRouter();
  });

  testWidgets(
      'Pushing ${SecondRoute.name} with no children should present [$SecondRoute]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.push(const SecondRoute());
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested1Route.name);
    expect(router.urlState.url,'/second/nested1');
  });

  testWidgets(
      'Navigating to ${SecondRoute.name} with no children should present [$SecondRoute]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.navigate(const SecondRoute());
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested1Route.name);
    expect(router.urlState.url,'/second/nested1');
  });

  testWidgets(
      'Pushing ${SecondRoute.name} then popping-top should present [$FirstPage]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.push(const SecondRoute());
    await tester.pumpAndSettle();
    router.popTop();
    await tester.pumpAndSettle();
    expectTopPage(router, FirstRoute.name);
    expect(router.urlState.url,'/first');
  });

  testWidgets(
      'Pushing ${SecondRoute.name} with children[$SecondNested1Route, $SecondNested2Route]  should present [$SecondNested2Route]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.push(const SecondRoute(children: [
      SecondNested1Route(),
      SecondNested2Route(),
    ]));
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested2Route.name);
    expect(router.urlState.url,'/second/nested2');
  });

  testWidgets(
      'Navigating to ${SecondRoute.name} with children[$SecondNested1Route, $SecondNested2Route]  should present [$SecondNested2Route]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.navigate(const SecondRoute(children: [
      SecondNested1Route(),
      SecondNested2Route(),
    ]));
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested2Route.name);
    expect(router.urlState.url,'/second/nested2');
  });

  testWidgets(
      'Navigating to $SecondRoute with children[$SecondNested2Route] when both routes are already at the top of their stacks should present [$SecondNested2Route]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.push(const SecondRoute(children: [
      SecondNested1Route(),
      SecondNested2Route(),
    ]));
    await tester.pumpAndSettle();
    router.navigate(
      const SecondRoute(children: [
        SecondNested2Route(),
      ]),
    );
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested2Route.name);
    expect(router.urlState.url,'/second/nested2');
  });

  testWidgets(
      'Pushing ${SecondRoute.name} with children[$SecondNested1Route, $SecondNested2Route] then popping-top should present [$SecondNested1Route]',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.push(const SecondRoute(
      children: [
        SecondNested1Route(),
         SecondNested2Route(),
      ],
    ));
    await tester.pumpAndSettle();
    router.popTop();
    await tester.pumpAndSettle();
    expectTopPage(router, SecondNested1Route.name);
    expect(router.urlState.url,'/second/nested1');
  });

  testWidgets(
      'Pushing $SecondRoute should add a child router then popping it should remove it',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.push(const SecondRoute());
    await tester.pumpAndSettle();
    expect(router.childControllers.length, 1);
    expect(router.urlState.url,'/second/nested1');
    router.pop();
    await tester.pumpAndSettle();
    expect(router.childControllers.length, 0);
    expect(router.urlState.url,'/first');
  });

  testWidgets(
      'Pushing $SecondRoute twice should add 2 child routers then popping once should remove top-child-router',
      (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.pushAll([
      const SecondRoute(),
      const SecondRoute(),
    ]);
    await tester.pumpAndSettle();
    expect(router.childControllers.length, 2);
    expect(router.urlState.url,'/second/nested1');
    router.pop();
    await tester.pumpAndSettle();
    expect(router.childControllers.length, 1);
    expect(router.urlState.url,'/second/nested1');
  });
}
