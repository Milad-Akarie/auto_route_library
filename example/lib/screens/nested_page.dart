import 'package:auto_route/auto_route_annotation.dart';
import 'package:example/screens/home_nested_page.dart';
import 'package:flutter/material.dart';

class NestedRoute extends AutoRoute {
  const NestedRoute() : super(navigatorName: nestedRoute);
}

@NestedRoute()
class NestedPage extends StatelessWidget {
  final String name;
  final int id;

  const NestedPage({this.name, this.id});

  @override
  Widget build(BuildContext context) {
    return Container(child: Center(child: Text("Nested Page")));
  }
}
