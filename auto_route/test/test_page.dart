import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class TestPage extends StatelessWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(context.routeData.name);
  }
}

class FirstPage extends TestPage {}

class SecondPage extends TestPage {}

class ThirdPage extends TestPage {}
