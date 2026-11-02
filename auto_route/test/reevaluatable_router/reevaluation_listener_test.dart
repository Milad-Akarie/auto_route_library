import 'package:auto_route/auto_route.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
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

// testing resolver.redirectUntil
  testWidgets('Reevaluation with redirectUntil should navigate accordingly', (WidgetTester tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, initial: true),
        AutoRoute.guarded(
          page: SecondRoute.page,
          onNavigation: (resolver, router) async {
            mockListener.call(resolver, router);
            if (reevaluationNotifier.value) {
              resolver.next(true);
            } else {
              resolver.redirectUntil(ThirdRoute());
            }
          },
        ),
        AutoRoute(page: ThirdRoute.page),
      ],
      defaultRouteType: RouteType.custom(
        reverseDuration: Duration.zero,
        duration: Duration.zero,
      ),
    );
    await pumpRouterApp(tester, router, reevaluationNotifier: reevaluationNotifier);
    expectTopPage(router, FirstRoute.name);
    router.push(const SecondRoute());
    await tester.pumpAndSettle();
    verify(mockListener(captureAny, router)).called(1);
    await tester.pumpAndSettle(Duration(milliseconds: 800));
    expectTopPage(router, ThirdRoute.name);
    reevaluationNotifier.value = true;
    await tester.pumpAndSettle();
    final resolver = verify(mockListener(captureAny, router)).captured[0] as NavigationResolver;
    expect(resolver.isReevaluating, true);
    expectTopPage(router, SecondRoute.name);
  });

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/pull/2318
  // Steps: show a tabs page whose second tab hosts its own AutoTabsRouter and
  // has not been opened yet, fire reevaluateListenable, then open that tab.
  // Happens: opening the tab crashes with "Unsupported operation: Cannot clear
  // an unmodifiable list", because the reevaluation gave the unopened tab a
  // const list of pending children that TabsRouter.setupRoutes later clears.
  // Should happen: the tab opens and shows its first nested page.
  testWidgets('Opening a nested tabs page after reevaluation should not crash', (WidgetTester tester) async {
    const innerTabsName = 'InnerTabsRoute';
    final router = RootStackRouter.build(routes: [
      AutoRoute(
        initial: true,
        page: TabsHostRoute.page,
        children: [
          AutoRoute(page: Tab1Route.page),
          AutoRoute(
            page: PageInfo(innerTabsName, builder: (_) => const AutoTabsRouter()),
            children: [
              AutoRoute(page: Tab2Nested1Route.page),
              AutoRoute(page: Tab2Nested2Route.page),
            ],
          ),
        ],
      ),
    ]);
    await pumpRouterConfigApp(
      tester,
      router.config(
        reevaluateListenable: reevaluationNotifier,
        deepLinkBuilder: (_) => DeepLink.single(TabsHostRoute(useDefaultRoutes: true)),
      ),
    );
    expectTopPage(router, Tab1Route.name);
    reevaluationNotifier.value = true;
    await tester.pumpAndSettle();
    router.innerRouterOf<TabsRouter>(TabsHostRoute.name)!.setActiveIndex(1);
    await tester.pumpAndSettle();
    expectTopPage(router, Tab2Nested1Route.name);
  });

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/pull/2343
  // Steps: tap the guarded initial page's counter to 1, fire
  // reevaluateListenable so its guard calls redirectUntil(SecondRoute), then
  // fire it again so the guard lets the page through.
  // Happens: the guarded page is dropped while the guard redirects, so the
  // stack is only [SecondRoute] and the counter is lost.
  // Should happen: the stack is [FirstRoute, SecondRoute], then [FirstRoute]
  // with the counter still at 1.
  testWidgets('Reevaluation with redirectUntil should keep the state of the reevaluated page',
      (WidgetTester tester) async {
    final isLoggedIn = ValueNotifier(true);
    final router = RootStackRouter.build(routes: [
      AutoRoute.guarded(
        initial: true,
        page: PageInfo(FirstRoute.name, builder: (_) => const _CounterPage()),
        onNavigation: (resolver, router) {
          if (isLoggedIn.value) {
            resolver.next();
          } else {
            resolver.redirectUntil(const SecondRoute());
          }
        },
      ),
      AutoRoute(page: SecondRoute.page),
    ]);
    await pumpRouterApp(tester, router, reevaluationNotifier: isLoggedIn);
    await tester.tap(find.text('${FirstRoute.name} 0'));
    await tester.pump();
    isLoggedIn.value = false;
    await tester.pumpAndSettle();
    expect(router.stack.map((e) => e.name), [FirstRoute.name, SecondRoute.name]);
    isLoggedIn.value = true;
    await tester.pumpAndSettle();
    expect(router.stack.map((e) => e.name), [FirstRoute.name]);
    expect(find.text('${FirstRoute.name} 1'), findsOneWidget);
  });

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/pull/2343
  // Steps: push the guarded SecondRoute, fire reevaluateListenable so its guard
  // calls redirectUntil(ThirdRoute), then pop ThirdRoute.
  // Happens: SecondRoute is dropped while the guard redirects, so the stack is
  // [FirstRoute, ThirdRoute].
  // Should happen: the stack is [FirstRoute, SecondRoute, ThirdRoute], and
  // popping ThirdRoute without passing the guard also removes SecondRoute.
  testWidgets('Reevaluation with redirectUntil should remove the reevaluated page when rejected',
      (WidgetTester tester) async {
    final router = RootStackRouter.build(routes: [
      AutoRoute(page: FirstRoute.page, initial: true),
      AutoRoute.guarded(
        page: SecondRoute.page,
        onNavigation: (resolver, router) {
          if (reevaluationNotifier.value) {
            resolver.redirectUntil(const ThirdRoute());
          } else {
            resolver.next();
          }
        },
      ),
      AutoRoute(page: ThirdRoute.page),
    ]);
    await pumpRouterApp(tester, router, reevaluationNotifier: reevaluationNotifier);
    router.push(const SecondRoute());
    await tester.pumpAndSettle();
    reevaluationNotifier.value = true;
    await tester.pumpAndSettle();
    expect(router.stack.map((e) => e.name), [FirstRoute.name, SecondRoute.name, ThirdRoute.name]);
    router.maybePop();
    await tester.pumpAndSettle();
    expectTopPage(router, FirstRoute.name);
  });

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/pull/2341
  // Steps: push a page whose async guard is still pending, then call
  // reevaluateGuards three times before the first guard check finishes.
  // Happens: the waiting reevaluations each complete the same completer and
  // throw "Bad state: Future already completed".
  // Should happen: each reevaluation waits its turn, the guard runs once per
  // reevaluation, and the page shows once the guard passes.
  testWidgets('Overlapping reevaluations wait for a running guard without crashing', (WidgetTester tester) async {
    var calls = 0;
    final router = RootStackRouter.build(routes: [
      AutoRoute(page: FirstRoute.page, initial: true),
      AutoRoute(
        page: SecondRoute.page,
        guards: [
          AutoRouteGuard.simple((resolver, router) async {
            calls++;
            await Future<void>.delayed(const Duration(milliseconds: 50));
            if (reevaluationNotifier.value) resolver.next(true);
          }),
        ],
      ),
    ])
      ..ignorePopCompleters = true;
    await pumpRouterApp(tester, router);
    router.push(const SecondRoute());
    await tester.pumpAndSettle();
    expect(calls, 1);

    // Three passes reach the same pending resolver while the first one's guard runs.
    router.reevaluateGuards();
    router.reevaluateGuards();
    router.reevaluateGuards();
    await tester.pump(const Duration(milliseconds: 200));
    expect(calls, 4);

    reevaluationNotifier.value = true;
    router.reevaluateGuards();
    await tester.pumpAndSettle();
    expectTopPage(router, SecondRoute.name);
  });
}

class _CounterPage extends StatefulWidget {
  const _CounterPage();

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => counter++),
      child: Text('${context.routeData.name} $counter'),
    );
  }
}
