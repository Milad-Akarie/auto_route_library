// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// RouteGenerator
// **************************************************************************

import 'package:flutter/material.dart';
import 'package:example/login.dart';
import 'package:example/home.dart';
import 'package:example/products_details.dart';

class Router {
  static const loginRoute = '/loginRoute';
  static const homePageRoute = '/homePageRoute';
  static const productDetailsRoute = '/productDetailsRoute';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case loginRoute:
        if (args is! int) throw ('Expected int found ${args.runtimeType}');
        return MaterialPageRoute(
            builder: (_) => Login(args as int), settings: settings);
        break;
      case homePageRoute:
        return MaterialPageRoute(
            builder: (_) => HomePage(), settings: settings);
        break;
      case productDetailsRoute:
        if (args is! ProductDetailsArguments)
          throw ('Expected ProductDetailsArguments found ${args.runtimeType}');
        final typedArgs = args as ProductDetailsArguments;
        return MaterialPageRoute(
            builder: (_) => ProductDetails(typedArgs.id, typedArgs.name),
            settings: settings);
        break;
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Container(
              color: Colors.redAccent,
              child: Center(
                child: Text('Route name ${settings.name} is not registered'),
              ),
            ),
          ),
        );
    }
  }
}

//----------------------------------------------
//ProductDetails arguments holder class
class ProductDetailsArguments {
  final int id;
  final int name;
  ProductDetailsArguments({this.id, this.name});
}
