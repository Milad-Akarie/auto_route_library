import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/web_auth_guard.dart';
import 'package:example/web_demo/router/web_router.gr.dart';
import 'package:example/web_demo/web_main.dart';
import 'package:flutter/material.dart';

@AutoRouterConfig(generateForDir: ['lib/web_demo'],deferredLoading: false)
class WebAppRouter extends $WebAppRouter {
  AuthService authService;

  WebAppRouter(this.authService);

 @override
  late final List<AutoRoute> routes = [
    AutoRoute(
      page: MainWebRoute.page,
      path: '/',
      guards: [AuthGuard(authService)],
    ),
    AutoRoute(
      path: '/login',
      page: WebLoginRoute.page,
      keepHistory: false,
    ),
    AutoRoute(
      path: '/user/:userID',
      page: UserRoute.page,
      children: [
        AutoRoute(path: '', page: UserProfileRoute.page),
        AutoRoute(
          path: 'posts',
          page: UserPostsRoute.page,
          children: [
            RedirectRoute(path: '', redirectTo: 'all'),
            AutoRoute(path: 'all', page: UserAllPostsRoute.page),
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
                onPressed:
                    widget.navigate ?? () => context.navigateTo(UserRoute(id: 2, query: const ['value1', 'value2'])),
                child: Text('Navigate to user/2'),
              ),
            ),
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
class UserProfilePage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'User Profile : $userId  likes: $likes}',
              style: TextStyle(fontSize: 30),
            ),
            Text(
              '${context.routeData.queryParams}',
              style: TextStyle(fontSize: 30),
            ),
            const SizedBox(height: 16),
            MaterialButton(
              color: Colors.red,
              onPressed: navigate ??
                  () {
                    context.pushRoute( UserPostsRoute());
                  },
              child: Text('Posts'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: navigate ??
                  () {
                    App.of(context).authService.isAuthenticated = false;
                  },
              child: Text('Logout'),
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
        title: Builder(
          builder: (context) {
            return Text(context.topRouteMatch.name + ' ${widget.id} query: ${widget.query}');
          },
        ),
        // leading: AutoLeadingButton(),
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
