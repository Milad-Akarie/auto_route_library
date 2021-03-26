// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i1;
import 'package:flutter/material.dart' as _i3;

import 'web_router.dart' as _i2;

class WebAppRouter extends _i1.RootStackRouter {
  WebAppRouter();

  @override
  final Map<String, _i1.PageFactory> pagesMap = {
    HomeRoute.name: (entry) {
      return _i1.MaterialPageX(entry: entry, child: _i2.HomePage());
    },
    UserRoute.name: (entry) {
      var pathParams = entry.routeData.pathParams;
      var args = entry.routeData.argsAs<UserRouteArgs>(
          orElse: () => UserRouteArgs(id: pathParams.getInt('userID', -1)));
      return _i1.MaterialPageX(
          entry: entry, child: _i2.UserPage(key: args.key, id: args.id));
    },
    UserProfileRoute.name: (entry) {
      return _i1.MaterialPageX(entry: entry, child: _i2.UserProfilePage());
    },
    UserPostsRoute.name: (entry) {
      return _i1.MaterialPageX(entry: entry, child: _i2.UserPostsPage());
    }
  };

  @override
  List<_i1.RouteConfig> get routes => [
        _i1.RouteConfig(HomeRoute.name, path: '/'),
        _i1.RouteConfig(UserRoute.name, path: '/user/:userID', children: [
          _i1.RouteConfig('#redirect',
              path: '', redirectTo: 'profile', fullMatch: true),
          _i1.RouteConfig(UserProfileRoute.name, path: 'profile'),
          _i1.RouteConfig(UserPostsRoute.name, path: 'posts')
        ])
      ];
}

class HomeRoute extends _i1.PageRouteInfo {
  const HomeRoute() : super(name, path: '/');

  static const String name = 'HomeRoute';
}

class UserRoute extends _i1.PageRouteInfo<UserRouteArgs> {
  UserRoute({_i3.Key? key, int id = -1, List<_i1.PageRouteInfo>? children})
      : super(name,
            path: '/user/:userID',
            args: UserRouteArgs(key: key, id: id),
            params: {'userID': id},
            initialChildren: children);

  static const String name = 'UserRoute';
}

class UserRouteArgs {
  const UserRouteArgs({this.key, this.id = -1});

  final _i3.Key? key;

  final int id;
}

class UserProfileRoute extends _i1.PageRouteInfo {
  const UserProfileRoute() : super(name, path: 'profile');

  static const String name = 'UserProfileRoute';
}

class UserPostsRoute extends _i1.PageRouteInfo {
  const UserPostsRoute() : super(name, path: 'posts');

  static const String name = 'UserPostsRoute';
}
