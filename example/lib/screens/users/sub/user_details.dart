import 'package:auto_route/auto_route.dart';
import 'package:example/screens/users/users_router.gr.dart';
import 'package:flutter/material.dart';

class UserDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FlatButton(
          child: Text("User Profile"),
          onPressed: () {
            ExtendedNavigator.of(context).pushNamed(UserRoutes.profileScreen);
          },
        ),
      ],
    );
  }
}
