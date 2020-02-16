// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/second_screen.dart';
import 'package:example/screens/login_screen.dart';

import 'auto_router_base.dart';

class Router extends AutoRouterBase {
  static const homeScreenRoute = '/';
  static const secondScreenRoute = 'custom-name';
  static const loginScreenDialog = '/login-screen-dialog';

  Router._() : super();
  static final Router _instance = Router._();
  static Router get instance => _instance;

  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case Router.homeScreenRoute:
        return MaterialPageRoute(
          builder: (_) => HomeScreen().wrappedRoute,
          settings: settings,
        );
      case Router.secondScreenRoute:
        if (hasInvalidArgs<SecondScreenArguments>(args, isRequired: true)) {
          return misTypedArgsRoute<SecondScreenArguments>(args);
        }
        final typedArgs = args as SecondScreenArguments;
        return MaterialPageRoute(
          builder: (_) =>
              SecondScreen(title: typedArgs.title, message: typedArgs.message)
                  .wrappedRoute,
          settings: settings,
          fullscreenDialog: true,
          maintainState: true,
        );
      case Router.loginScreenDialog:
        if (hasInvalidArgs<double>(args)) {
          return misTypedArgsRoute<double>(args);
        }
        final typedArgs = args as double ?? 20.0;
        return PageRouteBuilder(
          pageBuilder: (ctx, animation, secondaryAnimation) =>
              LoginScreen(id: typedArgs),
          settings: settings,
          transitionsBuilder: TransitionsBuilders.fadeIn,
        );
      default:
        return unknownRoutePage(settings.name);
    }
  }
}

//**************************************************************************
// Arguments holder classes
//***************************************************************************

//SecondScreen arguments holder class
class SecondScreenArguments {
  final String title;
  final String message;
  SecondScreenArguments({@required this.title, this.message});
}
