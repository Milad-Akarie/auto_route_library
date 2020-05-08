import 'package:flutter/material.dart';

class UnknownRouteScreen extends StatelessWidget {
  final String routeName;

  const UnknownRouteScreen(this.routeName);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text('can not navigate to $routeName'),
      ),
    );
  }
}
