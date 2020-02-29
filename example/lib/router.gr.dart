// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/screens/second_screen.dart';
import 'package:example/router.dart';
import 'package:example/screens/profile_screen.dart';
import 'package:example/screens/login_screen.dart';

class Router {
  static const homeScreen = '/';
  static const secondScreen = '/second-screen';
  static const profileScreen = '/profile-screen';
  static const loginScreenDialog = '/login-screen-dialog';
  static const _guardedRoutes = {
    secondScreen: [AuthGuard],
    profileScreen: [AuthGuard],
  };
  static final navigator = ExtendedNavigator(_guardedRoutes);
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case Router.homeScreen:
        return MaterialPageRoute<dynamic>(
          builder: (_) => HomeScreen(),
          settings: settings,
        );
      case Router.secondScreen:
        if (hasInvalidArgs<SecondScreenArguments>(args)) {
          return misTypedArgsRoute<SecondScreenArguments>(args);
        }
        final typedArgs =
            args as SecondScreenArguments ?? SecondScreenArguments();
        return MaterialPageRoute<dynamic>(
          builder: (_) => SecondScreen(
                  title: typedArgs.title,
                  message: typedArgs.message,
                  func: typedArgs.func)
              .wrappedRoute,
          settings: settings,
        );
      case Router.profileScreen:
        if (hasInvalidArgs<ProfileScreenArguments>(args)) {
          return misTypedArgsRoute<ProfileScreenArguments>(args);
        }
        final typedArgs =
            args as ProfileScreenArguments ?? ProfileScreenArguments();
        return MaterialPageRoute<dynamic>(
          builder: (_) =>
              ProfileScreen(title: typedArgs.title, message: typedArgs.message),
          settings: settings,
        );
      case Router.loginScreenDialog:
        if (hasInvalidArgs<double>(args)) {
          return misTypedArgsRoute<double>(args);
        }
        final typedArgs = args as double ?? 20.0;
        return PageRouteBuilder<bool>(
          pageBuilder: (ctx, animation, secondaryAnimation) =>
              LoginScreen(id: typedArgs),
          settings: settings,
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
  final dynamic title;
  final String message;
  final Function func;
  SecondScreenArguments({this.title, this.message, this.func});
}

//ProfileScreen arguments holder class
class ProfileScreenArguments {
  final dynamic title;
  final String message;
  ProfileScreenArguments({this.title, this.message});
}
