import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/web_router.gr.dart';
import 'package:example/web_demo/web_main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

//ignore_for_file: public_member_api_docs
@AutoRouterConfig(generateForDir: ['lib/web_demo'])
class WebAppRouter extends RootStackRouter {
  AuthService authService;

  WebAppRouter(this.authService);

  @override
  List<AutoRoute> get routes => [
        AutoRoute(
          initial: true,
          page: MainWebRoute.page,
          guards: [
            AutoRouteGuard.simple(
              (resolver, _) {
                if (authService.isAuthenticated) {
                  resolver.next();
                } else {
                  resolver.redirectUntil(WebLoginRoute());
                }
              },
            ),
          ],
        ),
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
                    print('Verify Guard: ${resolver.routeName}, isRev: ${resolver.isReevaluating}');
                    if (authService.isVerified) {
                      resolver.next();
                    } else {
                      resolver.redirectUntil(WebVerifyRoute());
                    }
                  },
                )
              ],
              children: [
                AutoRoute(path: 'all', page: UserAllPostsRoute.page, initial: true),
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
    super.key,
    this.navigate,
    this.showUserPosts,
  });

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
                    () async {
                      context.pushRoute(
                        UserRoute(
                          id: 2,
                          query: const ['value1', 'value2'],
                          fragment: 'frag',
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
                  final currentState = ((context.router.pathState as int?) ?? 0);
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
    super.key,
    @pathParam this.id = '-',
  });
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
    super.key,
    this.navigate,
    @PathParam('userID') this.userId = -1,
    @queryParam this.likes = 0,
  });

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

  const UserPostsPage({super.key, @PathParam.inherit('userID') required this.id});

  @override
  UserPostsPageState createState() => UserPostsPageState();
}

class UserPostsPageState extends State<UserPostsPage> {
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
  final String? fragment;

  const UserPage({
    super.key,
    @PathParam('userID') this.id = -1,
    @QueryParam() this.query,
    @urlFragment this.fragment,
  });

  @override
  UserPageState createState() => UserPageState();
}

class UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      appBar: AppBar(
        leading: AutoLeadingButton(),
        title: Builder(
          builder: (context) {
            return Text(
                '${context.topRouteMatch.name} ${widget.id} query: ${widget.query}, fragment: ${widget.fragment}');
          },
        ),
      ),
      body: AutoRouter(),
    );
  }
}

@RoutePage()
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

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

  const UserAllPostsPage({super.key, this.navigate});

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
  const UserFavoritePostsPage({super.key});

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
