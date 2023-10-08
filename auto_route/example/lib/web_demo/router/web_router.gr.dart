// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i4;
import 'package:example/web_demo/router/web_login_page.dart' as _i2;
import 'package:example/web_demo/router/web_router.dart' as _i1;
import 'package:example/web_demo/router/web_verify_page.dart' as _i3;
import 'package:flutter/foundation.dart' as _i5;
import 'package:flutter/material.dart' as _i6;

abstract class $WebAppRouter extends _i4.RootStackRouter {
  $WebAppRouter({super.navigatorKey});

  @override
  final Map<String, _i4.PageFactory> pagesMap = {
    MainWebRoute.name: (routeData) {
      final args = routeData.argsAs<MainWebRouteArgs>(
          orElse: () => const MainWebRouteArgs());
      return _i4.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.MainWebPage(
          key: args.key,
          navigate: args.navigate,
          showUserPosts: args.showUserPosts,
        ),
      );
    },
    NotFoundRoute.name: (routeData) {
      return _i4.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.NotFoundScreen(),
      );
    },
    UserAllPostsRoute.name: (routeData) {
      final args = routeData.argsAs<UserAllPostsRouteArgs>(
          orElse: () => const UserAllPostsRouteArgs());
      return _i4.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.UserAllPostsPage(
          key: args.key,
          navigate: args.navigate,
        ),
      );
    },
    UserFavoritePostsRoute.name: (routeData) {
      return _i4.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.UserFavoritePostsPage(),
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
      return _i4.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.UserPage(
          key: args.key,
          id: args.id,
          query: args.query,
        ),
      );
    },
    UserPostsRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      return _i4.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.UserPostsPage(id: pathParams.getInt('userID')),
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
      return _i4.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.UserProfilePage(
          key: args.key,
          navigate: args.navigate,
          userId: args.userId,
          likes: args.likes,
        ),
      );
    },
    WebLoginRoute.name: (routeData) {
      final args = routeData.argsAs<WebLoginRouteArgs>(
          orElse: () => const WebLoginRouteArgs());
      return _i4.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i2.WebLoginPage(
          key: args.key,
          onResult: args.onResult,
        ),
      );
    },
    WebVerifyRoute.name: (routeData) {
      final args = routeData.argsAs<WebVerifyRouteArgs>(
          orElse: () => const WebVerifyRouteArgs());
      return _i4.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i3.WebVerifyPage(
          key: args.key,
          onResult: args.onResult,
        ),
      );
    },
  };
}

/// generated route for
/// [_i1.MainWebPage]
class MainWebRoute extends _i4.PageRouteInfo<MainWebRouteArgs> {
  MainWebRoute({
    _i5.Key? key,
    void Function()? navigate,
    void Function()? showUserPosts,
    List<_i4.PageRouteInfo>? children,
  }) : super(
          MainWebRoute.name,
          args: MainWebRouteArgs(
            key: key,
            navigate: navigate,
            showUserPosts: showUserPosts,
          ),
          initialChildren: children,
        );

  static const String name = 'MainWebRoute';

  static const _i4.PageInfo<MainWebRouteArgs> page =
      _i4.PageInfo<MainWebRouteArgs>(name);
}

class MainWebRouteArgs {
  const MainWebRouteArgs({
    this.key,
    this.navigate,
    this.showUserPosts,
  });

  final _i5.Key? key;

  final void Function()? navigate;

  final void Function()? showUserPosts;

  @override
  String toString() {
    return 'MainWebRouteArgs{key: $key, navigate: $navigate, showUserPosts: $showUserPosts}';
  }
}

/// generated route for
/// [_i1.NotFoundScreen]
class NotFoundRoute extends _i4.PageRouteInfo<void> {
  const NotFoundRoute({List<_i4.PageRouteInfo>? children})
      : super(
          NotFoundRoute.name,
          initialChildren: children,
        );

  static const String name = 'NotFoundRoute';

  static const _i4.PageInfo<void> page = _i4.PageInfo<void>(name);
}

/// generated route for
/// [_i1.UserAllPostsPage]
class UserAllPostsRoute extends _i4.PageRouteInfo<UserAllPostsRouteArgs> {
  UserAllPostsRoute({
    _i5.Key? key,
    void Function()? navigate,
    List<_i4.PageRouteInfo>? children,
  }) : super(
          UserAllPostsRoute.name,
          args: UserAllPostsRouteArgs(
            key: key,
            navigate: navigate,
          ),
          initialChildren: children,
        );

  static const String name = 'UserAllPostsRoute';

  static const _i4.PageInfo<UserAllPostsRouteArgs> page =
      _i4.PageInfo<UserAllPostsRouteArgs>(name);
}

