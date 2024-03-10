// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i10;
import 'package:example/web_demo/screens/404/not_found_page.dart' as _i3;
import 'package:example/web_demo/screens/auth/login_page.dart' as _i1;
import 'package:example/web_demo/screens/auth/verify_page.dart' as _i9;
import 'package:example/web_demo/screens/main_page.dart' as _i2;
import 'package:example/web_demo/screens/users/posts/user_all_posts_page.dart'
    as _i4;
import 'package:example/web_demo/screens/users/posts/user_favourite_posts_page.dart'
    as _i5;
import 'package:example/web_demo/screens/users/posts/user_posts_page.dart'
    as _i7;
import 'package:example/web_demo/screens/users/user_page.dart' as _i6;
import 'package:example/web_demo/screens/users/user_profile_page.dart' as _i8;
import 'package:flutter/material.dart' as _i11;

abstract class $AppRouter extends _i10.RootStackRouter {
  $AppRouter({super.navigatorKey});

  @override
  final Map<String, _i10.PageFactory> pagesMap = {
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.LoginPage(
          key: args.key,
          onResult: args.onResult,
        ),
      );
    },
    MainWebRoute.name: (routeData) {
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const _i2.MainWebPage(),
      );
    },
    NotFoundRoute.name: (routeData) {
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i3.NotFoundScreen(),
      );
    },
    UserAllPostsRoute.name: (routeData) {
      final args = routeData.argsAs<UserAllPostsRouteArgs>(
          orElse: () => const UserAllPostsRouteArgs());
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i4.UserAllPostsPage(
          key: args.key,
          navigate: args.navigate,
        ),
      );
    },
    UserFavoritePostsRoute.name: (routeData) {
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i5.UserFavoritePostsPage(),
      );
    },
    UserRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final queryParams = routeData.queryParams;
      final args = routeData.argsAs<UserRouteArgs>(
          orElse: () => UserRouteArgs(
                id: pathParams.getInt(
                  'userID',
                  -1,
                ),
                query: queryParams.get('query'),
              ));
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i6.UserPage(
          key: args.key,
          id: args.id,
          query: args.query,
        ),
      );
    },
    UserPostsRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i7.UserPostsPage(id: pathParams.getInt('userID')),
      );
    },
    UserProfileRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final queryParams = routeData.queryParams;
      final args = routeData.argsAs<UserProfileRouteArgs>(
          orElse: () => UserProfileRouteArgs(
                userId: pathParams.getInt(
                  'userID',
                  -1,
                ),
                likes: queryParams.getInt(
                  'likes',
                  0,
                ),
              ));
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i8.UserProfilePage(
          key: args.key,
          navigate: args.navigate,
          userId: args.userId,
          likes: args.likes,
        ),
      );
    },
    VerifyRoute.name: (routeData) {
      final args = routeData.argsAs<VerifyRouteArgs>(
          orElse: () => const VerifyRouteArgs());
      return _i10.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i9.VerifyPage(
          key: args.key,
          onResult: args.onResult,
        ),
      );
    },
  };
}

/// generated route for
/// [_i1.LoginPage]
class LoginRoute extends _i10.PageRouteInfo<LoginRouteArgs> {
  LoginRoute({
    _i11.Key? key,
    void Function(bool)? onResult,
    List<_i10.PageRouteInfo>? children,
  }) : super(
          LoginRoute.name,
          args: LoginRouteArgs(
            key: key,
            onResult: onResult,
          ),
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static const _i10.PageInfo<LoginRouteArgs> page =
      _i10.PageInfo<LoginRouteArgs>(name);
}

class LoginRouteArgs {
  const LoginRouteArgs({
    this.key,
    this.onResult,
  });

  final _i11.Key? key;

  final void Function(bool)? onResult;

  @override
  String toString() {
    return 'LoginRouteArgs{key: $key, onResult: $onResult}';
  }
}

/// generated route for
/// [_i2.MainWebPage]
class MainWebRoute extends _i10.PageRouteInfo<void> {
  const MainWebRoute({List<_i10.PageRouteInfo>? children})
      : super(
          MainWebRoute.name,
          initialChildren: children,
        );

  static const String name = 'MainWebRoute';

  static const _i10.PageInfo<void> page = _i10.PageInfo<void>(name);
}

/// generated route for
/// [_i3.NotFoundScreen]
class NotFoundRoute extends _i10.PageRouteInfo<void> {
  const NotFoundRoute({List<_i10.PageRouteInfo>? children})
      : super(
          NotFoundRoute.name,
          initialChildren: children,
        );

  static const String name = 'NotFoundRoute';

