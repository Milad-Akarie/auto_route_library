// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i3;
import 'package:example/web_demo/router/web_login_page.dart' as _i1;
import 'package:example/web_demo/router/web_router.dart' as _i2;
import 'package:flutter/foundation.dart' as _i5;
import 'package:flutter/material.dart' as _i4;

abstract class $WebAppRouter extends _i3.RootStackRouter {
  $WebAppRouter({super.navigatorKey});

  @override
  final Map<String, _i3.PageFactory> pagesMap = {
    WebLoginRoute.name: (routeData) {
      final args = routeData.argsAs<WebLoginRouteArgs>(
          orElse: () => const WebLoginRouteArgs());
      return _i3.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i1.WebLoginPage(
          key: args.key,
          resolver: args.resolver,
          showBackButton: args.showBackButton,
        ),
      );
    },
    MainWebRoute.name: (routeData) {
      final args = routeData.argsAs<MainWebRouteArgs>(
          orElse: () => const MainWebRouteArgs());
      return _i3.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i2.MainWebPage(
          key: args.key,
          navigate: args.navigate,
          showUserPosts: args.showUserPosts,
        ),
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
      return _i3.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i2.UserProfilePage(
          key: args.key,
          navigate: args.navigate,
          userId: args.userId,
          likes: args.likes,
        ),
      );
    },
    UserPostsRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      return _i3.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i2.UserPostsPage(id: pathParams.getInt('userID')),
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
      return _i3.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i2.UserPage(
          key: args.key,
          id: args.id,
          query: args.query,
        ),
      );
    },
    NotFoundRoute.name: (routeData) {
      return _i3.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i2.NotFoundScreen(),
      );
    },
    UserAllPostsRoute.name: (routeData) {
      final args = routeData.argsAs<UserAllPostsRouteArgs>(
          orElse: () => const UserAllPostsRouteArgs());
      return _i3.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i2.UserAllPostsPage(
          key: args.key,
          navigate: args.navigate,
        ),
      );
    },
    UserFavoritePostsRoute.name: (routeData) {
      return _i3.AutoRoutePage<dynamic>(
        routeData: routeData,
        child: _i2.UserFavoritePostsPage(),
      );
    },
  };
}

/// generated route for
/// [_i1.WebLoginPage]
class WebLoginRoute extends _i3.PageRouteInfo<WebLoginRouteArgs> {
  WebLoginRoute({
    _i4.Key? key,
    _i3.NavigationResolver? resolver,
    bool showBackButton = true,
    List<_i3.PageRouteInfo>? children,
  }) : super(
          WebLoginRoute.name,
          args: WebLoginRouteArgs(
            key: key,
            resolver: resolver,
            showBackButton: showBackButton,
          ),
          initialChildren: children,
        );

  static const String name = 'WebLoginRoute';

  static const _i3.PageInfo<WebLoginRouteArgs> page =
      _i3.PageInfo<WebLoginRouteArgs>(name);
}

class WebLoginRouteArgs {
  const WebLoginRouteArgs({
    this.key,
    this.resolver,
    this.showBackButton = true,
  });

  final _i4.Key? key;

  final _i3.NavigationResolver? resolver;

  final bool showBackButton;

  @override
  String toString() {
    return 'WebLoginRouteArgs{key: $key, resolver: $resolver, showBackButton: $showBackButton}';
  }
}

