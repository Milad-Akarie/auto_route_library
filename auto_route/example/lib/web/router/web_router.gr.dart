// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************
//
// ignore_for_file: type=lint

part of 'web_router.dart';

class _$WebAppRouter extends RootStackRouter {
  _$WebAppRouter([GlobalKey<NavigatorState>? navigatorKey])
      : super(navigatorKey);

  @override
  final Map<String, PageFactory> pagesMap = {
    HomeRoute.name: (routeData) {
      final args =
          routeData.argsAs<HomeRouteArgs>(orElse: () => const HomeRouteArgs());
      return CustomPage<dynamic>(
          routeData: routeData,
          child: HomePage(
              key: args.key,
              navigate: args.navigate,
              showUserPosts: args.showUserPosts),
          reverseDurationInMilliseconds: 0,
          opaque: true,
          barrierDismissible: false);
    },
    LoginRoute.name: (routeData) {
      return CustomPage<dynamic>(
          routeData: routeData,
          child: const LoginPage(),
          transitionsBuilder: TransitionsBuilders.noTransition,
          opaque: true,
          barrierDismissible: false);
    },
    UserRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final queryParams = routeData.queryParams;
      final args = routeData.argsAs<UserRouteArgs>(
          orElse: () => UserRouteArgs(
              id: pathParams.getInt('userID', -1),
              query: queryParams.optString('query')));
      return CustomPage<dynamic>(
          routeData: routeData,
          child: UserPage(key: args.key, id: args.id, query: args.query),
          transitionsBuilder: TransitionsBuilders.noTransition,
          opaque: true,
          barrierDismissible: false);
    },
    NotFoundRoute.name: (routeData) {
      return CustomPage<dynamic>(
          routeData: routeData,
          child: NotFoundScreen(),
          transitionsBuilder: TransitionsBuilders.noTransition,
          opaque: true,
          barrierDismissible: false);
    },
    UserProfileRoute.name: (routeData) {
      final pathParams = routeData.inheritedPathParams;
      final queryParams = routeData.queryParams;
      final args = routeData.argsAs<UserProfileRouteArgs>(
          orElse: () =>
              UserProfileRouteArgs(likes: queryParams.getInt('likes', 0)));
      return CustomPage<dynamic>(
          routeData: routeData,
          child: UserProfilePage(
              key: args.key,
              navigate: args.navigate,
              userId: pathParams.getInt('userID', -1),
              likes: args.likes),
          transitionsBuilder: TransitionsBuilders.noTransition,
          opaque: true,
          barrierDismissible: false);
    },
    UserPostsRoute.name: (routeData) {
      return CustomPage<dynamic>(
          routeData: routeData,
          child: UserPostsPage(),
          transitionsBuilder: TransitionsBuilders.noTransition,
          opaque: true,
          barrierDismissible: false);
    },
    UserAllPostsRoute.name: (routeData) {
      final args = routeData.argsAs<UserAllPostsRouteArgs>(
          orElse: () => const UserAllPostsRouteArgs());
      return CustomPage<dynamic>(
          routeData: routeData,
          child: UserAllPostsPage(key: args.key, navigate: args.navigate),
          transitionsBuilder: TransitionsBuilders.noTransition,
          opaque: true,
          barrierDismissible: false);
    },
    UserFavoritePostsRoute.name: (routeData) {
      return CustomPage<dynamic>(
          routeData: routeData,
          child: UserFavoritePostsPage(),
          transitionsBuilder: TransitionsBuilders.noTransition,
          opaque: true,
          barrierDismissible: false);
    }
  };

  @override
  List<RouteConfig> get routes => [
        RouteConfig(HomeRoute.name, path: '/'),
        RouteConfig(LoginRoute.name, path: '/login'),
        RouteConfig('/user/:userID#redirect',
            path: '/user/:userID',
            redirectTo: '/user/:userID/page',
            fullMatch: true),
        RouteConfig(UserRoute.name, path: '/user/:userID/page', children: [
          RouteConfig(UserProfileRoute.name, path: '', parent: UserRoute.name),
          RouteConfig(UserPostsRoute.name,
              path: 'posts',
              parent: UserRoute.name,
              children: [
                RouteConfig('#redirect',
                    path: '',
                    parent: UserPostsRoute.name,
                    redirectTo: 'all',
                    fullMatch: true),
                RouteConfig(UserAllPostsRoute.name,
                    path: 'all', parent: UserPostsRoute.name),
                RouteConfig(UserFavoritePostsRoute.name,
                    path: 'favorite', parent: UserPostsRoute.name)
              ])
        ]),
        RouteConfig(NotFoundRoute.name, path: '*')
      ];
}

