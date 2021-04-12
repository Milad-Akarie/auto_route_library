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
        RedirectRoute(path: '', redirectTo: 'profile'),
        AutoRoute(path: 'profile', page: UserProfilePage),
        AutoRoute(path: 'posts', page: UserPostsPage, children: [
          RedirectRoute(path: '', redirectTo: 'post-profile'),
          AutoRoute(
            path: 'post-profile',
            name: 'PostsProfilePage',
            page: UserProfilePage,
          ),
        ]),
      ],
    ),
  ],
)
class $WebAppRouter {}

class HomePage extends StatelessWidget {
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
              onPressed: () {
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
              onPressed: () {
                context.router.push(UserPostsRoute());
              },
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

class UserPostsPage extends StatelessWidget {
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
            Expanded(child: AutoRouter())
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
  @override
  Widget build(BuildContext context) {
    print('Active user child ----> ${context.routeData.activeChild?.name}');
    return Scaffold(
      appBar: AppBar(title: Text('User ${widget.id}')),
      body: AutoRouter(),
    );
  }
}
