import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/web_router.gr.dart';
import 'package:example/web_demo/web_main.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

@AutoRouterConfig(generateForDir: ['lib/web_demo'])
class WebAppRouter extends RootStackRouter {
  new(this.authService);
  AuthService authService;

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
              unawaited(resolver.redirectUntil(WebLoginRoute()));
            }
          },
          debugLabel: 'AuthGuard',
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
                debugPrint(
                  'Verify Guard: ${resolver.routeName}, isRev: '
                  '${resolver.isReevaluating}',
                );
                if (authService.isVerified) {
                  resolver.next();
                } else {
                  unawaited(resolver.redirectUntil(WebVerifyRoute()));
                }
              },
              debugLabel: 'VerifyGuard',
            ),
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
// An example page, kept as written so the example shows the same code.
// ignore: avoid-unnecessary-stateful-widgets
class MainWebPage extends StatefulWidget {
  const new({
    super.key,
    this.navigate,
    this.showUserPosts,
  });
  final VoidCallback? navigate;
  final VoidCallback? showUserPosts;

  @override
  State<MainWebPage> createState() => _MainWebPageState();
}

class _MainWebPageState extends State<MainWebPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AutoLeadingButton(),
      ),
      body: Center(
        child: Column(
          mainAxisSize: .min,
          children: [
            const Text(
              'HomePage',
              style: TextStyle(fontSize: 30),
            ),
            Padding(
              padding: const .symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed:
                    widget.navigate ??
                    () async {
                      await context.pushRoute(
                        UserRoute(
                          id: 2,
                          query: const ['value1', 'value2'],
                          fragment: 'frag',
                        ),
                      );
                    },
                child: const Text('Navigate to user/2'),
              ),
            ),
            Padding(
              padding: const .symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () {
                  App.of(context).authService.isAuthenticated = false;
                },
                child: const Text('Logout'),
              ),
            ),
            if (kIsWeb)
              ElevatedButton(
                onPressed: () {
                  final currentState = (context.router.pathState as int?) ?? 0;
                  context.router.pushPathState(currentState + 1);
                },
                child: AnimatedBuilder(
                  animation: context.router.navigationHistory,
                  builder: (context, _) {
                    return Text('Update State: ${context.router.pathState}');
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class QueryPage extends StatelessWidget {
  const new({
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
  const new({
    super.key,
    this.navigate,
    @PathParam('userID') this.userId = -1,
    @queryParam this.likes = 0,
  });
  final VoidCallback? navigate;
  final int likes;
  final int userId;

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
          mainAxisSize: .min,
          children: [
            Text(
              'User Profile : ${widget.userId}  likes: ${widget.likes}}',
              style: const TextStyle(fontSize: 30),
            ),
            Text(
              '${context.routeData.queryParams}',
              style: const TextStyle(fontSize: 30),
            ),
            const SizedBox(height: 16),
            MaterialButton(
              color: Colors.red,
              onPressed:
                  widget.navigate ??
                  () {
                    unawaited(
                      context.pushRoute(const UserFavoritePostsRoute()),
                    );
                  },
              child: const Text('Posts -> '),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const .symmetric(vertical: 16),
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
              padding: const .symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () {
                  App.of(context).authService.isAuthenticated = false;
                },
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@RoutePage()
// An example page, kept as written so the example shows the same code.
// ignore: avoid-unnecessary-stateful-widgets
class UserPostsPage extends StatefulWidget {
  const new({
    super.key,
    @PathParam.inherit('userID') required this.id,
  });
  final int id;

  @override
  UserPostsPageState createState() => .new();
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
              style: const TextStyle(fontSize: 30),
            ),
            ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('Alert'),
                  ),
                );
              },
              child: const Text('Show Dialog'),
            ),
            Padding(
              padding: const .symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed: () {
                  App.of(context).authService.isAuthenticated = false;
                },
                child: const Text('Logout'),
              ),
            ),
            const Expanded(
              child: AutoRouter(),
            ),
          ],
        ),
      ),
    );
  }
}

@RoutePage()
// An example page, kept as written so the example shows the same code.
// ignore: avoid-unnecessary-stateful-widgets
class UserPage extends StatefulWidget {
  const new({
    super.key,
    @PathParam('userID') this.id = -1,
    @QueryParam() this.query,
    @urlFragment this.fragment,
  });
  final int id;
  final List<String>? query;
  final String? fragment;

  @override
  UserPageState createState() => .new();
}

class UserPageState extends State<UserPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      appBar: AppBar(
        leading: const AutoLeadingButton(),
        title: Builder(
          builder: (context) {
            return Text(
              '${context.topRouteMatch.name} ${widget.id} query: '
              '${widget.query}, fragment: ${widget.fragment}',
            );
          },
        ),
      ),
      body: const AutoRouter(),
    );
  }
}

@RoutePage()
class NotFoundScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
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
  const new({super.key, this.navigate});
  final VoidCallback? navigate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const Text(
              'All Posts',
              style: TextStyle(fontSize: 28),
            ),
            MaterialButton(
              color: Colors.red,
              onPressed:
                  navigate ??
                  () {
                    unawaited(
                      context.pushRoute(const UserFavoritePostsRoute()),
                    );
                  },
              child: const Text('Favorite'),
            ),
            MaterialButton(
              color: Colors.red,
              onPressed: navigate ?? () => context.back(),
              child: const Text('back'),
            ),
          ],
        ),
      ),
    );
  }
}

@RoutePage()
class UserFavoritePostsPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
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
