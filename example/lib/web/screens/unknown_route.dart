import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class UnknownRoutePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ERROR 404'),
      ),
      body: Center(
        child: Text(
          'page not found ${context.route.match}',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
