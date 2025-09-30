import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../main_router.dart';
import '../router_test_utils.dart';

class MockOnNavigationListener extends Mock {
  void call(NavigationResolver? resolver, StackRouter router);
}

void main() {
  late ValueNotifier<bool> reevaluationNotifier;
  late RootStackRouter router;
  late MockOnNavigationListener mockListener;

  setUp(() {
    mockListener = MockOnNavigationListener();
    reevaluationNotifier = ValueNotifier(false);
    router = RootStackRouter.build(routes: [
      AutoRoute(page: FirstRoute.page, initial: true),
      AutoRoute(
        page: SecondRoute.page,
        guards: [
          AutoRouteGuard.simple(mockListener.call),
        ],
      ),
      AutoRoute(
        page: ThirdRoute.page,
        guards: [
          AutoRouteGuard.simple((resolver, router) {
            mockListener.call(resolver, router);
            if (reevaluationNotifier.value) {
              resolver.next(true);
            }
          }),
        ],
      ),
    ])
      ..ignorePopCompleters = true;
  });

  testWidgets('Initial route should be ${FirstRoute.name}', (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    expect(find.text(FirstRoute.name), findsOneWidget);
  });

  testWidgets('Reevaluation should call the guard', (WidgetTester tester) async {
    await pumpRouterApp(tester, router);
    router.navigate(const SecondRoute());
    await tester.pumpAndSettle();
    verify(mockListener(captureAny, router)).called(1);
    router.reevaluateGuards();
    await tester.pumpAndSettle();
    verify(mockListener(captureAny, router)).called(1);
  });

  testWidgets('Reevaluation should call the guard', (WidgetTester tester) async {
    await pumpRouterApp(tester, router, reevaluationNotifier: reevaluationNotifier);
    router.navigate(const SecondRoute());
    await tester.pumpAndSettle();
    verify(mockListener(captureAny, router)).called(1);
    reevaluationNotifier.value = true;
    await tester.pumpAndSettle();
    verify(mockListener(captureAny, router)).called(1);
  });

  testWidgets('Reevaluation with true should navigate to the third route', (WidgetTester tester) async {
    await pumpRouterApp(tester, router, reevaluationNotifier: reevaluationNotifier);
    router.push(const ThirdRoute());
    await tester.pumpAndSettle();
    final resolver = verify(mockListener(captureAny, router)).captured[0] as NavigationResolver;
    expect(resolver.isReevaluating, false);
    verifyNever(mockListener(captureAny, router));
    reevaluationNotifier.value = true;
    await tester.pumpAndSettle();
    final resolver2 = verify(mockListener(captureAny, router)).captured[0] as NavigationResolver;
    expect(resolver2.isReevaluating, true);
    await tester.pumpAndSettle();
    verifyNever(mockListener(captureAny, router));
    expectTopPage(router, ThirdRoute.name);
  });

  testWidgets('Reevaluation should call the guard and navigate to protected page', (WidgetTester tester) async {
    final router = RootStackRouter.build(routes: [
      AutoRoute(
        initial: true,
        page: FirstRoute.page,
        guards: [
          AutoRouteGuard.simple((resolver, router) {
            mockListener.call(resolver, router);
            if (reevaluationNotifier.value) {
              resolver.next(true);
            }
          }),
        ],
      ),
    ])
      ..ignorePopCompleters = true;
    await pumpRouterApp(tester, router, reevaluationNotifier: reevaluationNotifier);
    verify(mockListener(captureAny, router)).called(1);
    reevaluationNotifier.value = true;
    await tester.pumpAndSettle();
    expectTopPage(router, FirstRoute.name);
    verify(mockListener(captureAny, router)).called(1);
    verifyNever(mockListener(captureAny, router));
  });

  testWidgets('Reevaluation with false should remove the route', (WidgetTester tester) async {
    reevaluationNotifier.value = true;
    await pumpRouterApp(tester, router, reevaluationNotifier: reevaluationNotifier);
    await router.push(const ThirdRoute());
    await tester.pumpAndSettle();
    expectTopPage(router, ThirdRoute.name);
    reevaluationNotifier.value = false;
    await tester.pumpAndSettle();
    expect(router.current.name, FirstRoute.name);
  });

  testWidgets('Reevaluation should call the guard and navigate to protected page [with TabRouter]',
      (WidgetTester tester) async {
    final tab2Router = EmptyShellRoute('Tab2Router');
    final router = RootStackRouter.build(routes: [
      AutoRoute(
        initial: true,
        page: TabsHostRoute.page,
        children: [
          AutoRoute(page: Tab1Route.page),
          AutoRoute(page: tab2Router.page, children: [
            AutoRoute(page: Tab2Nested1Route.page),
            AutoRoute(
              page: Tab2Nested2Route.page,
              guards: [
                AutoRouteGuard.simple((resolver, router) {
                  mockListener.call(resolver, router);
                  if (reevaluationNotifier.value) {
                    resolver.next(true);
                  }
                }),
              ],
            ),
          ]),
        ],
      ),
    ])
      ..ignorePopCompleters = true;
    await pumpRouterConfigApp(
        tester,
        router.config(
          reevaluateListenable: reevaluationNotifier,
          deepLinkBuilder: (_) => DeepLink.single(
            TabsHostRoute(
              useDefaultRoutes: true,
              children: [
                tab2Router(children: [Tab2Nested2Route()])
              ],
            ),
          ),
        ));
    reevaluationNotifier.value = true;
    await tester.pumpAndSettle();
    verifyNever(mockListener(captureAny, router));
  });
}
