import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

//ignore_for_file: public_member_api_docs

@RoutePage()
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class RouteDestination {
  final PageRouteInfo route;
  final IconData icon;
  final String label;

  const RouteDestination({
    required this.route,
    required this.icon,
    required this.label,
  });
}

class HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final destinations = [
    RouteDestination(
      route: BooksTab(),
      icon: Icons.source,
      label: 'Books',
    ),
    RouteDestination(
      route: ProfileTab(),
      icon: Icons.person,
      label: 'Profile',
    ),
    RouteDestination(
      route: SettingsTab(tab: 'tab'),
      icon: Icons.settings,
      label: 'Settings',
    ),
  ];

  void toggleSettingsTap() => setState(() {
        _showSettingsTap = !_showSettingsTap;
      });

  bool _showSettingsTap = true;

  @override
  Widget build(context) {
    // builder will rebuild everytime this router's stack
    // updates
    // we need it to indicate which NavigationRailDestination is active
    return kIsWeb
        ? AutoRouter(builder: (context, child) {
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
                      )
                  ],
                  selectedIndex: activeIndex,
                  onDestinationSelected: (index) {
                    // use navigate instead of push so you won't have
                    // many useless route stacks
                    context.navigateTo(destinations[index].route);
                  },
                ),
                // child is the rendered route stack
                Expanded(child: child)
              ],
            );
          })
        : AutoTabsRouter(
            builder: (context, child) {
              return Scaffold(
                appBar: AppBar(
                  leading: AutoLeadingButton(),
                  title: Text(context.topRoute.title(context)),
                  // bottom: TabBar(
                  //   controller: controller,
                  //   tabs: [for (final d in destinations) Tab(child: Text(d.label))],
                  // ),
                ),
                body: child,
                bottomNavigationBar: buildBottomNav(context, context.tabsRouter),
              );
            },
          );
  }

  Widget buildBottomNav(BuildContext context, TabsRouter tabsRouter) {
    final hideBottomNav = tabsRouter.topMatch.meta['hideBottomNav'] == true;
    return hideBottomNav
        ? SizedBox.shrink()
        : BottomNavigationBar(
            currentIndex: tabsRouter.activeIndex,
            onTap: tabsRouter.setActiveIndex,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.source),
                label: 'Books',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
              if (_showSettingsTap)
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
            ],
          );
  }
}

@RoutePage()
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AutoLeadingButton.builder(builder: (context, leading) {
      return Scaffold(
        appBar: AppBar(
          leading: leading,
          title: Text('Welcome'),
          centerTitle: false,
        ),
        body: Center(
          child: ElevatedButton(
            child: Text('Dashboard'),
            onPressed: () {
              context.pushRoute(HomeRoute());
            },
          ),
        ),
      );
    });
  }
}
