import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // Reproduces https://github.com/Milad-Akarie/auto_route_library/issues/2314
  // Steps: an AutoTabsRouter has routes [first, second, signedIn ? account :
  // signIn]. Open the first tab, then flip signedIn so only the third route
  // changes.
  // Happens: the first and second tab pages are disposed and built again.
  // Should: the first tab page keeps its state; only the third tab changes.
  testWidgets(
    'Swapping one route in AutoTabsRouter.routes keeps the state of the other tabs',
    (WidgetTester tester) async {
      addTearDown(() {
        _signedInNotifier.value = false;
        _FirstTabPageState.initCount = 0;
        _FirstTabPageState.disposeCount = 0;
      });
      final router = RootStackRouter.build(routes: [
        AutoRoute(page: _TabsHostRoute.page, path: '/', initial: true, children: [
          AutoRoute(page: _FirstTabRoute.page, path: 'first', initial: true),
          AutoRoute(page: _SecondTabRoute.page, path: 'second'),
          AutoRoute(page: _SignInTabRoute.page, path: 'sign-in'),
          AutoRoute(page: _AccountTabRoute.page, path: 'account'),
        ]),
      ]);
      await pumpRouterConfigApp(tester, router.config());
      expect(find.text(_FirstTabRoute.name), findsOneWidget);
      expect(_FirstTabPageState.initCount, 1);

      _signedInNotifier.value = true;
      await tester.pumpAndSettle();
      expect(find.text(_FirstTabRoute.name), findsOneWidget);
      expect(_FirstTabPageState.disposeCount, 0);
      expect(_FirstTabPageState.initCount, 1);
    },
    // Still open upstream (#2314): replaceAll rebuilds every tab page, so the
    // first tab is disposed and expect(disposeCount, 0) fails.
    skip: true,
  );
}

final _signedInNotifier = ValueNotifier<bool>(false);

class _TabsHostRoute extends PageRouteInfo<void> {
  const _TabsHostRoute() : super(name);

  static const String name = '_TabsHostRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => ValueListenableBuilder<bool>(
      valueListenable: _signedInNotifier,
      builder: (context, signedIn, _) => AutoTabsRouter(
        routes: [
          const _FirstTabRoute(),
          const _SecondTabRoute(),
          if (signedIn) const _AccountTabRoute() else const _SignInTabRoute(),
        ],
      ),
    ),
  );
}

class _FirstTabRoute extends PageRouteInfo<void> {
  const _FirstTabRoute() : super(name);

  static const String name = '_FirstTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const _FirstTabPage());
}

class _FirstTabPage extends StatefulWidget {
  const _FirstTabPage();

  @override
  State<_FirstTabPage> createState() => _FirstTabPageState();
}

class _FirstTabPageState extends State<_FirstTabPage> {
  static int initCount = 0;
  static int disposeCount = 0;

  @override
  void initState() {
    super.initState();
    initCount++;
  }

  @override
  void dispose() {
    disposeCount++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text(_FirstTabRoute.name));
}

class _SecondTabRoute extends PageRouteInfo<void> {
  const _SecondTabRoute() : super(name);

  static const String name = '_SecondTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}

class _SignInTabRoute extends PageRouteInfo<void> {
  const _SignInTabRoute() : super(name);

  static const String name = '_SignInTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}

class _AccountTabRoute extends PageRouteInfo<void> {
  const _AccountTabRoute() : super(name);

  static const String name = '_AccountTabRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}
