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

  //This will probably be removed in future versions
  //you should call ExtendedNavigator.ofRouter<Router>() directly
  static ExtendedNavigatorState get navigator =>
      ExtendedNavigator.ofRouter<Router>();

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
        return MaterialPageRoute<dynamic>(
          builder: (_) =>
              SecondScreen(title: typedArgs.title, message: typedArgs.message)
                  .wrappedRoute,
          settings: settings,
        );
      case Routes.loginScreenDialog:
        if (hasInvalidArgs<double>(args)) {
          return misTypedArgsRoute<double>(args);
        }
        final typedArgs = args as double ?? 20.0;
        return PageRouteBuilder<dynamic>(
          pageBuilder: (ctx, animation, secondaryAnimation) =>
              LoginScreen(id: typedArgs),
          settings: settings,
          fullscreenDialog: true,
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

//**************************************************************************
// Navigation helper methods extension
//***************************************************************************

extension RouterNavigationHelperMethods on ExtendedNavigatorState {
  Future pushHomeScreen() => pushNamed(Routes.homeScreen);
  Future pushSecondScreen(
          {@required String title,
          String message,
          OnNavigationRejected onReject}) =>
      pushNamed(Routes.secondScreen,
          arguments: SecondScreenArguments(title: title, message: message),
          onReject: onReject);
  Future pushLoginScreenDialog({
    double id = 20.0,
  }) =>
      pushNamed(Routes.loginScreenDialog, arguments: id);
}
