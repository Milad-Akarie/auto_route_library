// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

import 'package:auto_route/auto_route.dart' as _i3;
import 'package:flutter/foundation.dart' as _i5;
import 'package:flutter/material.dart' as _i4;

import '../web_main.dart' as _i2;
import 'web_router.dart' as _i1;

class WebAppRouter extends _i3.RootStackRouter {
  WebAppRouter([_i4.GlobalKey<_i4.NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, _i3.PageFactory> pagesMap = {
    HomeRoute.name: (routeData) {
      final args =
          routeData.argsAs<HomeRouteArgs>(orElse: () => const HomeRouteArgs());
      return _i3.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i1.HomePage(
              key: args.key,
              navigate: args.navigate,
              showUserPosts: args.showUserPosts));
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i3.MaterialPageX<dynamic>(
          routeData: routeData,
          child:
              _i2.LoginPage(key: args.key, onLoginResult: args.onLoginResult));
    },
    UserRoute.name: (routeData) {
      final pathParams = routeData.pathParams;
      final args = routeData.argsAs<UserRouteArgs>(
          orElse: () => UserRouteArgs(id: pathParams.getInt('userID', -1)));
      return _i3.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i1.UserPage(key: args.key, id: args.id));
    },
    NotFoundRoute.name: (routeData) {
      return _i3.MaterialPageX<dynamic>(
          routeData: routeData, child: _i1.NotFoundScreen());
    },
    UserProfileRoute.name: (routeData) {
      final queryParams = routeData.queryParams;
      final args = routeData.argsAs<UserProfileRouteArgs>(
          orElse: () =>
              UserProfileRouteArgs(likes: queryParams.getInt('likes', 0)));
      return _i3.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i1.UserProfilePage(
              key: args.key, navigate: args.navigate, likes: args.likes));
    },
    UserPostsRoute.name: (routeData) {
      return _i3.MaterialPageX<dynamic>(
          routeData: routeData, child: _i1.UserPostsPage());
    },
    UserAllPostsRoute.name: (routeData) {
      final args = routeData.argsAs<UserAllPostsRouteArgs>(
          orElse: () => const UserAllPostsRouteArgs());
      return _i3.MaterialPageX<dynamic>(
          routeData: routeData,
          child: _i1.UserAllPostsPage(key: args.key, navigate: args.navigate));
    },
    UserFavoritePostsRoute.name: (routeData) {
      return _i3.MaterialPageX<dynamic>(
          routeData: routeData, child: _i1.UserFavoritePostsPage());
    }
  };

  @override
  List<_i3.RouteConfig> get routes => [
        _i3.RouteConfig(HomeRoute.name, path: '/'),
        _i3.RouteConfig(LoginRoute.name, path: '/login'),
        _i3.RouteConfig(UserRoute.name, path: '/user/:userID', children: [
          _i3.RouteConfig('#redirect',
              path: '', redirectTo: 'profile', fullMatch: true),
          _i3.RouteConfig(UserProfileRoute.name, path: 'profile'),
          _i3.RouteConfig(UserPostsRoute.name, path: 'posts', children: [
            _i3.RouteConfig('#redirect',
                path: '', redirectTo: 'all', fullMatch: true),
            _i3.RouteConfig(UserAllPostsRoute.name, path: 'all'),
            _i3.RouteConfig(UserFavoritePostsRoute.name, path: 'favorite')
          ])
        ]),
        _i3.RouteConfig(NotFoundRoute.name, path: '*')
      ];
}

/// generated route for [_i1.HomePage]
class HomeRoute extends _i3.PageRouteInfo<HomeRouteArgs> {
  HomeRoute(
      {_i5.Key? key, void Function()? navigate, void Function()? showUserPosts})
      : super(name,
            path: '/',
            args: HomeRouteArgs(
                key: key, navigate: navigate, showUserPosts: showUserPosts));

  static const String name = 'HomeRoute';
}

class HomeRouteArgs {
  const HomeRouteArgs({this.key, this.navigate, this.showUserPosts});

  final _i5.Key? key;

  final void Function()? navigate;

  final void Function()? showUserPosts;
}

/// generated route for [_i2.LoginPage]
class LoginRoute extends _i3.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({_i5.Key? key, void Function(bool)? onLoginResult})
      : super(name,
            path: '/login',
            args: LoginRouteArgs(key: key, onLoginResult: onLoginResult));

  static const String name = 'LoginRoute';
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.onLoginResult});

  final _i5.Key? key;

  final void Function(bool)? onLoginResult;
}

/// generated route for [_i1.UserPage]
class UserRoute extends _i3.PageRouteInfo<UserRouteArgs> {
  UserRoute({_i5.Key? key, int id = -1, List<_i3.PageRouteInfo>? children})
      : super(name,
            path: '/user/:userID',
            args: UserRouteArgs(key: key, id: id),
            rawPathParams: {'userID': id},
            initialChildren: children);

  static const String name = 'UserRoute';
}

class UserRouteArgs {
  const UserRouteArgs({this.key, this.id = -1});

  final _i5.Key? key;

  final int id;
}

/// generated route for [_i1.NotFoundScreen]
class NotFoundRoute extends _i3.PageRouteInfo<void> {
  const NotFoundRoute() : super(name, path: '*');

  static const String name = 'NotFoundRoute';
}

/// generated route for [_i1.UserProfilePage]
class UserProfileRoute extends _i3.PageRouteInfo<UserProfileRouteArgs> {
  UserProfileRoute({_i5.Key? key, void Function()? navigate, int likes = 0})
      : super(name,
            path: 'profile',
            args: UserProfileRouteArgs(
                key: key, navigate: navigate, likes: likes),
            rawQueryParams: {'likes': likes});

  static const String name = 'UserProfileRoute';
}

class UserProfileRouteArgs {
  const UserProfileRouteArgs({this.key, this.navigate, this.likes = 0});

  final _i5.Key? key;

  final void Function()? navigate;

  final int likes;
}

/// generated route for [_i1.UserPostsPage]
class UserPostsRoute extends _i3.PageRouteInfo<void> {
  const UserPostsRoute({List<_i3.PageRouteInfo>? children})
      : super(name, path: 'posts', initialChildren: children);

  static const String name = 'UserPostsRoute';
}

/// generated route for [_i1.UserAllPostsPage]
class UserAllPostsRoute extends _i3.PageRouteInfo<UserAllPostsRouteArgs> {
  UserAllPostsRoute({_i5.Key? key, void Function()? navigate})
      : super(name,
            path: 'all',
            args: UserAllPostsRouteArgs(key: key, navigate: navigate));

  static const String name = 'UserAllPostsRoute';
}

class UserAllPostsRouteArgs {
  const UserAllPostsRouteArgs({this.key, this.navigate});

  final _i5.Key? key;

  final void Function()? navigate;
}

/// generated route for [_i1.UserFavoritePostsPage]
class UserFavoritePostsRoute extends _i3.PageRouteInfo<void> {
  const UserFavoritePostsRoute() : super(name, path: 'favorite');

  static const String name = 'UserFavoritePostsRoute';
}
