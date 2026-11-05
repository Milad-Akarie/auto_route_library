// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:auto_route/auto_route.dart' as _i10;
import 'package:collection/collection.dart' as _i13;
import 'package:example/web_demo/router/not_found_screen.dart' as _i2;
import 'package:example/web_demo/router/user_all_posts_page.dart' as _i3;
import 'package:example/web_demo/router/user_favorite_posts_page.dart' as _i4;
import 'package:example/web_demo/router/user_page.dart' as _i5;
import 'package:example/web_demo/router/user_posts_page.dart' as _i6;
import 'package:example/web_demo/router/user_profile_page.dart' as _i7;
import 'package:example/web_demo/router/web_app_router.dart' as _i1;
import 'package:example/web_demo/router/web_login_page.dart' as _i8;
import 'package:example/web_demo/router/web_verify_page.dart' as _i9;
import 'package:flutter/foundation.dart' as _i11;
import 'package:material_ui/material_ui.dart' as _i12;

/// generated route for
/// [_i1.MainWebPage]
class MainWebRoute extends _i10.PageRouteInfo<MainWebRouteArgs> {
  MainWebRoute({
    _i11.Key? key,
    _i11.VoidCallback? onNavigate,
    _i11.VoidCallback? onShowUserPosts,
    List<_i10.PageRouteInfo>? children,
  }) : super(
         MainWebRoute.name,
         args: MainWebRouteArgs(
           key: key,
           onNavigate: onNavigate,
           onShowUserPosts: onShowUserPosts,
         ),
         initialChildren: children,
       );

  static const String name = 'MainWebRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<MainWebRouteArgs>(
        orElse: () => const MainWebRouteArgs(),
      );
      return _i1.MainWebPage(
        key: args.key,
        onNavigate: args.onNavigate,
        onShowUserPosts: args.onShowUserPosts,
      );
    },
  );
}

class MainWebRouteArgs {
  const MainWebRouteArgs({this.key, this.onNavigate, this.onShowUserPosts});

  final _i11.Key? key;

  final _i11.VoidCallback? onNavigate;

  final _i11.VoidCallback? onShowUserPosts;

  @override
  String toString() {
    return 'MainWebRouteArgs{key: $key, onNavigate: $onNavigate, onShowUserPosts: $onShowUserPosts}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MainWebRouteArgs) return false;
    return key == other.key &&
        onNavigate == other.onNavigate &&
        onShowUserPosts == other.onShowUserPosts;
  }

  @override
  int get hashCode =>
      key.hashCode ^ onNavigate.hashCode ^ onShowUserPosts.hashCode;
}

/// generated route for
/// [_i2.NotFoundScreen]
class NotFoundRoute extends _i10.PageRouteInfo<void> {
  const NotFoundRoute({List<_i10.PageRouteInfo>? children})
    : super(NotFoundRoute.name, initialChildren: children);

  static const String name = 'NotFoundRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i2.NotFoundScreen();
    },
  );
}

/// generated route for
/// [_i3.UserAllPostsPage]
class UserAllPostsRoute extends _i10.PageRouteInfo<UserAllPostsRouteArgs> {
  UserAllPostsRoute({
    _i12.Key? key,
    _i12.VoidCallback? onNavigate,
    List<_i10.PageRouteInfo>? children,
  }) : super(
         UserAllPostsRoute.name,
         args: UserAllPostsRouteArgs(key: key, onNavigate: onNavigate),
         initialChildren: children,
       );

  static const String name = 'UserAllPostsRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<UserAllPostsRouteArgs>(
        orElse: () => const UserAllPostsRouteArgs(),
      );
      return _i3.UserAllPostsPage(key: args.key, onNavigate: args.onNavigate);
    },
  );
}

class UserAllPostsRouteArgs {
  const UserAllPostsRouteArgs({this.key, this.onNavigate});

  final _i12.Key? key;

  final _i12.VoidCallback? onNavigate;

  @override
  String toString() {
    return 'UserAllPostsRouteArgs{key: $key, onNavigate: $onNavigate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserAllPostsRouteArgs) return false;
    return key == other.key && onNavigate == other.onNavigate;
  }

  @override
  int get hashCode => key.hashCode ^ onNavigate.hashCode;
}

/// generated route for
/// [_i4.UserFavoritePostsPage]
class UserFavoritePostsRoute extends _i10.PageRouteInfo<void> {
  const UserFavoritePostsRoute({List<_i10.PageRouteInfo>? children})
    : super(UserFavoritePostsRoute.name, initialChildren: children);

  static const String name = 'UserFavoritePostsRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      return const _i4.UserFavoritePostsPage();
    },
  );
}

