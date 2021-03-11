// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i1;
import 'package:flutter/material.dart' as _i5;

import '../screens/home_page.dart' as _i2;
import '../screens/login_page.dart' as _i4;
import '../screens/user-data/data_collector.dart' as _i3;

class AppRouter extends _i1.RootStackRouter {
  AppRouter();

  @override
  final Map<String, _i1.PageFactory> pagesMap = {
    HomeRoute.name: (entry) {
      return _i1.MaterialPageX(
          entry: entry,
          child: _i2.HomePage(),
          maintainState: true,
          fullscreenDialog: false);
    },
    UserDataCollectorRoute.name: (entry) {
      var route = entry.routeData.as<UserDataCollectorRoute>();
      return _i1.MaterialPageX(
          entry: entry,
          child: _i3.UserDataCollectorPage(
              key: route.key, onResult: route.onResult, id: route.id),
          maintainState: true,
          fullscreenDialog: false);
    },
    LoginRoute.name: (entry) {
      var route = entry.routeData.as<LoginRoute>();
      return _i1.MaterialPageX(
          entry: entry,
          child: _i4.LoginPage(
              key: route.key,
              onLoginResult: route.onLoginResult,
              showBackButton: route.showBackButton ?? true),
          maintainState: true,
          fullscreenDialog: false);
    }
  };

  @override
  List<_i1.RouteConfig> get routes => [
        _i1.RouteConfig<HomeRoute>(HomeRoute.name,
            path: '/',
            fullMatch: false,
            usesTabsRouter: true,
            routeBuilder: (match) => HomeRoute.fromMatch(match)),
        _i1.RouteConfig<UserDataCollectorRoute>(UserDataCollectorRoute.name,
            path: '/user-data/:id',
            fullMatch: false,
            usesTabsRouter: false,
            routeBuilder: (match) => UserDataCollectorRoute.fromMatch(match)),
        _i1.RouteConfig<LoginRoute>(LoginRoute.name,
            path: '/login',
            fullMatch: false,
            usesTabsRouter: false,
            routeBuilder: (match) => LoginRoute.fromMatch(match)),
        _i1.RouteConfig('*#redirect',
            path: '*', redirectTo: '/', fullMatch: true)
      ];
}

class HomeRoute extends _i1.PageRouteInfo {
  HomeRoute() : super(name, path: '/');

  HomeRoute.fromMatch(_i1.RouteMatch match) : super.fromMatch(match);

  static const String name = 'HomeRoute';
}

class UserDataCollectorRoute extends _i1.PageRouteInfo {
  const UserDataCollectorRoute({this.key, this.onResult, required this.id})
      : super(name, path: '/user-data/:id');

  UserDataCollectorRoute.fromMatch(_i1.RouteMatch match)
      : key = null,
        onResult = null,
        id = match.pathParams.getInt('id'),
        super.fromMatch(match);

  final _i5.Key? key;

  final dynamic Function(_i3.UserData)? onResult;

  final int id;

  static const String name = 'UserDataCollectorRoute';
}

class LoginRoute extends _i1.PageRouteInfo {
  const LoginRoute({this.key, this.onLoginResult, this.showBackButton = true})
      : super(name, path: '/login');

  LoginRoute.fromMatch(_i1.RouteMatch match)
      : key = null,
        onLoginResult = null,
        showBackButton = true,
        super.fromMatch(match);

  final _i5.Key? key;

  final void Function(bool)? onLoginResult;

  final bool showBackButton;

  static const String name = 'LoginRoute';
}
