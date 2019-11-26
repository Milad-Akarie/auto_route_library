import 'package:auto_route/auto_route_annotation.dart';
import 'package:flutter/material.dart';

@AutoRoute(fullscreenDialog: true)
class ThirdPage extends StatelessWidget {
  final String name;
  final int id;

  ThirdPage({Key key, this.name, this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
