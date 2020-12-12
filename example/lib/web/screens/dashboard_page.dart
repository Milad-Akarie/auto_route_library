import 'package:auto_route/auto_route.dart';
import 'package:example/web/router/router.gr.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  var activeIndex = 0;
  var railExpanded = false;
  final dashBoardRouterKey = GlobalKey<AutoRouterState>();
  final routes = <PageRouteInfo>[
    BookListPageRoute(),
    SettingsPageRoute(),
  ];

  RoutingController dashBoardRouter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    dashBoardRouter = context.findChildRouter(DashboardPageRoute.key);
  }

  @override
  Widget build(BuildContext context) {
    print('++++building dashaboard');
    final activeRouteKey = dashBoardRouter.currentRoute?.key;
    activeIndex = routes.indexWhere((r) => r.routeKey == activeRouteKey);
    if (activeIndex == -1) activeIndex = 0;

    return Row(
      children: [
        NavigationRail(
          extended: true,
          selectedIndex: activeIndex,
          onDestinationSelected: (index) {
            dashBoardRouter.replace(routes[index]);
            // setState(() {
            //   activeIndex = index;
            // });
          },
          destinations: [
            // NavigationRailDestination(
            //   icon: Icon(Icons.account_tree_rounded),
            //   label: Text('Genres'),
            // ),
            NavigationRailDestination(
              icon: Icon(Icons.source),
              label: Text('Books'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.settings),
              label: Text('Settings'),
            ),
          ],
        ),
        Expanded(child: AutoRouter())
      ],
    );
  }
}
