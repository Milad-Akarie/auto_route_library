// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:auto_route/auto_route.dart' as _i4;
import 'package:collection/collection.dart' as _i6;
import 'package:example/web_demo/router/web_login_page.dart' as _i2;
import 'package:example/web_demo/router/web_router.dart' as _i1;
import 'package:example/web_demo/router/web_verify_page.dart' as _i3;
import 'package:flutter/foundation.dart' as _i5;
import 'package:flutter/material.dart' as _i7;

/// generated route for
/// [_i1.MainWebPage]
class MainWebRoute extends _i4.PageRouteInfo<MainWebRouteArgs> {
  MainWebRoute({
    _i5.Key? key,
    _i5.VoidCallback? navigate,
    _i5.VoidCallback? showUserPosts,
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

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MainWebRouteArgs>(
        orElse: () => const MainWebRouteArgs(),
      );
      return _i1.MainWebPage(
        key: args.key,
        navigate: args.navigate,
        showUserPosts: args.showUserPosts,
      );
    },
  );
}

class MainWebRouteArgs {
  const MainWebRouteArgs({this.key, this.navigate, this.showUserPosts});

  final _i5.Key? key;

  final _i5.VoidCallback? navigate;

  final _i5.VoidCallback? showUserPosts;

  @override
  String toString() {
    return 'MainWebRouteArgs{key: $key, navigate: $navigate, showUserPosts: $showUserPosts}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MainWebRouteArgs) return false;
    return key == other.key &&
        navigate == other.navigate &&
        showUserPosts == other.showUserPosts;
  }

  @override
  int get hashCode => key.hashCode ^ navigate.hashCode ^ showUserPosts.hashCode;
}

/// generated route for
/// [_i1.NotFoundScreen]
class NotFoundRoute extends _i4.PageRouteInfo<void> {
  const NotFoundRoute({List<_i4.PageRouteInfo>? children})
      : super(NotFoundRoute.name, initialChildren: children);

  static const String name = 'NotFoundRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      return const _i1.NotFoundScreen();
    },
  );
}

/// generated route for
/// [_i1.UserAllPostsPage]
class UserAllPostsRoute extends _i4.PageRouteInfo<UserAllPostsRouteArgs> {
  UserAllPostsRoute({
    _i5.Key? key,
    _i5.VoidCallback? navigate,
    List<_i4.PageRouteInfo>? children,
  }) : super(
          UserAllPostsRoute.name,
          args: UserAllPostsRouteArgs(key: key, navigate: navigate),
          initialChildren: children,
        );

  static const String name = 'UserAllPostsRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UserAllPostsRouteArgs>(
        orElse: () => const UserAllPostsRouteArgs(),
      );
      return _i1.UserAllPostsPage(key: args.key, navigate: args.navigate);
    },
  );
}

class UserAllPostsRouteArgs {
  const UserAllPostsRouteArgs({this.key, this.navigate});

  final _i5.Key? key;

  final _i5.VoidCallback? navigate;

  @override
  String toString() {
    return 'UserAllPostsRouteArgs{key: $key, navigate: $navigate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserAllPostsRouteArgs) return false;
    return key == other.key && navigate == other.navigate;
  }

  @override
  int get hashCode => key.hashCode ^ navigate.hashCode;
}

/// generated route for
/// [_i1.UserFavoritePostsPage]
class UserFavoritePostsRoute extends _i4.PageRouteInfo<void> {
  const UserFavoritePostsRoute({List<_i4.PageRouteInfo>? children})
      : super(UserFavoritePostsRoute.name, initialChildren: children);

  static const String name = 'UserFavoritePostsRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      return const _i1.UserFavoritePostsPage();
    },
  );
}

/// generated route for
/// [_i1.UserPage]
class UserRoute extends _i4.PageRouteInfo<UserRouteArgs> {
  UserRoute({
    _i5.Key? key,
    int id = -1,
    List<String>? query,
    String? fragment,
    List<_i4.PageRouteInfo>? children,
  }) : super(
          UserRoute.name,
          args: UserRouteArgs(
            key: key,
            id: id,
            query: query,
            fragment: fragment,
          ),
          rawPathParams: {'userID': id},
          rawQueryParams: {'query': query},
          fragment: fragment,
          initialChildren: children,
        );

  static const String name = 'UserRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<UserRouteArgs>(
        orElse: () => UserRouteArgs(
          id: pathParams.getInt('userID', -1),
          query: queryParams.optList('query'),
          fragment: data.fragment,
        ),
      );
      return _i1.UserPage(
        key: args.key,
        id: args.id,
        query: args.query,
        fragment: args.fragment,
      );
    },
  );
}

class UserRouteArgs {
  const UserRouteArgs({this.key, this.id = -1, this.query, this.fragment});

  final _i5.Key? key;

  final int id;

  final List<String>? query;

  final String? fragment;

