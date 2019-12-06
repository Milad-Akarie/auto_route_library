import 'package:auto_route/auto_route_annotation.dart';
import 'package:flutter/material.dart';

@AutoRoute()
class SecondScreen extends StatelessWidget {
  final String title;
  final String message;
  const SecondScreen({this.title, this.message});
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
