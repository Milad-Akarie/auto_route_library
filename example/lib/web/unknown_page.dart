import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';

class UnknownPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '404!',
              style: TextStyle(fontSize: 40),
            ),
            Text('Page ${context.route.match} not found!')
          ],
        ),
      ),
    );
  }
}