  static const _i10.PageInfo<void> page = _i10.PageInfo<void>(name);
}

/// generated route for
/// [_i4.UserAllPostsPage]
class UserAllPostsRoute extends _i10.PageRouteInfo<UserAllPostsRouteArgs> {
  UserAllPostsRoute({
    _i11.Key? key,
    void Function()? navigate,
    List<_i10.PageRouteInfo>? children,
  }) : super(
          UserAllPostsRoute.name,
          args: UserAllPostsRouteArgs(
            key: key,
            navigate: navigate,
          ),
          initialChildren: children,
        );

  static const String name = 'UserAllPostsRoute';

  static const _i10.PageInfo<UserAllPostsRouteArgs> page =
      _i10.PageInfo<UserAllPostsRouteArgs>(name);
}

class UserAllPostsRouteArgs {
  const UserAllPostsRouteArgs({
    this.key,
    this.navigate,
  });

  final _i11.Key? key;

  final void Function()? navigate;

  @override
  String toString() {
    return 'UserAllPostsRouteArgs{key: $key, navigate: $navigate}';
  }
}

/// generated route for
/// [_i5.UserFavoritePostsPage]
class UserFavoritePostsRoute extends _i10.PageRouteInfo<void> {
  const UserFavoritePostsRoute({List<_i10.PageRouteInfo>? children})
      : super(
          UserFavoritePostsRoute.name,
          initialChildren: children,
        );

  static const String name = 'UserFavoritePostsRoute';

  static const _i10.PageInfo<void> page = _i10.PageInfo<void>(name);
}

/// generated route for
/// [_i6.UserPage]
class UserRoute extends _i10.PageRouteInfo<UserRouteArgs> {
  UserRoute({
    _i11.Key? key,
    int id = -1,
    List<String>? query,
    List<_i10.PageRouteInfo>? children,
  }) : super(
          UserRoute.name,
          args: UserRouteArgs(
            key: key,
            id: id,
            query: query,
          ),
          rawPathParams: {'userID': id},
          rawQueryParams: {'query': query},
          initialChildren: children,
        );

  static const String name = 'UserRoute';

  static const _i10.PageInfo<UserRouteArgs> page =
      _i10.PageInfo<UserRouteArgs>(name);
}

class UserRouteArgs {
  const UserRouteArgs({
    this.key,
    this.id = -1,
    this.query,
  });

  final _i11.Key? key;

  final int id;

  final List<String>? query;

  @override
  String toString() {
    return 'UserRouteArgs{key: $key, id: $id, query: $query}';
  }
}

/// generated route for
/// [_i7.UserPostsPage]
class UserPostsRoute extends _i10.PageRouteInfo<void> {
  UserPostsRoute({List<_i10.PageRouteInfo>? children})
      : super(
          UserPostsRoute.name,
          initialChildren: children,
        );

  static const String name = 'UserPostsRoute';

  static const _i10.PageInfo<void> page = _i10.PageInfo<void>(name);
}

/// generated route for
/// [_i8.UserProfilePage]
class UserProfileRoute extends _i10.PageRouteInfo<UserProfileRouteArgs> {
  UserProfileRoute({
    _i11.Key? key,
    void Function()? navigate,
    int userId = -1,
    int likes = 0,
    List<_i10.PageRouteInfo>? children,
  }) : super(
          UserProfileRoute.name,
          args: UserProfileRouteArgs(
            key: key,
            navigate: navigate,
            userId: userId,
            likes: likes,
          ),
          rawPathParams: {'userID': userId},
          rawQueryParams: {'likes': likes},
          initialChildren: children,
        );

  static const String name = 'UserProfileRoute';

  static const _i10.PageInfo<UserProfileRouteArgs> page =
      _i10.PageInfo<UserProfileRouteArgs>(name);
}

class UserProfileRouteArgs {
  const UserProfileRouteArgs({
    this.key,
    this.navigate,
    this.userId = -1,
    this.likes = 0,
  });

  final _i11.Key? key;

  final void Function()? navigate;

  final int userId;

  final int likes;

  @override
  String toString() {
    return 'UserProfileRouteArgs{key: $key, navigate: $navigate, userId: $userId, likes: $likes}';
  }
}

/// generated route for
/// [_i9.VerifyPage]
class VerifyRoute extends _i10.PageRouteInfo<VerifyRouteArgs> {
  VerifyRoute({
    _i11.Key? key,
    void Function(bool)? onResult,
    List<_i10.PageRouteInfo>? children,
  }) : super(
          VerifyRoute.name,
          args: VerifyRouteArgs(
            key: key,
            onResult: onResult,
          ),
          initialChildren: children,
        );

  static const String name = 'VerifyRoute';

  static const _i10.PageInfo<VerifyRouteArgs> page =
      _i10.PageInfo<VerifyRouteArgs>(name);
}

class VerifyRouteArgs {
  const VerifyRouteArgs({
    this.key,
    this.onResult,
  });

  final _i11.Key? key;

  final void Function(bool)? onResult;

  @override
  String toString() {
    return 'VerifyRouteArgs{key: $key, onResult: $onResult}';
  }
}
