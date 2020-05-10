import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'nested_screens/nested_router.gr.dart';

class SecondScreen extends StatelessWidget implements AutoRouteWrapper {


  SecondScreen(String title);
  final tabViews = <Widget>[
    Icon(Icons.book),
    Icon(Icons.notifications),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ExtendedNavigator<NestedRouter>(
        router: NestedRouter(),
      ),
    );
  }

  @override
  Widget wrappedRoute(BuildContext context) {
    return this;
  }
}
