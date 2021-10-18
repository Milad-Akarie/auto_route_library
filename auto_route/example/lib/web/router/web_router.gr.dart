// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouteGenerator
// **************************************************************************

part of 'web_router.dart';

class _$WebAppRouter extends RootStackRouter {
  _$WebAppRouter(
      {GlobalKey<NavigatorState>? navigatorKey, required this.authGuard})
      : super(navigatorKey);

  final AuthGuard authGuard;

  @override
  final Map<String, PageFactory> pagesMap = {
    HomeRoute.name: (routeData) {
      final args =
          routeData.argsAs<HomeRouteArgs>(orElse: () => const HomeRouteArgs());
      return CupertinoPageX<dynamic>(
          routeData: routeData,
          child: HomePage(
              key: args.key,
              navigate: args.navigate,
              showUserPosts: args.showUserPosts));
    },
    LoginRoute.name: (routeData) {
      final args = routeData.argsAs<LoginRouteArgs>(
          orElse: () => const LoginRouteArgs());
      return CupertinoPageX<dynamic>(
          routeData: routeData,
          child: LoginPage(key: args.key, onLoginResult: args.onLoginResult));
    },
    UserRoute.name: (routeData) {
      final pathParams = routeData.pathParams;
      final args = routeData.argsAs<UserRouteArgs>(
          orElse: () => UserRouteArgs(id: pathParams.getInt('userID', -1)));
      return CupertinoPageX<dynamic>(
          routeData: routeData, child: UserPage(key: args.key, id: args.id));
    },
    NotFoundRoute.name: (routeData) {
      return CupertinoPageX<dynamic>(
          routeData: routeData, child: NotFoundScreen());
    },
    UserProfileRoute.name: (routeData) {
      final queryParams = routeData.queryParams;
      final args = routeData.argsAs<UserProfileRouteArgs>(
          orElse: () =>
              UserProfileRouteArgs(likes: queryParams.getInt('likes', 0)));
      return CupertinoPageX<dynamic>(
          routeData: routeData,
          child: UserProfilePage(
              key: args.key, navigate: args.navigate, likes: args.likes));
    },
    UserPostsRoute.name: (routeData) {
      return CupertinoPageX<dynamic>(
          routeData: routeData, child: UserPostsPage());
    },
    UserAllPostsRoute.name: (routeData) {
      final args = routeData.argsAs<UserAllPostsRouteArgs>(
          orElse: () => const UserAllPostsRouteArgs());
      return CupertinoPageX<dynamic>(
          routeData: routeData,
          child: UserAllPostsPage(key: args.key, navigate: args.navigate));
    },
    UserFavoritePostsRoute.name: (routeData) {
      return CupertinoPageX<dynamic>(
          routeData: routeData, child: UserFavoritePostsPage());
    }
  };

  @override
  List<RouteConfig> get routes => [
        RouteConfig(HomeRoute.name, path: '/'),
        RouteConfig(LoginRoute.name, path: '/login'),
        RouteConfig(UserRoute.name, path: '/user/:userID', guards: [
          authGuard
        ], children: [
          RouteConfig('#redirect',
              path: '',
              parent: UserRoute.name,
              redirectTo: 'profile',
              fullMatch: true),
          RouteConfig(UserProfileRoute.name,
              path: 'profile', parent: UserRoute.name),
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

/// generated route for [HomePage]
class HomeRoute extends PageRouteInfo<HomeRouteArgs> {
  HomeRoute(
      {Key? key, void Function()? navigate, void Function()? showUserPosts})
      : super(name,
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
}

/// generated route for [LoginPage]
class LoginRoute extends PageRouteInfo<LoginRouteArgs> {
  LoginRoute({Key? key, void Function(bool)? onLoginResult})
      : super(name,
            path: '/login',
            args: LoginRouteArgs(key: key, onLoginResult: onLoginResult));

  static const String name = 'LoginRoute';
}

class LoginRouteArgs {
  const LoginRouteArgs({this.key, this.onLoginResult});

  final Key? key;

  final void Function(bool)? onLoginResult;
}

/// generated route for [UserPage]
class UserRoute extends PageRouteInfo<UserRouteArgs> {
  UserRoute({Key? key, int id = -1, List<PageRouteInfo>? children})
      : super(name,
            path: '/user/:userID',
            args: UserRouteArgs(key: key, id: id),
            rawPathParams: {'userID': id},
            initialChildren: children);

  static const String name = 'UserRoute';
}

class UserRouteArgs {
  const UserRouteArgs({this.key, this.id = -1});

  final Key? key;

  final int id;
}

/// generated route for [NotFoundScreen]
class NotFoundRoute extends PageRouteInfo<void> {
  const NotFoundRoute() : super(name, path: '*');

  static const String name = 'NotFoundRoute';
}

/// generated route for [UserProfilePage]
class UserProfileRoute extends PageRouteInfo<UserProfileRouteArgs> {
  UserProfileRoute({Key? key, void Function()? navigate, int likes = 0})
      : super(name,
            path: 'profile',
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
}

/// generated route for [UserPostsPage]
class UserPostsRoute extends PageRouteInfo<void> {
  const UserPostsRoute({List<PageRouteInfo>? children})
      : super(name, path: 'posts', initialChildren: children);

  static const String name = 'UserPostsRoute';
}

/// generated route for [UserAllPostsPage]
class UserAllPostsRoute extends PageRouteInfo<UserAllPostsRouteArgs> {
  UserAllPostsRoute({Key? key, void Function()? navigate})
      : super(name,
            path: 'all',
            args: UserAllPostsRouteArgs(key: key, navigate: navigate));

  static const String name = 'UserAllPostsRoute';
}

class UserAllPostsRouteArgs {
  const UserAllPostsRouteArgs({this.key, this.navigate});

  final Key? key;

  final void Function()? navigate;
}

/// generated route for [UserFavoritePostsPage]
class UserFavoritePostsRoute extends PageRouteInfo<void> {
  const UserFavoritePostsRoute() : super(name, path: 'favorite');

  static const String name = 'UserFavoritePostsRoute';
}
