import 'package:auto_route/auto_route.dart';
import 'package:example/web/router/web_router.gr.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(path: '/', page: HomePage),
    AutoRoute(
      path: '/user/:userID',
      page: UserPage,
      children: [
        AutoRoute(path: 'profile', page: UserProfilePage),
        AutoRoute(path: 'posts', page: UserPostsPage, children: [
          AutoRoute(
            path: 'all',
            page: UserAllPostsPage,
          ),
          AutoRoute(
            path: 'favorite',
            page: UserFavoritePostsPage,
          ),
        ]),
      ],
    ),
    AutoRoute(path: '*', page: NotFoundPage),
  ],
)
class $WebAppRouter {}

class HomePage extends StatelessWidget {
  final VoidCallback? navigate;

  const HomePage({Key? key, this.navigate}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    context.pushRoute(UserRoute(id: 1));
                  },
              child: Text('Navigate to user/1'),
            )
          ],
        ),
      ),
    );
  }
}

class UserProfilePage extends StatefulWidget {
  final VoidCallback navigate;

  const UserProfilePage({Key? key, required this.navigate}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    final pathParams = context.routeData.parent?.pathParams;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'User Profile : ${pathParams?.optInt('userID')}',
              style: TextStyle(fontSize: 30),
            ),
            MaterialButton(
              color: Colors.red,
              onPressed: widget.navigate,
              child: Text('Posts'),
            ),
            const SizedBox(
              height: 32,
            ),
            MaterialButton(
              color: Colors.blue,
              onPressed: () {
                setState(() {
                  _count++;
                });
              },
              child: Text('Count $_count'),
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
  PageRouteInfo? _favoritePosts;

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
            Expanded(
                child: AutoRouter.declarative(
              onInitialRoutes: (tree) {
                _favoritePosts = null;
                if (tree.topRoute?.routeName == UserFavoritePostsRoute.name) {
                  _favoritePosts = tree.topRoute;
                }
              },
              routes: (context) => [
                UserAllPostsRoute(navigate: () {
                  setState(() {
                    _favoritePosts = UserFavoritePostsRoute();
                  });
                }),
                if (_favoritePosts != null) _favoritePosts!,
              ],
            ))
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
  PageRouteInfo? _postsRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User ${widget.id} ${context.routeData.queryParams.toString()}')),
      body: AutoRouter.declarative(
        onInitialRoutes: (UrlTree tree) {
          if (tree.topRoute?.routeName == UserPostsRoute.name) {
            _postsRoute = tree.topRoute;
          } else {
            _postsRoute = null;
          }
        },
        routes: (context) => [
          UserProfileRoute(navigate: () {
            setState(() {
              _postsRoute = const UserPostsRoute();
            });
          }),
          if (_postsRoute != null) _postsRoute!,
        ],
      ),
    );
  }
}

class NotFoundPage extends StatelessWidget {
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
  final VoidCallback navigate;
  const UserAllPostsPage({Key? key, required this.navigate}) : super(key: key);

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
              onPressed: navigate,
              child: Text('Favorite'),
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
