import 'package:auto_route/auto_route_annotation.dart';
import 'package:flutter/material.dart';

@AutoRoute(initial: true)
class LoginScreen extends StatelessWidget {
  final int id;
  final String userName;
  LoginScreen({this.id = 100, this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      appBar: AppBar(),
      body: Container(
        child: Center(child: Text(id.toString())),
      ),
    );
  }
}
