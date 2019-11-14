import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@AutoRoute(fullscreenDialog: false)
class Login extends StatelessWidget {
  final int id;

  const Login({this.id = 100});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(child: Text(id.toString())),
      ),
    );
  }
}
