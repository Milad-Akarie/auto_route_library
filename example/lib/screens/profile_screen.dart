import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final String message;

  const ProfileScreen({title, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: <Widget>[
          FlatButton(
            child: Text("ProfileScreen Screen"),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
