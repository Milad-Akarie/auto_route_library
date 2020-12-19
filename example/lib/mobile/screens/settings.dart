import 'package:auto_route/auto_route.dart';
import 'package:example/mobile/router/router.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Settings'),
          const SizedBox(height: 24),
          RaisedButton(
              child: Text('Navigate to Book/4'),
              onPressed: () {
                context.tabsRouter
                  ..setActiveIndex(0)
                  ..innerRouterOf<StackRouter>(BooksTab.name).push(BookDetailsRoute(id: 4));
              })
        ],
      ),
    );
  }
}
