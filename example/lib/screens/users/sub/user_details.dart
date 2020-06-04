import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.dart';
import 'package:example/screens/users/users_router.dart';
import 'package:flutter/material.dart';

import '../users_router.gr.dart';

class UserDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        FlatButton(
          child: Text("User Profile"),
          onPressed: () {

            ExtendedNavigator.ofRouter<UsersRouter>()
                .pushNamed(UserRoutes.profileScreen);
          },
        ),
      ],
    );
  }
}
