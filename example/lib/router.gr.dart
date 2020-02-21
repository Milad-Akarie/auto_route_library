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
import 'package:example/screens/third_screen.dart';
import 'package:example/screens/login_screen.dart';

class Router {
  static const homeScreen = '/';
  static const secondScreen = '/second-screen';
  static const profileScreen = '/profile-screen';
  static const loginScreenDialog = '/login-screen-dialog';
  static const routes = [
    homeScreen,
    secondScreen,
    profileScreen,
    loginScreenDialog,
  ];
  static const _guardedRoutes = const {
    secondScreen: [AuthGuard],
    profileScreen: [AuthGuard],
  };
  static final navigator = ExtendedNavigator(_guardedRoutes);
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case Router.homeScreen:
        return PageRouteBuilder<dynamic>(
          pageBuilder: (ctx, animation, secondaryAnimation) => HomeScreen(),
          settings: settings,
        );
      case Router.secondScreen:
        if (hasInvalidArgs<SecondScreenArguments>(args)) {
          return misTypedArgsRoute<SecondScreenArguments>(args);
        }
        final typedArgs =
            args as SecondScreenArguments ?? SecondScreenArguments();
        return PageRouteBuilder<dynamic>(
          pageBuilder: (ctx, animation, secondaryAnimation) =>
              SecondScreen(title: typedArgs.title, message: typedArgs.message)
                  .wrappedRoute,
          settings: settings,
          opaque: true,
          barrierDismissible: true,
          transitionsBuilder: TransitionsBuilders.slideLeft,
          transitionDuration: Duration(milliseconds: 300),
        );
      case Router.profileScreen:
        if (hasInvalidArgs<ProfileScreenArguments>(args)) {
          return misTypedArgsRoute<ProfileScreenArguments>(args);
        }
        final typedArgs =
            args as ProfileScreenArguments ?? ProfileScreenArguments();
        return PageRouteBuilder<dynamic>(
          pageBuilder: (ctx, animation, secondaryAnimation) =>
              ProfileScreen(title: typedArgs.title, message: typedArgs.message),
          settings: settings,
          opaque: true,
          barrierDismissible: true,
          transitionsBuilder: TransitionsBuilders.slideLeft,
          transitionDuration: Duration(milliseconds: 300),
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
  SecondScreenArguments({this.title, this.message});
}

//ProfileScreen arguments holder class
class ProfileScreenArguments {
  final dynamic title;
  final String message;
  ProfileScreenArguments({this.title, this.message});
}
