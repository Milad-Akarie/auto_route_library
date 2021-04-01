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

class UserProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final pathParams = context.routeData.parent?.pathParams;

    return Scaffold(
      body: Center(
        child: Text(
          'User Profile : ${pathParams?.optInt('userID')}',
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
  final int id;

  UserPage({
    Key? key,
    @PathParam('userID') this.id = -1,
  }) : super(key: key);

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
