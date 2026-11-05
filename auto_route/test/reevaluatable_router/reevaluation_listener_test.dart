import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../main_router.dart';
import '../router_test_utils.dart';

class _MockOnNavigationListener extends Mock {
  void call(NavigationResolver? resolver, StackRouter router);
}

void main() {
  late ValueNotifier<bool> reevaluationNotifier;
  late RootStackRouter router;
  late _MockOnNavigationListener mockListener;

  setUp(() {
    mockListener = _MockOnNavigationListener();
    reevaluationNotifier = ValueNotifier(false);
    addTearDown(reevaluationNotifier.dispose);
    router = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, initial: true),
        AutoRoute(
          page: SecondRoute.page,
          guards: [AutoRouteGuard.simple(mockListener.call)],
        ),
        AutoRoute(
          page: ThirdRoute.page,
          guards: [
            AutoRouteGuard.simple((resolver, guardedRouter) {
              mockListener(resolver, guardedRouter);
              if (reevaluationNotifier.value) {
                resolver.next();
              }
            }),
          ],
        ),
      ],
    )..ignorePopCompleters = true;
  });

  testWidgets('Initial route should be ${FirstRoute.name}', (tester) async {
    await pumpRouterApp(tester, router);
    expect(find.text(FirstRoute.name), findsOneWidget);
  });

  testWidgets(
    'Reevaluation should call the guard when reevaluateGuards is called',
    (tester) async {
      await pumpRouterApp(tester, router);
      unawaited(router.navigate(const SecondRoute()));
      await tester.pumpAndSettle();
      verify(mockListener(captureAny, router)).called(1);
      unawaited(router.reevaluateGuards());
      await tester.pumpAndSettle();
      verify(mockListener(captureAny, router)).called(1);
    },
  );

  testWidgets(
    'Reevaluation should call the guard when the reevaluation notifier changes',
    (tester) async {
      await pumpRouterApp(
        tester,
        router,
        reevaluationNotifier: reevaluationNotifier,
      );
      unawaited(router.navigate(const SecondRoute()));
      await tester.pumpAndSettle();
      verify(mockListener(captureAny, router)).called(1);
      reevaluationNotifier.value = true;
      await tester.pumpAndSettle();
      verify(mockListener(captureAny, router)).called(1);
    },
  );

  testWidgets('Reevaluation with true should navigate to the third route', (
    tester,
  ) async {
    await pumpRouterApp(
      tester,
      router,
      reevaluationNotifier: reevaluationNotifier,
    );
    unawaited(router.push(const ThirdRoute()));
    await tester.pumpAndSettle();
    final resolver =
        verify(mockListener(captureAny, router)).captured.firstOrNull
            as NavigationResolver?;
    expect(resolver?.isReevaluating, false);
    verifyNever(mockListener(captureAny, router));
    reevaluationNotifier.value = true;
    await tester.pumpAndSettle();
    expect(
      (verify(mockListener(captureAny, router)).captured.firstOrNull
              as NavigationResolver?)
          ?.isReevaluating,
      true,
    );
    await tester.pumpAndSettle();
    verifyNever(mockListener(captureAny, router));
    expectTopPage(router, ThirdRoute.name);
  });

  testWidgets(
    'Reevaluation should call the guard and navigate to protected page',
    (tester) async {
      final localRouter = RootStackRouter.build(
        routes: [
          AutoRoute(
            initial: true,
            page: FirstRoute.page,
            guards: [
              AutoRouteGuard.simple((resolver, guardedRouter) {
                mockListener(resolver, guardedRouter);
                if (reevaluationNotifier.value) {
                  resolver.next();
                }
              }),
            ],
          ),
        ],
      )..ignorePopCompleters = true;
      await pumpRouterApp(
        tester,
        localRouter,
        reevaluationNotifier: reevaluationNotifier,
      );
      verify(mockListener(captureAny, localRouter)).called(1);
      reevaluationNotifier.value = true;
      await tester.pumpAndSettle();
      expectTopPage(localRouter, FirstRoute.name);
      verify(mockListener(captureAny, localRouter)).called(1);
      verifyNever(mockListener(captureAny, localRouter));
    },
  );

  testWidgets('Reevaluation with false should remove the route', (
    tester,
  ) async {
    reevaluationNotifier.value = true;
    await pumpRouterApp(
      tester,
      router,
      reevaluationNotifier: reevaluationNotifier,
    );
    await router.push(const ThirdRoute());
    await tester.pumpAndSettle();
    expectTopPage(router, ThirdRoute.name);
    reevaluationNotifier.value = false;
    await tester.pumpAndSettle();
    expect(router.current.name, FirstRoute.name);
  });

  testWidgets(
    'Reevaluation should call the guard and navigate to protected page [with '
    'TabRouter]',
    (tester) async {
      const tab2Router = EmptyShellRoute('Tab2Router');
      final localRouter = RootStackRouter.build(
        routes: [
          AutoRoute(
            initial: true,
            page: TabsHostRoute.page,
            children: [
              AutoRoute(page: Tab1Route.page),
              AutoRoute(
                page: tab2Router.page,
                children: [
                  AutoRoute(page: Tab2Nested1Route.page),
                  AutoRoute(
                    page: Tab2Nested2Route.page,
                    guards: [
                      AutoRouteGuard.simple((resolver, guardedRouter) {
                        mockListener(resolver, guardedRouter);
                        if (reevaluationNotifier.value) {
                          resolver.next();
                        }
                      }),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      )..ignorePopCompleters = true;
      await pumpRouterConfigApp(
        tester,
        localRouter.config(
          reevaluateListenable: reevaluationNotifier,
          deepLinkBuilder: (_) => DeepLink.single(
            TabsHostRoute(
              useDefaultRoutes: true,
              children: [
                tab2Router(children: [const Tab2Nested2Route()]),
              ],
            ),
          ),
        ),
      );
      reevaluationNotifier.value = true;
      await tester.pumpAndSettle();
      verifyNever(mockListener(captureAny, localRouter));
    },
  );

  // testing resolver.redirectUntil
  testWidgets('Reevaluation with redirectUntil should navigate accordingly', (
    tester,
  ) async {
    final localRouter = RootStackRouter.build(
      routes: [
        AutoRoute(page: FirstRoute.page, initial: true),
        AutoRoute.guarded(
          page: SecondRoute.page,
          onNavigation: (resolver, guardedRouter) async {
            mockListener(resolver, guardedRouter);
            if (reevaluationNotifier.value) {
              resolver.next();
            } else {
              unawaited(resolver.redirectUntil(const ThirdRoute()));
            }
          },
        ),
        AutoRoute(page: ThirdRoute.page),
      ],
      defaultRouteType: RouteType.custom(
        reverseDuration: .zero,
        duration: .zero,
      ),
    );
    await pumpRouterApp(
      tester,
      localRouter,
      reevaluationNotifier: reevaluationNotifier,
    );
    expectTopPage(localRouter, FirstRoute.name);
    unawaited(localRouter.push(const SecondRoute()));
    await tester.pumpAndSettle();
    verify(mockListener(captureAny, localRouter)).called(1);
    await tester.pumpAndSettle(const Duration(milliseconds: 800));
    expectTopPage(localRouter, ThirdRoute.name);
    reevaluationNotifier.value = true;
    await tester.pumpAndSettle();
    final resolver =
        verify(mockListener(captureAny, localRouter)).captured.firstOrNull
            as NavigationResolver?;
    expect(resolver?.isReevaluating, true);
    expectTopPage(localRouter, SecondRoute.name);
  });

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/pull/2318
  // Steps: show a tabs page whose second tab hosts its own AutoTabsRouter and
  // has not been opened yet, fire reevaluateListenable, then open that tab.
  // Happens: opening the tab crashes with "Unsupported operation: Cannot clear
  // an unmodifiable list", because the reevaluation gave the unopened tab a
  // const list of pending children that TabsRouter.setupRoutes later clears.
  // Should happen: the tab opens and shows its first nested page.
  testWidgets(
    'Opening a nested tabs page after reevaluation should not crash',
    (tester) async {
      const innerTabsName = 'InnerTabsRoute';
      final localRouter = RootStackRouter.build(
        routes: [
          AutoRoute(
            initial: true,
            page: TabsHostRoute.page,
            children: [
              AutoRoute(page: Tab1Route.page),
              AutoRoute(
                page: PageInfo(
                  innerTabsName,
                  builder: (_) => const AutoTabsRouter(),
                ),
                children: [
                  AutoRoute(page: Tab2Nested1Route.page),
                  AutoRoute(page: Tab2Nested2Route.page),
                ],
              ),
            ],
          ),
        ],
      );
      await pumpRouterConfigApp(
        tester,
        localRouter.config(
          reevaluateListenable: reevaluationNotifier,
          deepLinkBuilder: (_) =>
              DeepLink.single(TabsHostRoute(useDefaultRoutes: true)),
        ),
      );
      expectTopPage(localRouter, Tab1Route.name);
      reevaluationNotifier.value = true;
      await tester.pumpAndSettle();
      localRouter
          .innerRouterOf<TabsRouter>(TabsHostRoute.name)!
          .setActiveIndex(1);
      await tester.pumpAndSettle();
      expectTopPage(localRouter, Tab2Nested1Route.name);
    },
  );

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/pull/2343
  // Steps: tap the guarded initial page's counter to 1, fire
  // reevaluateListenable so its guard calls redirectUntil(SecondRoute), then
  // fire it again so the guard lets the page through.
  // Happens: the guarded page is dropped while the guard redirects, so the
  // stack is only [SecondRoute] and the counter is lost.
  // Should happen: the stack is [FirstRoute, SecondRoute], then [FirstRoute]
  // with the counter still at 1.
  testWidgets(
    'Reevaluation with redirectUntil should keep the state of the reevaluated '
    'page',
    (tester) async {
      final isLoggedIn = ValueNotifier(true);
      addTearDown(isLoggedIn.dispose);
      final localRouter = RootStackRouter.build(
        routes: [
          AutoRoute.guarded(
            initial: true,
            page: PageInfo(
              FirstRoute.name,
              builder: (_) => const _CounterPage(),
            ),
            onNavigation: (resolver, guardedRouter) {
              if (isLoggedIn.value) {
                resolver.next();
              } else {
                unawaited(resolver.redirectUntil(const SecondRoute()));
              }
            },
          ),
          AutoRoute(page: SecondRoute.page),
        ],
      );
      await pumpRouterApp(
        tester,
        localRouter,
        reevaluationNotifier: isLoggedIn,
      );
      await tester.tap(find.text('${FirstRoute.name} 0'));
      await tester.pump();
      isLoggedIn.value = false;
      await tester.pumpAndSettle();
      expect(localRouter.stack.map((e) => e.name), [
        FirstRoute.name,
        SecondRoute.name,
      ]);
      isLoggedIn.value = true;
      await tester.pumpAndSettle();
      expect(localRouter.stack.map((e) => e.name), [FirstRoute.name]);
      expect(find.text('${FirstRoute.name} 1'), findsOneWidget);
    },
  );

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/pull/2343
  // Steps: push the guarded SecondRoute, fire reevaluateListenable so its guard
  // calls redirectUntil(ThirdRoute), then pop ThirdRoute.
  // Happens: SecondRoute is dropped while the guard redirects, so the stack is
  // [FirstRoute, ThirdRoute].
  // Should happen: the stack is [FirstRoute, SecondRoute, ThirdRoute], and
  // popping ThirdRoute without passing the guard also removes SecondRoute.
  testWidgets(
    'Reevaluation with redirectUntil should remove the reevaluated page when '
    'rejected',
    (tester) async {
      final localRouter = RootStackRouter.build(
        routes: [
          AutoRoute(page: FirstRoute.page, initial: true),
          AutoRoute.guarded(
            page: SecondRoute.page,
            onNavigation: (resolver, guardedRouter) {
              if (reevaluationNotifier.value) {
                unawaited(resolver.redirectUntil(const ThirdRoute()));
              } else {
                resolver.next();
              }
            },
          ),
          AutoRoute(page: ThirdRoute.page),
        ],
      );
      await pumpRouterApp(
        tester,
        localRouter,
        reevaluationNotifier: reevaluationNotifier,
      );
      unawaited(localRouter.push(const SecondRoute()));
      await tester.pumpAndSettle();
      reevaluationNotifier.value = true;
      await tester.pumpAndSettle();
      expect(localRouter.stack.map((e) => e.name), [
        FirstRoute.name,
        SecondRoute.name,
        ThirdRoute.name,
      ]);
      unawaited(localRouter.maybePop());
      await tester.pumpAndSettle();
      expectTopPage(localRouter, FirstRoute.name);
    },
  );

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/pull/2341
  // Steps: push a page whose async guard is still pending, then call
  // reevaluateGuards three times before the first guard check finishes.
  // Happens: the waiting reevaluations each complete the same completer and
  // throw "Bad state: Future already completed".
  // Should happen: each reevaluation waits its turn, the guard runs once per
  // reevaluation, and the page shows once the guard passes.
  testWidgets(
    'Overlapping reevaluations wait for a running guard without crashing',
    (tester) async {
      var calls = 0;
      final localRouter = RootStackRouter.build(
        routes: [
          AutoRoute(page: FirstRoute.page, initial: true),
          AutoRoute(
            page: SecondRoute.page,
            guards: [
              AutoRouteGuard.simple((resolver, guardedRouter) async {
                calls++;
                await Future<void>.delayed(const Duration(milliseconds: 50));
                if (reevaluationNotifier.value) resolver.next();
              }),
            ],
          ),
        ],
      )..ignorePopCompleters = true;
      await pumpRouterApp(tester, localRouter);
      unawaited(localRouter.push(const SecondRoute()));
      await tester.pumpAndSettle();
      expect(calls, 1);

      // Three passes reach the same pending resolver while the first one's
      // guard runs.
      unawaited(localRouter.reevaluateGuards());
      unawaited(localRouter.reevaluateGuards());
      unawaited(localRouter.reevaluateGuards());
      await tester.pump(const Duration(milliseconds: 200));
      expect(calls, 4);

      reevaluationNotifier.value = true;
      unawaited(localRouter.reevaluateGuards());
      await tester.pumpAndSettle();
      expectTopPage(localRouter, SecondRoute.name);
    },
  );

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/2338
  // Steps: one guard on HomeRoute (initial) and LoginRoute sends a logged-out
  // user from HomeRoute to LoginRoute with redirectUntil; reevaluateListenable
  // is the auth store. Start logged in, tap Increment three times, tap Log out,
  // then tap Log in.
  // Happens (reported on 11.1.0): HomeRoute comes back with its counter at 0.
  // Should happen: HomeRoute comes back with its counter still at 3.
  testWidgets(
    'Logging out and back in should keep the state of the guarded home page '
    '(#2338)',
    (tester) async {
      final authStore = _AuthStore();
      addTearDown(authStore.dispose);
      final authGuard = AutoRouteGuard.simple((resolver, guardedRouter) {
        final isHome = resolver.route.name == _HomePage.routeName;
        if (!isHome || authStore.isLoggedIn) {
          resolver.next();
        } else {
          unawaited(
            resolver.redirectUntil(const PageRouteInfo(_LoginPage.routeName)),
          );
        }
      });
      final localRouter = RootStackRouter.build(
        routes: [
          AutoRoute(
            initial: true,
            page: PageInfo(
              _HomePage.routeName,
              builder: (_) => _HomePage(authStore),
            ),
            guards: [authGuard],
          ),
          AutoRoute(
            page: PageInfo(
              _LoginPage.routeName,
              builder: (_) => _LoginPage(authStore),
            ),
            guards: [authGuard],
          ),
        ],
      );
      await pumpRouterApp(tester, localRouter, reevaluationNotifier: authStore);
      for (var i = 0; i < 3; i++) {
        await tester.tap(find.text('Increment'));
        await tester.pump();
      }
      expect(find.text('Counter 3'), findsOneWidget);
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();
      expect(localRouter.topRoute.name, _LoginPage.routeName);
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();
      expect(localRouter.topRoute.name, _HomePage.routeName);
      expect(
        find.text('Counter 3'),
        findsOneWidget,
        reason: 'after tester.tap(find.text(Log in))',
      );
    },
  );

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/2327
  // Steps: with no guards at all, a button calls push(SecondRoute) and then
  // fires reevaluateListenable in the same callback.
  // Happens (reported): the push is skipped or never becomes visible.
  // Should happen: SecondRoute is pushed and shown.
  testWidgets(
    'Push followed by reevaluation in the same callback should still push '
    '(#2327)',
    (tester) async {
      final localRouter = RootStackRouter.build(
        routes: [
          AutoRoute(
            initial: true,
            page: PageInfo(
              FirstRoute.name,
              builder: (_) => Builder(
                builder: (context) => GestureDetector(
                  onTap: () {
                    unawaited(context.router.push(const SecondRoute()));
                    reevaluationNotifier.value = !reevaluationNotifier.value;
                  },
                  child: const Text('Push and reevaluate'),
                ),
              ),
            ),
          ),
          AutoRoute(page: SecondRoute.page),
        ],
      );
      await pumpRouterApp(
        tester,
        localRouter,
        reevaluationNotifier: reevaluationNotifier,
      );
      await tester.tap(find.text('Push and reevaluate'));
      await tester.pumpAndSettle();
      expect(localRouter.stack.map((e) => e.name), [
        FirstRoute.name,
        SecondRoute.name,
      ]);
      expectTopPage(localRouter, SecondRoute.name);
    },
  );
}

class _CounterPage extends StatefulWidget {
  const new();

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

class _AuthStore extends ChangeNotifier {
  bool isLoggedIn = true;

  void logIn() {
    isLoggedIn = true;
    notifyListeners();
  }

  void logOut() {
    isLoggedIn = false;
    notifyListeners();
  }
}

class _HomePage extends StatefulWidget {
  const new(this.authStore);
  static const routeName = 'HomeRoute';

  final _AuthStore authStore;

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Counter $counter'),
        GestureDetector(
          onTap: () => setState(() => counter++),
          child: const Text('Increment'),
        ),
        GestureDetector(
          onTap: widget.authStore.logOut,
          child: const Text('Log out'),
        ),
      ],
    );
  }
}

class _LoginPage extends StatelessWidget {
  const new(this.authStore);
  static const routeName = 'LoginRoute';

  final _AuthStore authStore;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: authStore.logIn,
        child: const Text('Log in'),
      ),
    );
  }
}
