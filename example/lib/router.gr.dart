// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:auto_route/auto_route.dart';
import 'package:example/screens/home_screen.dart';
import 'package:example/router.dart';
import 'package:example/screens/second_screen.dart';
import 'package:example/screens/login_screen.dart';

abstract class Routes {
  static const homeScreen = '/';
  static const secondScreen = '/second-screen';
  static const loginScreenDialog = '/login-screen-dialog';
}

class Router extends RouterBase {
  @override
  Map<String, List<Type>> get guardedRoutes => {
        Routes.homeScreen: [AuthGuard],
        Routes.secondScreen: [AuthGuard],
      };
  @override
  Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case Routes.homeScreen:
        return MaterialPageRoute<dynamic>(
          builder: (_) => HomeScreen(),
          settings: settings,
        );
      case Routes.secondScreen:
        if (hasInvalidArgs<SecondScreenArguments>(args, isRequired: true)) {
          return misTypedArgsRoute<SecondScreenArguments>(args);
        }
        final typedArgs = args as SecondScreenArguments;
        return PageRouteBuilder<dynamic>(
          pageBuilder: (ctx, animation, secondaryAnimation) =>
              SecondScreen(title: typedArgs.title, message: typedArgs.message)
                  .wrappedRoute,
          settings: settings,
          transitionsBuilder: TransitionsBuilders.fadeIn,
          transitionDuration: Duration(milliseconds: 300),
        );
      case Routes.loginScreenDialog:
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
  final String title;
  final String message;
  SecondScreenArguments({@required this.title, this.message});
}

extension RouterNavigationHelperMethods on ExtendedNavigatorState {
  Future<T> pushHomeScreen<T>() => pushNamed<T>(Routes.homeScreen);
  Future<T> pushSecondScreen<T>(
          {@required String title,
          String message,
          OnNavigationRejected onReject}) =>
      pushNamed<T>(Routes.secondScreen,
          arguments: SecondScreenArguments(title: title, message: message),
          onReject: onReject);
  Future<bool> pushLoginScreenDialog<bool>({
    double id = 20.0,
  }) =>
      pushNamed<bool>(Routes.loginScreenDialog, arguments: id);
}
