// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_route/router_utils.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/second_screen.dart';
import 'package:example/screens/login_screen.dart';
import 'package:auto_route/transitions_builders.dart';

class Router {
  static const homeScreenRoute = '/';
  static const secondScreenRoute = '/secondScreenRoute';
  static const loginScreenDialog = '/loginScreenDialog';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case Router.homeScreenRoute:
        return MaterialPageRoute(
          builder: (_) => HomeScreen().wrappedRoute,
          settings: settings,
          fullscreenDialog: true,
          maintainState: true,
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
        );
      case Router.loginScreenDialog:
        if (hasInvalidArgs<double>(args)) {
          return misTypedArgsRoute<double>(args);
        }
        final typedArgs = args as double ?? 20.0;
        return PageRouteBuilder(
          pageBuilder: (ctx, animation, secondaryAnimation) =>
              LoginScreen(id: typedArgs).wrappedRoute,
          settings: settings,
          opaque: true,
          barrierDismissible: true,
          transitionsBuilder: TransitionsBuilders.fadeIn,
          transitionDuration: Duration(milliseconds: 100),
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
