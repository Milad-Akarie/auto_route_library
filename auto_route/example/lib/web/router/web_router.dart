import 'package:auto_route/auto_route.dart';
import 'package:example/web/router/web_router.gr.dart';
import 'package:example/web/web_main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@MaterialAutoRouter(
  replaceInRouteName: 'Page|Screen,Route',
  routes: <AutoRoute>[
    AutoRoute(path: '/', page: HomePage, initial: true),
    AutoRoute(path: '/login', page: LoginPage),
    AutoRoute(
      path: '/user/:userID',
      usesPathAsKey: false,
      page: UserPage,
      // guards: [AuthGuard],
      children: [
        AutoRoute(path: 'profile', page: UserProfilePage, initial: true),
        AutoRoute(path: 'posts', page: UserPostsPage, children: [
          AutoRoute(path: 'all', page: UserAllPostsPage, initial: true),
          AutoRoute(
            path: 'favorite',
            page: UserFavoritePostsPage,
          ),
        ]),
      ],
    ),
    AutoRoute(path: '*', page: NotFoundScreen),
  ],
)
class $WebAppRouter {}

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
      appBar: AppBar(),
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
                    context.router.navigateNamed('/user/1/profile');
                    // context.pushRoute(
                    //   UserRoute(
                    //     id: 1,
                    //     children: [
                    //       UserProfileRoute(likes: 2)
                    //       // UserPostsRoute(children: [
                    //       //   UserAllPostsRoute(),
                    //       // ])
                    //     ],
                    //   ),
                    // );
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

class UserProfilePage extends StatelessWidget {
  final VoidCallback? navigate;
  final int likes;

  const UserProfilePage({
    Key? key,
    this.navigate,
    @queryParam this.likes = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var userId = context.routeData.inheritedPathParams.getInt('userID');
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'User Profile : $userId',
              style: TextStyle(fontSize: 30),
            ),
            MaterialButton(
              color: Colors.red,
              onPressed: navigate ??
                  () {
                    context.router.navigateNamed('posts');
                  },
              child: Text('Posts'),
            ),
            const SizedBox(
              height: 32,
            ),
            // MaterialButton(
            //   color: Colors.blue,
            //   onPressed: () {
            //     setState(() {
            //       _count++;
            //     });
            //   },
            //   child: Text('Count $_count'),
            // ),
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
            Expanded(
              child: AutoRouter(
                  // onNewRoutes: (routes) {
                  //   print('OnNew UserPsot routes ${routes.map((e) => e.routeName)}');
                  //   return SynchronousFuture(null);
                  // },
                  // routes: (context) => [],
                  ),
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
            return Text(context.topRoute.name + ' $_id');
          },
        ),
        leading: AutoBackButton(),
      ),
      body: AutoRouter(
          // onNavigate: (routes, initial) async {
          //   // print('onNew routes ${routes.last.routeName}');
          //   showPosts = false;
          //   if (routes.isNotEmpty && routes.last.routeName == UserPostsRoute.name) {
          //     showPosts = true;
          //   }
          //   if (!initial) {
          //     setState(() {});
          //   }
          //
          //   return null;
          // },
          // routes: (_) => [
          //       UserProfileRoute(navigate: () {
          //         setState(() {
          //           showPosts = true;
          //         });
          //       }),
          //       if (showPosts) UserPostsRoute()
          //     ],
          // onPopRoute: (route, _) {
          //   showPosts = false;
          // }
          ),
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
