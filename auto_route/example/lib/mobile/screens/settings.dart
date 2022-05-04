import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.gr.dart';
import 'package:flutter/material.dart';

import 'home_page.dart';

class SettingsPage extends StatefulWidget {
  final String tab;
  final String query;

  SettingsPage({
    Key? key,
    @pathParam required this.tab,
    @queryParam this.query = 'none',
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with AutoRouteAwareStateMixin<SettingsPage> {
  var queryUpdateCont = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.tab),
            Text(widget.query),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    queryUpdateCont++;
                  });
                  context.navigateTo(SettingsTab(
                    tab: 'Updated Path param $queryUpdateCont',
                    query: 'updated Query $queryUpdateCont',
                  ));
                },
                child: Text('Update Query $queryUpdateCont'))
          ],
        ),
      ),
    );
  }

  @override
  void didInitTabRoute(TabPageRoute? previousRoute) {
    print('init tab route from ${previousRoute?.name}');
  }

  @override
  void didChangeTabRoute(TabPageRoute previousRoute) {
    print('did change tab route from ${previousRoute.name}');
  }
}


