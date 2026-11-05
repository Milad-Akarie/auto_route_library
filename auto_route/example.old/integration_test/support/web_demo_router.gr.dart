// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'web_demo_router.dart';

/// generated route for
/// [MainWebPage]
class MainWebRoute extends PageRouteInfo<void> {
  const MainWebRoute({List<PageRouteInfo>? children})
    : super(MainWebRoute.name, initialChildren: children);

  static const String name = 'MainWebRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const MainWebPage();
    },
  );
}

/// generated route for
/// [NotFoundScreen]
class NotFoundRoute extends PageRouteInfo<void> {
  const NotFoundRoute({List<PageRouteInfo>? children})
    : super(NotFoundRoute.name, initialChildren: children);

  static const String name = 'NotFoundRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const NotFoundScreen();
    },
  );
}

/// generated route for
/// [UserAllPostsPage]
class UserAllPostsRoute extends PageRouteInfo<void> {
  const UserAllPostsRoute({List<PageRouteInfo>? children})
    : super(UserAllPostsRoute.name, initialChildren: children);

  static const String name = 'UserAllPostsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const UserAllPostsPage();
    },
  );
}

/// generated route for
/// [UserFavoritePostsPage]
class UserFavoritePostsRoute extends PageRouteInfo<void> {
  const UserFavoritePostsRoute({List<PageRouteInfo>? children})
    : super(UserFavoritePostsRoute.name, initialChildren: children);

  static const String name = 'UserFavoritePostsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const UserFavoritePostsPage();
    },
  );
}

/// generated route for
/// [UserPage]
class UserRoute extends PageRouteInfo<UserRouteArgs> {
  UserRoute({
    Key? key,
    int id = -1,
    List<String>? query,
    String? fragment,
    List<PageRouteInfo>? children,
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

  static PageInfo page = PageInfo(
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
      return UserPage(
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

  final Key? key;

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
        const ListEquality<String>().equals(query, other.query) &&
        fragment == other.fragment;
  }

  @override
  int get hashCode =>
      key.hashCode ^
      id.hashCode ^
      const ListEquality<String>().hash(query) ^
      fragment.hashCode;
}

/// generated route for
/// [UserPostsPage]
class UserPostsRoute extends PageRouteInfo<UserPostsRouteArgs> {
  UserPostsRoute({Key? key, List<PageRouteInfo>? children})
    : super(
        UserPostsRoute.name,
        args: UserPostsRouteArgs(key: key),
        initialChildren: children,
      );

  static const String name = 'UserPostsRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      final pathParams = data.inheritedPathParams;
      final args = data.argsAs<UserPostsRouteArgs>(
        orElse: () => UserPostsRouteArgs(),
      );
      return UserPostsPage(id: pathParams.getInt('userID'), key: args.key);
    },
  );
}

class UserPostsRouteArgs {
  const UserPostsRouteArgs({this.key});

  final Key? key;

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
/// [UserProfilePage]
class UserProfileRoute extends PageRouteInfo<UserProfileRouteArgs> {
  UserProfileRoute({
    Key? key,
    int userId = -1,
    int likes = 0,
    List<PageRouteInfo>? children,
  }) : super(
         UserProfileRoute.name,
         args: UserProfileRouteArgs(key: key, userId: userId, likes: likes),
         rawPathParams: {'userID': userId},
         rawQueryParams: {'likes': likes},
         initialChildren: children,
       );

  static const String name = 'UserProfileRoute';

  static PageInfo page = PageInfo(
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
      return UserProfilePage(
        key: args.key,
        userId: args.userId,
        likes: args.likes,
      );
    },
  );
}

class UserProfileRouteArgs {
  const UserProfileRouteArgs({this.key, this.userId = -1, this.likes = 0});

  final Key? key;

  final int userId;

  final int likes;

  @override
  String toString() {
    return 'UserProfileRouteArgs{key: $key, userId: $userId, likes: $likes}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! UserProfileRouteArgs) return false;
    return key == other.key && userId == other.userId && likes == other.likes;
  }

  @override
  int get hashCode => key.hashCode ^ userId.hashCode ^ likes.hashCode;
}

/// generated route for
/// [WebLoginPage]
class WebLoginRoute extends PageRouteInfo<void> {
  const WebLoginRoute({List<PageRouteInfo>? children})
    : super(WebLoginRoute.name, initialChildren: children);

  static const String name = 'WebLoginRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const WebLoginPage();
    },
  );
}

/// generated route for
/// [WebVerifyPage]
class WebVerifyRoute extends PageRouteInfo<void> {
  const WebVerifyRoute({List<PageRouteInfo>? children})
    : super(WebVerifyRoute.name, initialChildren: children);

  static const String name = 'WebVerifyRoute';

  static PageInfo page = PageInfo(
    name,
    builder: (data) {
      return const WebVerifyPage();
    },
  );
}
