import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'router_test_utils.dart';

void main() {
  late _ObserverRouter router;
  late AutoRouteObserver observer;

  setUp(() {
    observer = AutoRouteObserver();
    router = _ObserverRouter();
  });

  Future<void> pumpRouter(WidgetTester tester) => pumpRouterApp(tester, router, observers: () => [observer]);

  testWidgets('AutoRouteObserver should notify subscribers of push and pop events', (tester) async {
    await pumpRouter(tester);
    final state = tester.state<_AutoRouteAwareTestPageState>(find.byType(_AutoRouteAwareTestPage));

    unawaited(router.push(const _SecondRoute()));
    await tester.pumpAndSettle();

    expect(state.didPushNextCalled, isTrue);
    expect(state.didPopNextCalled, isFalse);

    router.pop();
    await tester.pumpAndSettle();

    expect(state.didPopNextCalled, isTrue);
  });

  testWidgets('AutoRouteObserver should notify subscribers of tab events', (tester) async {
    await pumpRouter(tester);
    unawaited(router.push(const _TabsRoute()));
    await tester.pumpAndSettle();

    final activeTabState = tester.state<_AutoRouteAwareTestPageState>(find.byKey(const ValueKey('tab1')));

    expect(activeTabState.didInitTabRouteCalled, isTrue);

    final tabsRouter = router.innerRouterOf<TabsRouter>(_TabsRoute.name);
    expect(tabsRouter, isNotNull);

    // Switch to Tab 2
    tabsRouter?.setActiveIndex(1);
    await tester.pumpAndSettle();

    // Switch back to Tab 1 to trigger didChangeTabRoute for Tab 1
    tabsRouter?.setActiveIndex(0);
    await tester.pumpAndSettle();

    expect(activeTabState.didChangeTabRouteCalled, isTrue);
  });

  // https://github.com/Milad-Akarie/auto_route_library/issues/2315
  // Steps: no tabs or nested routers. The app hands the observer through
  // `config(navigatorObservers: () => [AutoRouteObserver()])`, and the first
  // page's state uses AutoRouteAwareStateMixin. Push a page, then pop it.
  // Reported: didPushNext and didPopNext never fire.
  // Should: both fire. They do when the observer is an AutoRouteObserver; the
  // mixin finds no other kind of observer, so a plain NavigatorObserver or
  // AutoRouterObserver tells it nothing.
  testWidgets('AutoRouteAwareStateMixin hears push and pop with the observer given to config()', (tester) async {
    await pumpRouterConfigApp(tester, router.config(navigatorObservers: () => [AutoRouteObserver()]));
    final state = tester.state<_AutoRouteAwareTestPageState>(find.byType(_AutoRouteAwareTestPage));
    expect(state.didPushCalled, isTrue);

    unawaited(router.push(const _SecondRoute()));
    await tester.pumpAndSettle();
    expect(state.didPushNextCalled, isTrue);

    router.pop();
    await tester.pumpAndSettle();
    expect(state.didPopNextCalled, isTrue);
  });

  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/1774
  // Steps: _FirstRoute has AutoRouteAwareStateMixin. Push _ConfirmRoute, open a
  // dialog there, and tap its button, which closes the dialog with
  // `await context.maybePop()` and then calls `context.navigateTo(_FirstRoute())`.
  // Happens: _ConfirmRoute is removed and _FirstRoute shows, but FirstRoute's
  // didPopNext doesn't fire; the observer gets didRemove, not didPop.
  // Should: _FirstRoute gets didPopNext, as when going back without the dialog.
  testWidgets('navigateTo() back to a page right after closing a dialog tells that page didPopNext', (tester) async {
    await pumpRouter(tester);
    final state = tester.state<_AutoRouteAwareTestPageState>(find.byType(_AutoRouteAwareTestPage));
    unawaited(router.push(const _ConfirmRoute()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(state.didPopNextCalled, isFalse);

    await tester.tap(find.text('Close and go back'));
    await tester.pumpAndSettle();
    expect(router.stack.map((page) => page.name), [_FirstRoute.name]);
    expect(state.didPopNextCalled, isTrue);
  });

  // Same as above, but replace() removes the page over _FirstRoute and pushes
  // another one in its place: _FirstRoute stays covered and hears nothing.
  testWidgets('replacing the page over a page does not tell that page didPopNext', (tester) async {
    await pumpRouter(tester);
    final state = tester.state<_AutoRouteAwareTestPageState>(find.byType(_AutoRouteAwareTestPage));
    unawaited(router.push(const _SecondRoute()));
    await tester.pumpAndSettle();
    unawaited(router.replace(const _ConfirmRoute()));
    await tester.pumpAndSettle();
    expect(router.stack.map((page) => page.name), [_FirstRoute.name, _ConfirmRoute.name]);
    expect(state.didPopNextCalled, isFalse);
  });

  testWidgets('AutoRouteObserver should unsubscribe when widget is disposed', (tester) async {
    await pumpRouter(tester);
    expect(find.byType(_AutoRouteAwareTestPage), findsOneWidget);

    unawaited(router.replace(const _SecondRoute()));
    await tester.pumpAndSettle();

    expect(find.byType(_AutoRouteAwareTestPage), findsNothing);
  });
}

class _AutoRouteAwareTestPage extends StatefulWidget {
  const new({super.key});

  @override
  State<_AutoRouteAwareTestPage> createState() => _AutoRouteAwareTestPageState();
}

class _AutoRouteAwareTestPageState extends State<_AutoRouteAwareTestPage> with AutoRouteAwareStateMixin {
  bool didPushNextCalled = false;
  bool didPopNextCalled = false;
  bool didPushCalled = false;
  bool didInitTabRouteCalled = false;
  bool didChangeTabRouteCalled = false;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SizedBox.expand());
  }

  @override
  void didPushNext() {
    didPushNextCalled = true;
  }

  @override
  void didPopNext() {
    didPopNextCalled = true;
  }

  @override
  void didPush() {
    didPushCalled = true;
  }

  @override
  void didInitTabRoute(TabPageRoute? previousRoute) {
    didInitTabRouteCalled = true;
  }

  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {
    didChangeTabRouteCalled = true;
  }
}

