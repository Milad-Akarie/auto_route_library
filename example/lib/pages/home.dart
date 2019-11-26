import 'package:auto_route/auto_route_annotation.dart';
import 'package:flutter/material.dart';

import '../router.dart';

@initialRoute
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
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
