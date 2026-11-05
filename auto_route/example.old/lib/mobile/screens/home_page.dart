import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:example/mobile/router/router.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Home page of the mobile example, which holds the books, profile and settings
/// tabs.
///
/// On the web it shows a navigation rail, elsewhere a bottom bar.
@RoutePage()
class HomePage extends StatefulWidget {
  /// Creates the page.
  const new({super.key});

  @override
  HomePageState createState() => .new();
}

/// One entry of the home page navigation: the route it opens and how it looks.
class RouteDestination {
  /// All fields are required.
  const new({required this.route, required this.icon, required this.label});

  /// The route that opens when this destination is chosen.
  final PageRouteInfo route;

  /// The icon shown for this destination.
  final IconData icon;

  /// The text shown for this destination.
  final String label;
}

/// State of [HomePage]; builds the navigation and decides whether the settings
/// tab shows.
class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  /// The destinations of the navigation rail shown on the web.
  final destinations = [
    RouteDestination(route: kBooksTab(), icon: Icons.source, label: 'Books'),
    RouteDestination(
      route: kProfileTab(),
      icon: Icons.person,
      label: 'Profile',
    ),
    RouteDestination(
      route: SettingsTab(tab: 'tab'),
      icon: Icons.settings,
      label: 'Settings',
    ),
  ];

  /// Shows or hides the settings tab in the bottom bar.
  void toggleSettingsTap() => setState(() {
    _shouldShowSettingsTap = !_shouldShowSettingsTap;
  });

  bool _shouldShowSettingsTap = true;

  @override
  Widget build(BuildContext context) {
    // builder will rebuild everytime this router's stack
    // updates
    // we need it to indicate which NavigationRailDestination is active
    return kIsWeb
        ? AutoRouter(
            builder: (context, child) {
              // we check for active route index by using
              // router.isRouteActive method
              var activeIndex = destinations.indexWhere(
                (d) => context.router.isRouteActive(d.route.routeName),
              );
              // there might be no active route until router is mounted
              // so we play it safe
              if (activeIndex == -1) {
                activeIndex = 0;
              }
              return Row(
                children: [
                  NavigationRail(
                    destinations: [
                      for (final d in destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          label: Text(d.label),
                        ),
                    ],
                    selectedIndex: activeIndex,
                    onDestinationSelected: (index) {
                      // use navigate instead of push so you won't have
                      // many useless route stacks
                      final destination = destinations.elementAtOrNull(index);
                      if (destination != null) {
                        unawaited(context.navigateTo(destination.route));
                      }
                    },
                  ),
                  // child is the rendered route stack
                  Expanded(child: child),
                ],
              );
            },
          )
        : AutoTabsRouter(
            builder: (context, child) {
              return Scaffold(
                appBar: AppBar(
                  leading: const AutoLeadingButton(),
                  title: Text(context.topRoute.title(context)),
                ),
                body: child,
                bottomNavigationBar: buildBottomNav(context.tabsRouter),
              );
            },
          );
  }

  /// Builds the bottom navigation bar for [tabsRouter].
  ///
  /// Returns an empty box when the active route sets `hideBottomNav` in its
  /// meta.
  Widget buildBottomNav(TabsRouter tabsRouter) {
    final shouldHideBottomNav =
        tabsRouter.topMatch.meta['hideBottomNav'] == true;
    return shouldHideBottomNav
        ? const SizedBox.shrink()
        : BottomNavigationBar(
            currentIndex: tabsRouter.activeIndex,
            onTap: tabsRouter.setActiveIndex,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.source),
                label: 'Books',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
              if (_shouldShowSettingsTap)
                const BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
            ],
          );
  }
}

/// A page with a button that opens the home page.
@RoutePage()
class WelcomeScreen extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoLeadingButton.builder(
      builder: (context, leading) {
        return Scaffold(
          appBar: AppBar(
            leading: leading,
            title: const Text('Welcome'),
            centerTitle: false,
          ),
          body: Center(
            child: ElevatedButton(
              child: const Text('Dashboard'),
              onPressed: () {
                unawaited(context.pushRoute(const HomeRoute()));
              },
            ),
          ),
        );
      },
    );
  }
}
