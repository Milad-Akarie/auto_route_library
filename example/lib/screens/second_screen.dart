import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import 'nested_screens/nested_router.gr.dart';

class SecondScreen extends StatelessWidget {
  final String message;

  const SecondScreen({@required String title, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: ExtendedNavigator<NestedRouter>(
                router: NestedRouter(),
                initialRouteArgs: NestedScreenArguments(x: 2),
              ),
            )
          ],
        ),
      ),
    );
  }
}
