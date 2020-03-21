import 'package:auto_route/auto_route.dart';
import 'package:example/router.dart';
import 'package:example/router.gr.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class AuthGuard extends RouteGuard {
  @override
  Future<bool> canNavigate(ExtendedNavigatorState navigator, String routeName,
      Object arguments) async {
    return true;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: ExtendedNavigator<Router>(
        router: Router(),
        guards: [AuthGuard()],
      ),
    );
  }
}