/// generated route for
/// [_i5.UserPage]
class UserRoute extends _i10.PageRouteInfo<UserRouteArgs> {
  UserRoute({
    _i12.Key? key,
    int id = -1,
    List<String>? query,
    String? fragment,
    List<_i10.PageRouteInfo>? children,
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

  static _i10.PageInfo page = _i10.PageInfo(
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
      return _i5.UserPage(
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

  final _i12.Key? key;

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
        const _i13.ListEquality<String>().equals(query, other.query) &&
        fragment == other.fragment;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      id.hashCode ^
      const _i13.ListEquality<String>().hash(query) ^
      fragment.hashCode;
}

/// generated route for
/// [_i6.UserPostsPage]
class UserPostsRoute extends _i10.PageRouteInfo<UserPostsRouteArgs> {
  UserPostsRoute({_i12.Key? key, List<_i10.PageRouteInfo>? children})
    : super(
        UserPostsRoute.name,
        args: UserPostsRouteArgs(key: key),
        initialChildren: children,
      );

  static const String name = 'UserPostsRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<UserPostsRouteArgs>(
        orElse: () => UserPostsRouteArgs(),
      );
      return _i6.UserPostsPage(id: pathParams.getInt('userID'), key: args.key);
    },
  );
}

class UserPostsRouteArgs {
  const UserPostsRouteArgs({this.key});

  final _i12.Key? key;

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
/// [_i7.UserProfilePage]
class UserProfileRoute extends _i10.PageRouteInfo<UserProfileRouteArgs> {
  UserProfileRoute({
    _i12.Key? key,
    _i12.VoidCallback? onNavigate,
    int userId = -1,
    int likes = 0,
    List<_i10.PageRouteInfo>? children,
  }) : super(
         UserProfileRoute.name,
         args: UserProfileRouteArgs(
           key: key,
           onNavigate: onNavigate,
           userId: userId,
           likes: likes,
         ),
         rawPathParams: {'userID': userId},
         rawQueryParams: {'likes': likes},
         initialChildren: children,
       );

  static const String name = 'UserProfileRoute';

  static _i10.PageInfo page = _i10.PageInfo(
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
      return _i7.UserProfilePage(
        key: args.key,
        onNavigate: args.onNavigate,
        userId: args.userId,
        likes: args.likes,
      );
    },
  );
}

class UserProfileRouteArgs {
  const UserProfileRouteArgs({
    this.key,
    this.onNavigate,
    this.userId = -1,
    this.likes = 0,
  });

  final _i12.Key? key;

  final _i12.VoidCallback? onNavigate;

  final int userId;

  final int likes;

  @override
  String toString() {
    return 'UserProfileRouteArgs{key: $key, onNavigate: $onNavigate, userId: $userId, likes: $likes}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserProfileRouteArgs) return false;
    return key == other.key &&
        onNavigate == other.onNavigate &&
        userId == other.userId &&
        likes == other.likes;
  }

  @override
  int get hashCode =>
      key.hashCode ^ onNavigate.hashCode ^ userId.hashCode ^ likes.hashCode;
}

/// generated route for
/// [_i8.WebLoginPage]
class WebLoginRoute extends _i10.PageRouteInfo<WebLoginRouteArgs> {
  WebLoginRoute({
    _i12.Key? key,
    _i12.ValueChanged<bool>? onResult,
    List<_i10.PageRouteInfo>? children,
  }) : super(
         WebLoginRoute.name,
         args: WebLoginRouteArgs(key: key, onResult: onResult),
         initialChildren: children,
       );

  static const String name = 'WebLoginRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WebLoginRouteArgs>(
        orElse: () => const WebLoginRouteArgs(),
      );
      return _i8.WebLoginPage(key: args.key, onResult: args.onResult);
    },
  );
}

class WebLoginRouteArgs {
  const WebLoginRouteArgs({this.key, this.onResult});

  final _i12.Key? key;

  final _i12.ValueChanged<bool>? onResult;

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
/// [_i9.WebVerifyPage]
class WebVerifyRoute extends _i10.PageRouteInfo<WebVerifyRouteArgs> {
  WebVerifyRoute({
    _i12.Key? key,
    _i12.ValueChanged<bool>? onResult,
    List<_i10.PageRouteInfo>? children,
  }) : super(
         WebVerifyRoute.name,
         args: WebVerifyRouteArgs(key: key, onResult: onResult),
         initialChildren: children,
       );

  static const String name = 'WebVerifyRoute';

  static _i10.PageInfo page = _i10.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<WebVerifyRouteArgs>(
        orElse: () => const WebVerifyRouteArgs(),
      );
      return _i9.WebVerifyPage(key: args.key, onResult: args.onResult);
    },
  );
}

class WebVerifyRouteArgs {
  const WebVerifyRouteArgs({this.key, this.onResult});

  final _i12.Key? key;

  final _i12.ValueChanged<bool>? onResult;

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
