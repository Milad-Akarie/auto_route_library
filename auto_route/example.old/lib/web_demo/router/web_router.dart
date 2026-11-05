import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/web_router.gr.dart';
import 'package:example/web_demo/web_main.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Routes of the web example app.
///
/// The main page needs a signed-in user, and the posts of a user also need a
/// verified one. Both guards redirect to their own page.
@AutoRouterConfig(generateForDir: ['lib/web_demo'])
class WebAppRouter extends RootStackRouter {
  /// Takes the [AuthService] that the guards ask.
  new(this.authService);

  /// The sign-in state the guards check.
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

/// Main page of the web example, with buttons to open a user and to sign out.
@RoutePage()
// An example page, kept as written so the example shows the same code.
// ignore: avoid-unnecessary-stateful-widgets
class MainWebPage extends StatefulWidget {
  /// All arguments are optional.
  const new({super.key, this.onNavigate, this.onShowUserPosts});

  /// Replaces the default of the button that opens user 2.
  final VoidCallback? onNavigate;

  /// Not used by this page.
  final VoidCallback? onShowUserPosts;

  @override
  State<MainWebPage> createState() => _MainWebPageState();
}

class _MainWebPageState extends State<MainWebPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AutoLeadingButton()),
      body: Center(
        child: Column(
          mainAxisSize: .min,
          children: [
            const Text('HomePage', style: TextStyle(fontSize: 30)),
            Padding(
              padding: const .symmetric(vertical: 16),
              child: ElevatedButton(
                onPressed:
                    widget.onNavigate ??
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
                    return Text(
                      'Update State: ${context.router.pathState ?? 'null'}',
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Page that shows its `id` path parameter; not part of any route.
class QueryPage extends StatelessWidget {
  /// Takes the [id] path parameter.
  const new({super.key, @pathParam this.id = '-'});

  /// The id from the path, `-` when the url has none.
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text('Query: $id')));
  }
}

/// Profile of a user, with a button that opens the favorite posts.
@RoutePage()
class UserProfilePage extends StatefulWidget {
  /// All arguments are optional.
  const new({
    super.key,
    this.onNavigate,
    @PathParam('userID') this.userId = -1,
    @queryParam this.likes = 0,
  });

  /// Replaces the default of the button that opens the favorite posts.
  final VoidCallback? onNavigate;

  /// The `likes` query parameter, 0 when the url has none.
  final int likes;

  /// The user id, taken from the `userID` path parameter; -1 when the url has
  /// none.
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
                  widget.onNavigate ??
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

/// Posts of a user, with a nested router for the lists of all and favorite
/// posts.
@RoutePage()
// An example page, kept as written so the example shows the same code.
// ignore: avoid-unnecessary-stateful-widgets
class UserPostsPage extends StatefulWidget {
  /// Takes the user [id], which is inherited from the parent route.
  const new({@PathParam.inherit('userID') required this.id, super.key});

  /// The id of the user whose posts show.
  final int id;

  @override
  UserPostsPageState createState() => .new();
}

/// State of [UserPostsPage].
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
                  builder: (_) => const AlertDialog(title: Text('Alert')),
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
            const Expanded(child: AutoRouter()),
          ],
        ),
      ),
    );
  }
}

/// Page of a user, with a nested router for the profile and the posts.
@RoutePage()
// An example page, kept as written so the example shows the same code.
// ignore: avoid-unnecessary-stateful-widgets
class UserPage extends StatefulWidget {
  /// All arguments are optional.
  const new({
    super.key,
    @PathParam('userID') this.id = -1,
    @QueryParam() this.query,
    @urlFragment this.fragment,
  });

  /// The user id, taken from the `userID` path parameter; -1 when the url has
  /// none.
  final int id;

  /// The `query` values from the url, or `null` when there are none.
  final List<String>? query;

  /// The url fragment, or `null` when there is none.
  final String? fragment;

  @override
  UserPageState createState() => .new();
}

/// State of [UserPage].
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
              '${widget.query ?? 'null'}, fragment: '
              '${widget.fragment ?? 'null'}',
            );
          },
        ),
      ),
      body: const AutoRouter(),
    );
  }
}

/// Page for urls that match no route.
@RoutePage()
class NotFoundScreen extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('404!', style: TextStyle(fontSize: 28))),
    );
  }
}

/// Lists all posts of a user, with buttons for the favorite posts and back.
@RoutePage()
class UserAllPostsPage extends StatelessWidget {
  /// Takes [onNavigate].
  const new({super.key, this.onNavigate});

  /// Replaces the default action of both buttons.
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            const Text('All Posts', style: TextStyle(fontSize: 28)),
            MaterialButton(
              color: Colors.red,
              onPressed:
                  onNavigate ??
                  () {
                    unawaited(
                      context.pushRoute(const UserFavoritePostsRoute()),
                    );
                  },
              child: const Text('Favorite'),
            ),
            MaterialButton(
              color: Colors.red,
              onPressed: onNavigate ?? () => context.back(),
              child: const Text('back'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lists the favorite posts of a user.
@RoutePage()
class UserFavoritePostsPage extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          children: [Text('Favorite Posts', style: TextStyle(fontSize: 28))],
        ),
      ),
    );
  }
}
