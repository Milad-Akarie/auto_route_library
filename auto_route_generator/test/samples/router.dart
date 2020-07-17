//@ShouldGenerate(output)
//@ShouldThrow('Class name must be prefixed with \$')
//@MaterialAutoRouter()
//class Router {
//  @initial
//  HomeScreen homeScreen;
//}
//
//class HomeScreen{}

const output = '''
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';
import 'package:__test__/router_base.dart';

abstract class Routes {
  static const homeScreen = '/';
}

class Router extends RouterBase {
  @override
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.homeScreen:
        return PageRouteBuilder<dynamic>(
          pageBuilder: (context, animation, secondaryAnimation) => HomeScreen(),
          settings: settings,
        );
      default:
        return unknownRoutePage(settings.name);
    }
  }
}
''';
