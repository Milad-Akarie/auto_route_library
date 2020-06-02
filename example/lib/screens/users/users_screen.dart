import 'package:auto_route/auto_route.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:example/screens/users/users_router.dart';
import 'package:example/screens/users/users_router.gr.dart';
import 'package:flutter/material.dart';

class UsersScreen extends StatelessWidget {
  final String id;

  const UsersScreen({
    @pathParam this.id,
    int score,
    double limit = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // var route = ModalRoute.of(context);
    // var settings = route.settings as ExtendedRouteSettings;
    print(RouteData.of(context)?.pathParams?.input);

    return Scaffold(
      appBar: AppBar(
        title: Text("Users Details $id"),
      ),
      body: ExtendedNavigator<UsersRouter>(
        router: UsersRouter(),
        initialRoute: UserRoutes.profileScreen,
      ),
    );
  }
}
