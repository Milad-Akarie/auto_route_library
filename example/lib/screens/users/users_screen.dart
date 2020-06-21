import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/material.dart';

class UsersScreen extends StatelessWidget {
  final String id;
  final int score;

  const UsersScreen({
    this.id,
    this.score,
    double limit = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // var route = ModalRoute.of(context);
    // var settings = route.settings as ExtendedRouteSettings;
    print(RouteData.of(context));

    return Scaffold(
      appBar: AppBar(
        title: Text("Users Details $id score:$score"),
      ),
//      body: FlatButton(
//          child: Text("push deep link"),
//          onPressed: () async {
//            ExtendedNavigator.of(context).pushNamed(Routes.usersScreen);
//          }),
        body: NestedNavigator()
    );
  }
}
