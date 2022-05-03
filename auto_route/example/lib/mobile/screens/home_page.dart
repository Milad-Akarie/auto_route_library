import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

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

class HomePageState extends State<HomePage> {
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
            // so we play safe
            if (activeIndex == -1) {
              activeIndex = 0;
            }
            return Row(
              children: [
                NavigationRail(
                  destinations: destinations
                      .map((item) => NavigationRailDestination(
                            icon: Icon(item.icon),
                            label: Text(item.label),
                          ))
                      .toList(),
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
        : AutoTabsScaffold(
            homeIndex: 0,
            appBarBuilder: (context, tabsRouter) {
              return AppBar(
                title: Text(tabsRouter.topRoute.name),
                leading: AutoBackButton(),
              );
            },
            routes: [
              BooksTab(),
              ProfileTab(),
              if (_showSettingsTap) SettingsTab(tab: 'tab'),
            ],
            bottomNavigationBuilder: buildBottomNav,
            endDrawer: Drawer(
              child: Column(
                children: [
                  SizedBox(height: 50),
                  SvgPicture.asset(
                    'assets/auto_route_logo.svg',
                    width: 250,
                  ),
                  SizedBox(height: 50),
                  ListTile(
                    leading: Icon(Icons.ad_units_outlined),
                    title: Text("Tab Bar"),
                    onTap: () {
                      context.router.pop();
                      context.router.push(TabbarRoute());
                    },
                  ),
                  SizedBox(height: 5),
                  ListTile(
                    leading: Icon(Icons.source),
                    title: Text("Books"),
                    onTap: () {
                      context.router.pop();
                      context.navigateTo(destinations[0].route);
                    },
                  ),
                  SizedBox(height: 5),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text("Profile"),
                    onTap: () {
                      context.router.pop();
                      context.navigateTo(destinations[1].route);
                    },
                  ),
                  SizedBox(height: 5),
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text("Settings"),
                    onTap: () {
                      context.router.pop();
                      context.navigateTo(destinations[2].route);
                    },
                  ),
                ],
              ),
            ),
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
