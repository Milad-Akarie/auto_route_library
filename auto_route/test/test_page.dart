import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

class TestPage extends StatelessWidget {
  const TestPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(context.routeData.name);
  }
}


class NotFoundPage extends TestPage {
  const NotFoundPage({Key? key}) : super(key: key);
}

class FirstPage extends TestPage {
  const FirstPage({Key? key}) : super(key: key);
}

class SecondPage extends TestPage {
  const SecondPage({Key? key}) : super(key: key);
}

class ThirdPage extends TestPage {
  const ThirdPage({Key? key}) : super(key: key);
}