  @override
  String toString() {
    return 'UserRouteArgs{key: $key, id: $id, query: $query, fragment: $fragment}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserRouteArgs) return false;
    return key == other.key &&
        id == other.id &&
        const _i6.ListEquality().equals(query, other.query) &&
        fragment == other.fragment;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      id.hashCode ^
      const _i6.ListEquality().hash(query) ^
      fragment.hashCode;
}

/// generated route for
/// [_i1.UserPostsPage]
class UserPostsRoute extends _i4.PageRouteInfo<UserPostsRouteArgs> {
  UserPostsRoute({_i5.Key? key, List<_i4.PageRouteInfo>? children})
      : super(
          UserPostsRoute.name,
          args: UserPostsRouteArgs(key: key),
          initialChildren: children,
        );

  static const String name = 'UserPostsRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<UserPostsRouteArgs>(
        orElse: () => UserPostsRouteArgs(),
      );
      return _i1.UserPostsPage(key: args.key, id: pathParams.getInt('userID'));
    },
  );
}

class UserPostsRouteArgs {
  const UserPostsRouteArgs({this.key});

  final _i5.Key? key;

  @override
  String toString() {
    return 'UserPostsRouteArgs{key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserPostsRouteArgs) return false;
    return key == other.key;
  }

  @override
  int get hashCode => key.hashCode;
}

/// generated route for
/// [_i1.UserProfilePage]
class UserProfileRoute extends _i4.PageRouteInfo<UserProfileRouteArgs> {
  UserProfileRoute({
    _i5.Key? key,
    _i5.VoidCallback? navigate,
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

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final queryParams = data.queryParams;
      final args = data.argsAs<UserProfileRouteArgs>(
        orElse: () => UserProfileRouteArgs(
          userId: pathParams.getInt('userID', -1),
          likes: queryParams.getInt('likes', 0),
        ),
      );
      return _i1.UserProfilePage(
        key: args.key,
        navigate: args.navigate,
        userId: args.userId,
        likes: args.likes,
      );
    },
  );
}

class UserProfileRouteArgs {
  const UserProfileRouteArgs({
    this.key,
    this.navigate,
    this.userId = -1,
    this.likes = 0,
  });

  final _i5.Key? key;

  final _i5.VoidCallback? navigate;

  final int userId;

  final int likes;

  @override
  String toString() {
    return 'UserProfileRouteArgs{key: $key, navigate: $navigate, userId: $userId, likes: $likes}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserProfileRouteArgs) return false;
    return key == other.key &&
        navigate == other.navigate &&
        userId == other.userId &&
        likes == other.likes;
  }

  @override
  int get hashCode =>
      key.hashCode ^ navigate.hashCode ^ userId.hashCode ^ likes.hashCode;
}

/// generated route for
/// [_i2.WebLoginPage]
class WebLoginRoute extends _i4.PageRouteInfo<WebLoginRouteArgs> {
  WebLoginRoute({
    _i7.Key? key,
    _i7.ValueChanged<bool>? onResult,
    List<_i4.PageRouteInfo>? children,
  }) : super(
          WebLoginRoute.name,
          args: WebLoginRouteArgs(key: key, onResult: onResult),
          initialChildren: children,
        );

  static const String name = 'WebLoginRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WebLoginRouteArgs>(
        orElse: () => const WebLoginRouteArgs(),
      );
      return _i2.WebLoginPage(key: args.key, onResult: args.onResult);
    },
  );
}

class WebLoginRouteArgs {
  const WebLoginRouteArgs({this.key, this.onResult});

  final _i7.Key? key;

  final _i7.ValueChanged<bool>? onResult;

  @override
  String toString() {
    return 'WebLoginRouteArgs{key: $key, onResult: $onResult}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WebLoginRouteArgs) return false;
    return key == other.key && onResult == other.onResult;
  }

  @override
  int get hashCode => key.hashCode ^ onResult.hashCode;
}

/// generated route for
/// [_i3.WebVerifyPage]
class WebVerifyRoute extends _i4.PageRouteInfo<WebVerifyRouteArgs> {
  WebVerifyRoute({
    _i7.Key? key,
    _i7.ValueChanged<bool>? onResult,
    List<_i4.PageRouteInfo>? children,
  }) : super(
          WebVerifyRoute.name,
          args: WebVerifyRouteArgs(key: key, onResult: onResult),
          initialChildren: children,
        );

  static const String name = 'WebVerifyRoute';

  static _i4.PageInfo page = _i4.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WebVerifyRouteArgs>(
        orElse: () => const WebVerifyRouteArgs(),
      );
      return _i3.WebVerifyPage(key: args.key, onResult: args.onResult);
    },
  );
}

class WebVerifyRouteArgs {
  const WebVerifyRouteArgs({this.key, this.onResult});

  final _i7.Key? key;

  final _i7.ValueChanged<bool>? onResult;

  @override
  String toString() {
    return 'WebVerifyRouteArgs{key: $key, onResult: $onResult}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WebVerifyRouteArgs) return false;
    return key == other.key && onResult == other.onResult;
  }

  @override
  int get hashCode => key.hashCode ^ onResult.hashCode;
}
