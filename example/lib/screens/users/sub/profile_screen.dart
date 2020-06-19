import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String id;

  const ProfileScreen({this.id});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile Screen"),),
      body: Column(
        children: <Widget>[
          FlatButton(
            child: Text("Users $id"),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
