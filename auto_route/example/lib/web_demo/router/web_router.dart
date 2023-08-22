import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/web_router.gr.dart';
import 'package:example/web_demo/web_main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

//ignore_for_file: public_member_api_docs
@AutoRouterConfig(generateForDir: ['lib/web_demo'])
class WebAppRouter extends $WebAppRouter implements AutoRouteGuard {
  AuthService authService;

  WebAppRouter(this.authService);

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) async {
    if (authService.isAuthenticated ||
        resolver.routeName == WebLoginRoute.name) {
      resolver.next();
    } else {
      resolver.redirect(
        WebLoginRoute(onResult: (didLogin) {
          resolver.resolveNext(didLogin, reevaluateNext: false);
        }),
      );
    }
  }

  @override
  List<AutoRoute> get routes => [
        AutoRoute(page: MainWebRoute.page, initial: true),
        AutoRoute(path: '/login', page: WebLoginRoute.page),
        AutoRoute(path: '/verify', page: WebVerifyRoute.page),
        AutoRoute(
          path: '/user/:userID',
          page: UserRoute.page,
          children: [
            AutoRoute(page: UserProfileRoute.page, initial: true),
            AutoRoute(
              path: 'posts',
              page: UserPostsRoute.page,
              guards: [
                AutoRouteGuard.simple(
                  (resolver, scope) {
                    if (authService.isVerified) {
                      resolver.next();
                    } else {
                      resolver
                          .redirect(WebVerifyRoute(onResult: resolver.next));
                    }
                  },
                )
              ],
              children: [
                AutoRoute(
                    path: 'all', page: UserAllPostsRoute.page, initial: true),
                AutoRoute(path: 'favorite', page: UserFavoritePostsRoute.page),
              ],
            ),
          ],
        ),
        AutoRoute(path: '*', page: NotFoundRoute.page),
      ];
}

@RoutePage()
class MainWebPage extends StatefulWidget {
  final VoidCallback? navigate, showUserPosts;

  const MainWebPage({
    Key? key,
    this.navigate,
    this.showUserPosts,
  }) : super(key: key);

  @override
  State<MainWebPage> createState() => _MainWebPageState();
}

class _MainWebPageState extends State<MainWebPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AutoLeadingButton(),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'HomePage',
              style: TextStyle(fontSize: 30),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: widget.navigate ??
                    () {
                      context.pushRoute(
                        UserRoute(
                          id: 2,
                          query: const ['value1', 'value2'],
                        ),
                      );
                    },
                child: Text('Navigate to user/2'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () {
                  App.of(context).authService.isAuthenticated = false;
                },
                child: Text('Logout'),
              ),
            ),
            if (kIsWeb)
              ElevatedButton(
                onPressed: () {
                  final currentState =
                      ((context.router.pathState as int?) ?? 0);
                  context.router.pushPathState(currentState + 1);
                },
                child: AnimatedBuilder(
                    animation: context.router.navigationHistory,
                    builder: (context, _) {
                      return Text('Update State: ${context.router.pathState}');
                    }),
              ),
          ],
        ),
      ),
    );
  }
}

class QueryPage extends StatelessWidget {
  const QueryPage({
    Key? key,
    @pathParam this.id = '-',
  }) : super(key: key);
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('Query: $id'),
      ),
    );
  }
}

@RoutePage()
class UserProfilePage extends StatefulWidget {
  final VoidCallback? navigate;
  final int likes;
  final int userId;

  const UserProfilePage({
    Key? key,
    this.navigate,
    @PathParam('userID') this.userId = -1,
    @queryParam this.likes = 0,
  }) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'User Profile : ${widget.userId}  likes: ${widget.likes}}',
              style: TextStyle(fontSize: 30),
            ),
            Text(
              '${context.routeData.queryParams}',
              style: TextStyle(fontSize: 30),
            ),
            const SizedBox(height: 16),
            MaterialButton(
              color: Colors.red,
              onPressed: widget.navigate ??
                  () {
                    context.pushRoute(UserFavoritePostsRoute());
                  },
              child: Text('Posts -> '),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _counter++;
                  });
                },
                child: Text('State $_counter'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () {
                  App.of(context).authService.isAuthenticated = false;
                },
                child: Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@RoutePage()
class UserPostsPage extends StatefulWidget {
  final int id;

  const UserPostsPage({@PathParam.inherit('userID') required this.id});

  @override
  _UserPostsPageState createState() => _UserPostsPageState();
}

class _UserPostsPageState extends State<UserPostsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text(
              'User Posts ${widget.id}',
              style: TextStyle(fontSize: 30),
            ),
            ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    useRootNavigator: true,
                    builder: (_) => AlertDialog(
                      title: Text('Alert'),
                    ),
                  );
                },
                child: Text('Show Dialog')),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () {
                  App.of(context).authService.isAuthenticated = false;
                },
                child: Text('Logout'),
              ),
            ),
            Expanded(
              child: AutoRouter(),
            )
          ],
        ),
      ),
    );
  }
}

@RoutePage()
class UserPage extends StatefulWidget {
  final int id;
  final List<String>? query;

  UserPage({
    Key? key,
    @PathParam('userID') this.id = -1,
    @QueryParam() this.query,
  }) : super(key: key);

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      appBar: AppBar(
        leading: AutoLeadingButton(),
        title: Builder(
          builder: (context) {
            return Text(context.topRouteMatch.name +
                ' ${widget.id} query: ${widget.query}');
          },
        ),
      ),
      body: AutoRouter(),
    );
  }
}

@RoutePage()
class NotFoundScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '404!',
          style: TextStyle(fontSize: 28),
        ),
      ),
    );
  }
}

@RoutePage()
class UserAllPostsPage extends StatelessWidget {
  final VoidCallback? navigate;

  const UserAllPostsPage({Key? key, this.navigate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text(
              'All Posts',
              style: TextStyle(fontSize: 28),
            ),
            MaterialButton(
              color: Colors.red,
              onPressed: navigate ??
                  () {
                    context.pushRoute(UserFavoritePostsRoute());
                  },
              child: Text('Favorite'),
            ),
            MaterialButton(
              color: Colors.red,
              onPressed: navigate ?? () => context.back(),
              child: Text('back'),
            ),
          ],
        ),
      ),
    );
  }
}

@RoutePage()
class UserFavoritePostsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text(
              'Favorite Posts',
              style: TextStyle(fontSize: 28),
            ),
          ],
        ),
      ),
    );
  }
}
