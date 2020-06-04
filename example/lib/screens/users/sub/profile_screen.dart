import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String id;

  const ProfileScreen({title, this.id});

  @override
  Widget build(BuildContext context) {
    print('profileScreen: ${RouteData.of(context)}');
    print(ExtendedNavigator.of(context).runtimeType);
    return Column(
      children: <Widget>[
        FlatButton(
          child: Text("Users $id"),
          onPressed: () {},
        ),
      ],
    );
  }
}
