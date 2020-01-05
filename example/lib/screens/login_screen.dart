import 'package:auto_route/auto_route_wrapper.dart';
import 'package:example/screens/nested/nested_router.gr.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../router.dart';

class LoginScreen extends StatelessWidget implements AutoRouteWrapper {
  final double id;

  const LoginScreen({this.id = 20.0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Navigator(
              key: NestedRouter.navigatorKey,
              onGenerateRoute: NestedRouter.onGenerateRoute,
            ),
          ),
          FlatButton(
            child: Text("NestedScreen Screen"),
            onPressed: () {
              NestedRouter.navigator.pushNamed(NestedRouter.nestedPage);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget get wrappedRoute => Provider(child: this, create: (_) => Model(),);
}
