import 'package:auto_route/auto_route.dart';
import 'package:example/web/router/web_auth_guard.dart';
import 'package:example/web/web_main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// optionally add part directive to use
// pare builder
part 'web_router.gr.dart';

@CupertinoAutoRouter(
  replaceInRouteName: 'Page|Screen,Route',
  routes: <AutoRoute>[
    AutoRoute(
      path: '/',
      page: HomePage,
      initial: true,
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
          path: 'profile',
          page: UserProfilePage,
          initial: true,
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

class HomePage extends StatefulWidget {
  final VoidCallback? navigate, showUserPosts;

  const HomePage({
    Key? key,
    this.navigate,
    this.showUserPosts,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AutoBackButton(),
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
              onPressed: widget.navigate ??
                  () {
                    // context.pushRoute(
                    //   UserRoute(id: 5, children: [
                    //     UserProfileRoute(name: 'Name'),
                    //   ]),
                    // );
                    context.navigateNamedTo('/user/2');
                  },
              child: Text('Navigate to user/2'),
            ),
            ElevatedButton(
              onPressed: widget.showUserPosts,
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
                    context.router.pushNamed('posts');
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

  UserPage({
    Key? key,
    @PathParam('userID') this.id = -1,
  }) : super(key: key);

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late var _id = widget.id;

  @override
  void didUpdateWidget(covariant UserPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.id != oldWidget.id) {
      print('User Id changed ${widget.id}');
      _id = widget.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            return Text(context.topRouteMatch.name + ' $_id');
          },
        ),
        leading: AutoBackButton(),
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
