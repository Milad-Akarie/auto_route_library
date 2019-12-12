import 'package:auto_route/auto_route_annotation.dart';
import 'package:flutter/material.dart';

const String nestedRoute = "nestedRouter";

@InitialRoute(navigatorName: nestedRoute)
class HomeNestedPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    print(Navigator.of(context).widget.key.toString());
    return Container(child: Center(child: Text("Home nested Page")));
  }
}
