import 'package:auto_route/route_gen_annotation.dart';
import 'package:flutter/material.dart';

@AutoRoute()
class Login extends StatelessWidget {
  final int id;

  const Login(this.id);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(child: Text(id.toString())),
    );
  }
}