class UserAllPostsRouteArgs {
  const UserAllPostsRouteArgs({
    this.key,
    this.navigate,
  });

  final _i5.Key? key;

  final void Function()? navigate;

  @override
  String toString() {
    return 'UserAllPostsRouteArgs{key: $key, navigate: $navigate}';
  }
}

/// generated route for
/// [_i1.UserFavoritePostsPage]
class UserFavoritePostsRoute extends _i4.PageRouteInfo<void> {
  const UserFavoritePostsRoute({List<_i4.PageRouteInfo>? children})
      : super(
          UserFavoritePostsRoute.name,
          initialChildren: children,
        );

  static const String name = 'UserFavoritePostsRoute';

  static const _i4.PageInfo<void> page = _i4.PageInfo<void>(name);
}

/// generated route for
/// [_i1.UserPage]
class UserRoute extends _i4.PageRouteInfo<UserRouteArgs> {
  UserRoute({
    _i5.Key? key,
    int id = -1,
    List<String>? query,
    List<_i4.PageRouteInfo>? children,
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

  static const _i4.PageInfo<UserRouteArgs> page =
      _i4.PageInfo<UserRouteArgs>(name);
}

class UserRouteArgs {
  const UserRouteArgs({
    this.key,
    this.id = -1,
    this.query,
  });

  final _i5.Key? key;

  final int id;

  final List<String>? query;

  @override
  String toString() {
    return 'UserRouteArgs{key: $key, id: $id, query: $query}';
  }
}

/// generated route for
/// [_i1.UserPostsPage]
class UserPostsRoute extends _i4.PageRouteInfo<void> {
  UserPostsRoute({List<_i4.PageRouteInfo>? children})
      : super(
          UserPostsRoute.name,
          initialChildren: children,
        );

  static const String name = 'UserPostsRoute';

  static const _i4.PageInfo<void> page = _i4.PageInfo<void>(name);
}

/// generated route for
/// [_i1.UserProfilePage]
class UserProfileRoute extends _i4.PageRouteInfo<UserProfileRouteArgs> {
  UserProfileRoute({
    _i5.Key? key,
    void Function()? navigate,
    int userId = -1,
    int likes = 0,
    List<_i4.PageRouteInfo>? children,
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

  static const _i4.PageInfo<UserProfileRouteArgs> page =
      _i4.PageInfo<UserProfileRouteArgs>(name);
}

class UserProfileRouteArgs {
  const UserProfileRouteArgs({
    this.key,
    this.navigate,
    this.userId = -1,
    this.likes = 0,
  });

  final _i5.Key? key;

  final void Function()? navigate;

  final int userId;

  final int likes;

  @override
  String toString() {
    return 'UserProfileRouteArgs{key: $key, navigate: $navigate, userId: $userId, likes: $likes}';
  }
}

/// generated route for
/// [_i2.WebLoginPage]
class WebLoginRoute extends _i4.PageRouteInfo<WebLoginRouteArgs> {
  WebLoginRoute({
    _i6.Key? key,
    void Function(bool)? onResult,
    List<_i4.PageRouteInfo>? children,
  }) : super(
          WebLoginRoute.name,
          args: WebLoginRouteArgs(
            key: key,
            onResult: onResult,
          ),
          initialChildren: children,
        );

  static const String name = 'WebLoginRoute';

  static const _i4.PageInfo<WebLoginRouteArgs> page =
      _i4.PageInfo<WebLoginRouteArgs>(name);
}

class WebLoginRouteArgs {
  const WebLoginRouteArgs({
    this.key,
    this.onResult,
  });

  final _i6.Key? key;

  final void Function(bool)? onResult;

  @override
  String toString() {
    return 'WebLoginRouteArgs{key: $key, onResult: $onResult}';
  }
}

/// generated route for
/// [_i3.WebVerifyPage]
class WebVerifyRoute extends _i4.PageRouteInfo<WebVerifyRouteArgs> {
  WebVerifyRoute({
    _i6.Key? key,
    void Function(bool)? onResult,
    List<_i4.PageRouteInfo>? children,
  }) : super(
          WebVerifyRoute.name,
          args: WebVerifyRouteArgs(
            key: key,
            onResult: onResult,
          ),
          initialChildren: children,
        );

  static const String name = 'WebVerifyRoute';

  static const _i4.PageInfo<WebVerifyRouteArgs> page =
      _i4.PageInfo<WebVerifyRouteArgs>(name);
}

class WebVerifyRouteArgs {
  const WebVerifyRouteArgs({
    this.key,
    this.onResult,
  });

  final _i6.Key? key;

  final void Function(bool)? onResult;

  @override
  String toString() {
    return 'WebVerifyRouteArgs{key: $key, onResult: $onResult}';
  }
}