/// generated route for
/// [HomePage]
class HomeRoute extends PageRouteInfo<HomeRouteArgs> {
  HomeRoute(
      {Key? key, void Function()? navigate, void Function()? showUserPosts})
      : super(HomeRoute.name,
            path: '/',
            args: HomeRouteArgs(
                key: key, navigate: navigate, showUserPosts: showUserPosts));

  static const String name = 'HomeRoute';
}

class HomeRouteArgs {
  const HomeRouteArgs({this.key, this.navigate, this.showUserPosts});

  final Key? key;

  final void Function()? navigate;

  final void Function()? showUserPosts;

  @override
  String toString() {
    return 'HomeRouteArgs{key: $key, navigate: $navigate, showUserPosts: $showUserPosts}';
  }
}

/// generated route for
/// [LoginPage]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute() : super(LoginRoute.name, path: '/login');

  static const String name = 'LoginRoute';
}

/// generated route for
/// [UserPage]
class UserRoute extends PageRouteInfo<UserRouteArgs> {
  UserRoute(
      {Key? key, int id = -1, String? query, List<PageRouteInfo>? children})
      : super(UserRoute.name,
            path: '/user/:userID/page',
            args: UserRouteArgs(key: key, id: id, query: query),
            rawPathParams: {'userID': id},
            rawQueryParams: {'query': query},
            initialChildren: children);

  static const String name = 'UserRoute';
}

class UserRouteArgs {
  const UserRouteArgs({this.key, this.id = -1, this.query});

  final Key? key;

  final int id;

  final String? query;

  @override
  String toString() {
    return 'UserRouteArgs{key: $key, id: $id, query: $query}';
  }
}

/// generated route for
/// [NotFoundScreen]
class NotFoundRoute extends PageRouteInfo<void> {
  const NotFoundRoute() : super(NotFoundRoute.name, path: '*');

  static const String name = 'NotFoundRoute';
}

/// generated route for
/// [UserProfilePage]
class UserProfileRoute extends PageRouteInfo<UserProfileRouteArgs> {
  UserProfileRoute({Key? key, void Function()? navigate, int likes = 0})
      : super(UserProfileRoute.name,
            path: '',
            args: UserProfileRouteArgs(
                key: key, navigate: navigate, likes: likes),
            rawQueryParams: {'likes': likes});

  static const String name = 'UserProfileRoute';
}

class UserProfileRouteArgs {
  const UserProfileRouteArgs({this.key, this.navigate, this.likes = 0});

  final Key? key;

  final void Function()? navigate;

  final int likes;

  @override
  String toString() {
    return 'UserProfileRouteArgs{key: $key, navigate: $navigate, likes: $likes}';
  }
}

/// generated route for
/// [UserPostsPage]
class UserPostsRoute extends PageRouteInfo<void> {
  const UserPostsRoute({List<PageRouteInfo>? children})
      : super(UserPostsRoute.name, path: 'posts', initialChildren: children);

  static const String name = 'UserPostsRoute';
}

/// generated route for
/// [UserAllPostsPage]
class UserAllPostsRoute extends PageRouteInfo<UserAllPostsRouteArgs> {
  UserAllPostsRoute({Key? key, void Function()? navigate})
      : super(UserAllPostsRoute.name,
            path: 'all',
            args: UserAllPostsRouteArgs(key: key, navigate: navigate));

  static const String name = 'UserAllPostsRoute';
}

class UserAllPostsRouteArgs {
  const UserAllPostsRouteArgs({this.key, this.navigate});

  final Key? key;

  final void Function()? navigate;

  @override
  String toString() {
    return 'UserAllPostsRouteArgs{key: $key, navigate: $navigate}';
  }
}

/// generated route for
/// [UserFavoritePostsPage]
class UserFavoritePostsRoute extends PageRouteInfo<void> {
  const UserFavoritePostsRoute()
      : super(UserFavoritePostsRoute.name, path: 'favorite');

  static const String name = 'UserFavoritePostsRoute';
}
