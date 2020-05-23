import 'package:auto_route/auto_route.dart';
import 'package:example/samples/router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (ctx, __) => ExtendedNavigator<Router>(
        router: Router(),
      ),
    );
  }
}
