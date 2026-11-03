import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';

import 'support/app.dart';

// A nested tab bar opened after a reevaluation shows its first tab.
// https://github.com/Milad-Akarie/auto_route_library/issues/2333
// Headless test: auto_route/test/nested_tabs_router/nested_tab_bar_reevaluation_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Steps: HomeWrapper's tabs are [feed, myProfile]; feed builds
  // AutoTabsRouter.tabBar for [forYou, following]. Tap 'Open profile', so
  // feed is not built yet, tap 'Reevaluate', which fires the router's
  // reevaluateListenable, then tap 'Feed'.
  // Should: feed shows its first tab, forYou.
  testWidgets('a nested tab bar opened after a reevaluation shows its first tab', (tester) async {
    final router = RootStackRouter.build(
      routes: [
        AutoRoute(page: _SplashRoute.page, path: '/', initial: true),
        AutoRoute(
          page: _HomeWrapperRoute.page,
          path: '/home',
          children: [
            AutoRoute(
              page: _FeedRoute.page,
              path: 'feed',
              children: [
                AutoRoute(page: _ForYouFeedRoute.page, path: 'for-you', initial: true),
                AutoRoute(page: _FollowingFeedRoute.page, path: 'following'),
              ],
            ),
            AutoRoute(page: _MyProfileRoute.page, path: 'profile'),
          ],
        ),
      ],
    );
    await pumpRouterApp(tester, router, reevaluationNotifier: _reevaluateNotifier);

    await tester.tap(find.text('Open profile'));
    await tester.pumpAndSettle();
    expect(find.text(_MyProfileRoute.name), findsOneWidget);
    await tester.tap(find.text('Reevaluate'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Feed'));
    await tester.pumpAndSettle();
    expect(find.text(_ForYouFeedRoute.name), findsOneWidget);
  });
}

final _reevaluateNotifier = ValueNotifier(0);

class _SplashRoute extends PageRouteInfo<void> {
  const _SplashRoute() : super(name);

  static const String name = '_SplashRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => Scaffold(
      body: SafeArea(
        child: Builder(
          builder: (context) => TextButton(
            onPressed: () => context.router.replace(const _HomeWrapperRoute(children: [_MyProfileRoute()])),
            child: const Text('Open profile'),
          ),
        ),
      ),
    ),
  );
}

class _HomeWrapperRoute extends PageRouteInfo<void> {
  const _HomeWrapperRoute({List<PageRouteInfo>? children}) : super(name, initialChildren: children);

  static const String name = '_HomeWrapperRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => AutoTabsRouter(
      routes: const [_FeedRoute(), _MyProfileRoute()],
      builder: (context, child) => Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Row(
                children: [
                  TextButton(onPressed: () => AutoTabsRouter.of(context).setActiveIndex(0), child: const Text('Feed')),
                  TextButton(onPressed: () => _reevaluateNotifier.value++, child: const Text('Reevaluate')),
                ],
              ),
              Expanded(child: child),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FeedRoute extends PageRouteInfo<void> {
  const _FeedRoute() : super(name);

  static const String name = '_FeedRoute';
  static PageInfo page = PageInfo(
    name,
    builder: (_) => AutoTabsRouter.tabBar(
      routes: const [_ForYouFeedRoute(), _FollowingFeedRoute()],
      builder: (context, child, tabController) => Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            controller: tabController,
            tabs: const [
              Tab(text: 'For you'),
              Tab(text: 'Following'),
            ],
          ),
        ),
        body: child,
      ),
    ),
  );
}

class _ForYouFeedRoute extends PageRouteInfo<void> {
  const _ForYouFeedRoute() : super(name);

  static const String name = '_ForYouFeedRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _FollowingFeedRoute extends PageRouteInfo<void> {
  const _FollowingFeedRoute() : super(name);

  static const String name = '_FollowingFeedRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _MyProfileRoute extends PageRouteInfo<void> {
  const _MyProfileRoute() : super(name);

  static const String name = '_MyProfileRoute';
  static PageInfo page = PageInfo(name, builder: (_) => const Scaffold(body: Text(name)));
}