/// generated route for
/// [_i2.MainWebPage]
class MainWebRoute extends _i3.PageRouteInfo<MainWebRouteArgs> {
  MainWebRoute({
    _i5.Key? key,
    dynamic navigate,
    dynamic showUserPosts,
    List<_i3.PageRouteInfo>? children,
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

  static const _i3.PageInfo<MainWebRouteArgs> page =
      _i3.PageInfo<MainWebRouteArgs>(name);
}

class MainWebRouteArgs {
  const MainWebRouteArgs({
    this.key,
    this.navigate,
    this.showUserPosts,
  });

  final _i5.Key? key;

  final dynamic navigate;

  final dynamic showUserPosts;

  @override
  String toString() {
    return 'MainWebRouteArgs{key: $key, navigate: $navigate, showUserPosts: $showUserPosts}';
  }
}

/// generated route for
/// [_i2.UserProfilePage]
class UserProfileRoute extends _i3.PageRouteInfo<UserProfileRouteArgs> {
  UserProfileRoute({
    _i5.Key? key,
    dynamic navigate,
    int userId = -1,
    int likes = 0,
    List<_i3.PageRouteInfo>? children,
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

  static const _i3.PageInfo<UserProfileRouteArgs> page =
      _i3.PageInfo<UserProfileRouteArgs>(name);
}

class UserProfileRouteArgs {
  const UserProfileRouteArgs({
    this.key,
    this.navigate,
    this.userId = -1,
    this.likes = 0,
  });

  final _i5.Key? key;

  final dynamic navigate;

  final int userId;

  final int likes;

  @override
  String toString() {
    return 'UserProfileRouteArgs{key: $key, navigate: $navigate, userId: $userId, likes: $likes}';
  }
}

/// generated route for
/// [_i2.UserPostsPage]
class UserPostsRoute extends _i3.PageRouteInfo<void> {
  UserPostsRoute({List<_i3.PageRouteInfo>? children})
      : super(
          UserPostsRoute.name,
          initialChildren: children,
        );

  static const String name = 'UserPostsRoute';

  static const _i3.PageInfo<void> page = _i3.PageInfo<void>(name);
}

/// generated route for
/// [_i2.UserPage]
class UserRoute extends _i3.PageRouteInfo<UserRouteArgs> {
  UserRoute({
    _i5.Key? key,
    int id = -1,
    List<String>? query,
    List<_i3.PageRouteInfo>? children,
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

  static const _i3.PageInfo<UserRouteArgs> page =
      _i3.PageInfo<UserRouteArgs>(name);
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
/// [_i2.NotFoundScreen]
class NotFoundRoute extends _i3.PageRouteInfo<void> {
  const NotFoundRoute({List<_i3.PageRouteInfo>? children})
      : super(
          NotFoundRoute.name,
          initialChildren: children,
        );

  static const String name = 'NotFoundRoute';

  static const _i3.PageInfo<void> page = _i3.PageInfo<void>(name);
}

/// generated route for
/// [_i2.UserAllPostsPage]
class UserAllPostsRoute extends _i3.PageRouteInfo<UserAllPostsRouteArgs> {
  UserAllPostsRoute({
    _i5.Key? key,
    dynamic navigate,
    List<_i3.PageRouteInfo>? children,
  }) : super(
          UserAllPostsRoute.name,
          args: UserAllPostsRouteArgs(
            key: key,
            navigate: navigate,
          ),
          initialChildren: children,
        );

  static const String name = 'UserAllPostsRoute';

  static const _i3.PageInfo<UserAllPostsRouteArgs> page =
      _i3.PageInfo<UserAllPostsRouteArgs>(name);
}

class UserAllPostsRouteArgs {
  const UserAllPostsRouteArgs({
    this.key,
    this.navigate,
  });

  final _i5.Key? key;

  final dynamic navigate;

  @override
  String toString() {
    return 'UserAllPostsRouteArgs{key: $key, navigate: $navigate}';
  }
}

/// generated route for
/// [_i2.UserFavoritePostsPage]
class UserFavoritePostsRoute extends _i3.PageRouteInfo<void> {
  const UserFavoritePostsRoute({List<_i3.PageRouteInfo>? children})
      : super(
          UserFavoritePostsRoute.name,
          initialChildren: children,
        );

  static const String name = 'UserFavoritePostsRoute';

  static const _i3.PageInfo<void> page = _i3.PageInfo<void>(name);
}
