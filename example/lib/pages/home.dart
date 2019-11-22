import 'package:auto_route/auto_route_annotation.dart';
import 'package:flutter/material.dart';

import '../router.dart';

@AutoRoute(initial: true,fullscreenDialog: false)
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'You have pushed the button this many times:',
            ),
            Text("", style: Theme.of(context).textTheme.display1),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).pushNamed(Router.productDetailsRoute, arguments: 299);
        },
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
}