// Router Configuration

class _ObserverRouter extends RootStackRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: _FirstRoute.page, initial: true),
    AutoRoute(page: _SecondRoute.page),
    AutoRoute(page: _ConfirmRoute.page),
    AutoRoute(
      page: _TabsRoute.page,
      children: [
        AutoRoute(page: _Tab1Route.page),
        AutoRoute(page: _Tab2Route.page),
      ],
    ),
  ];
}

class _FirstRoute extends PageRouteInfo<void> {
  const new() : super(_FirstRoute.name);

  static const String name = 'FirstRoute';
  static final PageInfo page = PageInfo(name, builder: (data) => const _AutoRouteAwareTestPage(key: ValueKey('first')));
}

class _SecondRoute extends PageRouteInfo<void> {
  const new() : super(_SecondRoute.name);

  static const String name = 'SecondRoute';
  static final PageInfo page = PageInfo(name, builder: (data) => const Scaffold(body: Text('Second Page')));
}

class _ConfirmRoute extends PageRouteInfo<void> {
  const new() : super(_ConfirmRoute.name);

  static const String name = 'ConfirmRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (data) => Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              actions: [
                TextButton(
                  onPressed: () => unawaited(_closeDialogAndGoBack(dialogContext, context)),
                  child: const Text('Close and go back'),
                ),
              ],
            ),
          ),
          child: const Text('Open dialog'),
        ),
      ),
    ),
  );
}

Future<void> _closeDialogAndGoBack(BuildContext dialogContext, BuildContext context) async {
  await dialogContext.maybePop();
  if (context.mounted) unawaited(context.navigateTo(const _FirstRoute()));
}

class _TabsRoute extends PageRouteInfo<void> {
  const new() : super(_TabsRoute.name);

  static const String name = 'TabsRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (data) => const AutoTabsRouter(routes: [_Tab1Route(), _Tab2Route()]),
  );
}

class _Tab1Route extends PageRouteInfo<void> {
  const new() : super(_Tab1Route.name);

  static const String name = 'Tab1Route';
  static final PageInfo page = PageInfo(name, builder: (data) => const _AutoRouteAwareTestPage(key: ValueKey('tab1')));
}

class _Tab2Route extends PageRouteInfo<void> {
  const new() : super(_Tab2Route.name);

  static const String name = 'Tab2Route';
  static final PageInfo page = PageInfo(name, builder: (data) => const Scaffold(body: Text('Tab 2')));
}
