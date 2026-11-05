import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../router_test_utils.dart';

void main() {
  // Guards https://github.com/Milad-Akarie/auto_route_library/issues/2333
  // Steps: the router has a reevaluateListenable. HomeWrapper's tabs are
  // [feed, myProfile], and feed builds AutoTabsRouter.tabBar for its own
  // children [forYou, following]. Open HomeWrapper on myProfile, so feed is
  // not built yet, fire the reevaluateListenable, then open the feed tab.
  // Reported: "Unsupported operation: Cannot clear an unmodifiable list" from
  // TabsRouter.setupRoutes, building feed's AutoTabsRouter.tabBar.
  // Should: feed shows its first tab, forYou.
  testWidgets(
    'a nested tab bar opened after a reevaluation shows its first tab',
    (tester) async {
      final reevaluateNotifier = ValueNotifier(0);
      addTearDown(reevaluateNotifier.dispose);
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
                  AutoRoute(
                    page: _ForYouFeedRoute.page,
                    path: 'for-you',
                    initial: true,
                  ),
                  AutoRoute(page: _FollowingFeedRoute.page, path: 'following'),
                ],
              ),
              AutoRoute(page: _MyProfileRoute.page, path: 'profile'),
            ],
          ),
        ],
      );
      await pumpRouterApp(
        tester,
        router,
        reevaluationNotifier: reevaluateNotifier,
      );
      unawaited(
        router.replace(const _HomeWrapperRoute(children: [_MyProfileRoute()])),
      );
      await tester.pumpAndSettle();
      expect(find.text(_MyProfileRoute.name), findsOneWidget);

      reevaluateNotifier.value++;
      await tester.pumpAndSettle();

      router
          .innerRouterOf<TabsRouter>(_HomeWrapperRoute.name)!
          .setActiveIndex(0);
      await tester.pumpAndSettle();
      expect(find.text(_ForYouFeedRoute.name), findsOneWidget);
    },
  );
}

abstract final class _SplashRoute {
  static const String name = '_SplashRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text(name)),
  );
}

class _HomeWrapperRoute extends PageRouteInfo<void> {
  const new({required List<PageRouteInfo> children})
    : super(name, initialChildren: children);

  static const String name = '_HomeWrapperRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) =>
        const AutoTabsRouter(routes: [_FeedRoute(), _MyProfileRoute()]),
  );
}

class _FeedRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_FeedRoute';
  static final PageInfo page = PageInfo(
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
  const new() : super(name);

  static const String name = '_ForYouFeedRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _FollowingFeedRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_FollowingFeedRoute';
  static final PageInfo page = PageInfo(name, builder: (_) => const Text(name));
}

class _MyProfileRoute extends PageRouteInfo<void> {
  const new() : super(name);

  static const String name = '_MyProfileRoute';
  static final PageInfo page = PageInfo(
    name,
    builder: (_) => const Scaffold(body: Text(name)),
  );
}
