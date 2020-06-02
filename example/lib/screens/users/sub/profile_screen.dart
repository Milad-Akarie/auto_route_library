import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String id;

  const ProfileScreen({title, this.id});

  @override
  Widget build(BuildContext context) {
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
