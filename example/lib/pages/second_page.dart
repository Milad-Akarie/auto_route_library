import 'package:auto_route/auto_route_annotation.dart';
import 'package:flutter/material.dart';

@AutoRoute()
class SecondPage extends StatelessWidget {
  final String name;
  const SecondPage(this.name);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Center(child: Text(name.toString())),
      ),
    );
  }
}
