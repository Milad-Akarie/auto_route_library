import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';

class SettingsPage extends StatelessWidget {
  final String tab;
  final String query;
  SettingsPage({
    Key? key,
    @pathParam required this.tab,
    @queryParam this.query = 'none',
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tab),
            Text(query),
          ],
        ),
      ),
    );
  }
}

class Settings2Page extends StatefulWidget {
  final String tab;

  Settings2Page({Key? key, @pathParam required this.tab}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<Settings2Page> with AutoRouteAware {
  var _count = 0;

  @override
  void didInitTabRoute(TabPageRoute? previousRoute) {}

  @override
  void didPush() {
    print('did push settings tab');
  }

  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {
    print('Changed to settings tab from ${previousRoute.name}');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final observer =
        RouterScope.of(context).firstObserverOfType<AutoRouteObserver>();
    if (observer != null) {
      observer.subscribe(this, context.routeData);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Settings/${widget.tab} $_count'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context.navigateTo(
                ProfileTab(children: [
                  MyBooksRoute(),
                ]),
              );
            },
            child: Text('navigateNamed to profile/my-books'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              context
                  .findRootAncestorStateOfType<HomePageState>()
                  ?.toggleSettingsTap();
            },
            child: Text('Toggle Settings Tab'),
          ),
        ],
      ),
    );
  }
}
