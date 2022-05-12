import 'package:auto_route/auto_route.dart';
import 'package:example/web/router/web_auth_guard.dart';
import 'package:example/web/web_main.dart';
import 'package:flutter/material.dart';

// optionally add part directive to use
// pare builder
part 'web_router.gr.dart';

@CustomAutoRouter(
  transitionsBuilder: TransitionsBuilders.noTransition,
  replaceInRouteName: 'Page|Screen,Route',
  routes: <AutoRoute>[
    CustomRoute(
      path: '/',
      page: HomePage,
      initial: true,
      reverseDurationInMilliseconds: 0,
    ),
    AutoRoute(path: '/login', page: LoginPage),
    RedirectRoute(
      path: '/user/:userID',
      redirectTo: '/user/:userID/page',
    ),
    AutoRoute(
      path: '/user/:userID/page',
      guards: [AuthGuard],
      page: UserPage,
      children: [
        AutoRoute(
          path: '',
          page: UserProfilePage,
        ),
        AutoRoute(
          path: 'posts',
          page: UserPostsPage,
          children: [
            AutoRoute(
              path: 'all',
              page: UserAllPostsPage,
              initial: true,
            ),
            AutoRoute(
              path: 'favorite',
              page: UserFavoritePostsPage,
            ),
          ],
        ),
      ],
    ),
    AutoRoute(path: '*', page: NotFoundScreen),
  ],
)
// when using a part build you should not
// use the '$' prefix on the actual class
// instead extend the generated class
// prefixing it with '_$'
class WebAppRouter extends _$WebAppRouter {
  WebAppRouter(
    AuthService authService,
  ) : super(
          authGuard: AuthGuard(authService),
        );
}

class HomePage extends StatelessWidget {
  final VoidCallback? navigate, showUserPosts;
  const HomePage({
    Key? key,
    this.navigate,
    this.showUserPosts,
  }) : super(key: key);


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
            ElevatedButton(
              onPressed: navigate ??
                  () {

                    context.navigateNamedTo('/user/2?query=foo');
                  },
              child: Text('Navigate to user/2'),
            ),
            ElevatedButton(
              onPressed: showUserPosts,
              child: Text('Show user posts'),
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
                    context.pushRoute(const UserPostsRoute());
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

class UserPostsPage extends StatefulWidget {
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
              'User Posts',
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

class UserPage extends StatefulWidget {
  final int id;
  final String? query;
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
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            return Text(context.topRouteMatch.name + ' ${widget.id} query: ${widget.query}');
          },
        ),
        leading: AutoLeadingButton(),
      ),
      body: AutoRouter(),
    );
  }
}

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
              onPressed: navigate ??
                  () {
                    context.navigateBack();
                  },
              child: Text('back'),
            ),
          ],
        ),
      ),
    );
  }
}

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
