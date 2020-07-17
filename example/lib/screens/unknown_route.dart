import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class UnknownRouteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: Colors.grey,
      body: Center(
        child: Text(
          'ERROR 404 \npage not found ${RouteData.of(context).name}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
