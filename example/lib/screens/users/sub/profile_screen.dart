import 'package:auto_route/auto_route.dart';
import 'package:example/router/router.gr.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile Screen"),
      ),
      body: Column(
        children: <Widget>[
          FlatButton(
            child: Text("User posts"),
            onPressed: () {
              ExtendedNavigator.of(context).pushNamed(UsersScreenRoutes.postsScreen);
              // or without Context
              // ExtendedNavigator.byName("usersRouter").pushNamed(UsersScreenRoutes.postsScreen);
            },
          ),
        ],
      ),
    );
  }
}
