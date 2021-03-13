import 'package:auto_route/auto_route.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

@CustomAutoRouter(
  replaceInRouteName: 'Page,Route',
  routes: <AutoRoute>[
    AutoRoute(path: '/', page: HomePage),
    AutoRoute(
      path: '/user/:id',
      page: UserPage,
      children: [
        RedirectRoute(path: '', redirectTo: 'profile'),
        AutoRoute(path: 'profile', page: UserProfilePage),
        AutoRoute(path: 'posts', page: UserPostsPage),
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
        child: Text(
          'HomePage',
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}

class UserProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'User Profile',
          style: TextStyle(fontSize: 30),
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
        child: Text(
          'User Posts',
          style: TextStyle(fontSize: 30),
        ),
      ),
    );
  }
}

class UserPage extends StatelessWidget {
  final int? id;

  const UserPage({Key? key, @pathParam this.id, int? x}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User $id'),
        actions: [
          IconButton(
            icon: Icon(Icons.account_box),
            onPressed: () {
              // AutoRouter.innerRouterOf(context, UserRoute.name)?.push(UserPostsRoute());
            },
          ),
        ],
      ),
      body: AutoRouter(),
    );
  }
}
