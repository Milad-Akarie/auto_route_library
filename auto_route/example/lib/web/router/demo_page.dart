import 'package:auto_route/annotations.dart';
import 'package:example/mobile/router/auth_guard.dart';
import 'package:flutter/material.dart';

@AutoRoute(guards: [AuthGuard])
class DemoPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
