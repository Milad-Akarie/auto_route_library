import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:collection/collection.dart';
import 'package:material_ui/material_ui.dart';

part 'web_demo_router.gr.dart';

// A copy of the routes and pages of the example's former web demo that the
// #1837 test drives, so the test keeps them when the example changes. The
// route tree and its guards are the demo's; the pages keep only what the test
// sees or taps.

/// The demo's sign-in state, read by the router's guards.
class AuthService extends ChangeNotifier {
  bool _isAuthenticated = false;

  bool get isAuthenticated => _isAuthenticated;

  set isAuthenticated(bool value) {
    _isAuthenticated = value;
    if (!_isAuthenticated) {
      _isVerified = false;
    }
    notifyListeners();
  }

  bool _isVerified = false;

  bool get isVerified => _isVerified;

  set isVerified(bool value) {
    _isVerified = value;
    notifyListeners();
  }
}

@AutoRouterConfig(generateForDir: ['integration_test/support/web_demo_router'])
class WebAppRouter extends RootStackRouter {
  WebAppRouter(this.authService);
  final AuthService authService;

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
              unawaited(resolver.redirectUntil(const WebLoginRoute()));
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
              (resolver, _) {
                if (authService.isVerified) {
                  resolver.next();
                } else {
                  unawaited(resolver.redirectUntil(const WebVerifyRoute()));
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
class MainWebPage extends StatelessWidget {
  const MainWebPage({super.key});

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
                onPressed: () async {
                  await context.pushRoute(
                    UserRoute(id: 2, query: const ['value1', 'value2'], fragment: 'frag'),
                  );
                },
                child: const Text('Navigate to user/2'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

@RoutePage()
class WebLoginPage extends StatelessWidget {
  const WebLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text('Login')),
    );
  }
}

@RoutePage()
class WebVerifyPage extends StatelessWidget {
  const WebVerifyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Center(child: Text('verify')),
    );
  }
}

@RoutePage()
class UserPage extends StatelessWidget {
  const UserPage({
    super.key,
    @PathParam('userID') this.id = -1,
    @QueryParam() this.query,
    @urlFragment this.fragment,
  });
  final int id;
  final List<String>? query;
  final String? fragment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const AutoLeadingButton(),
        title: Builder(
          builder: (context) {
            return Text('${context.topRouteMatch.name} $id query: $query, fragment: $fragment');
          },
        ),
      ),
      body: const AutoRouter(),
    );
  }
}

@RoutePage()
class UserProfilePage extends StatelessWidget {
  const UserProfilePage({
    super.key,
    @PathParam('userID') this.userId = -1,
    @queryParam this.likes = 0,
  });
  final int likes;
  final int userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: .min,
          spacing: 16,
          children: [
            Text('User Profile : $userId  likes: $likes', style: const TextStyle(fontSize: 30)),
            MaterialButton(
              color: Colors.red,
              onPressed: () {
                unawaited(context.pushRoute(const UserFavoritePostsRoute()));
              },
              child: const Text('Posts -> '),
            ),
          ],
        ),
      ),
    );
  }
}

@RoutePage()
class UserPostsPage extends StatelessWidget {
  const UserPostsPage({super.key, @PathParam.inherit('userID') required this.id});
  final int id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text('User Posts $id', style: const TextStyle(fontSize: 30)),
          const Expanded(child: AutoRouter()),
        ],
      ),
    );
  }
}

@RoutePage()
class UserAllPostsPage extends StatelessWidget {
  const UserAllPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('All Posts')));
  }
}

@RoutePage()
class UserFavoritePostsPage extends StatelessWidget {
  const UserFavoritePostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Favorite Posts')));
  }
}

@RoutePage()
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('404!')));
  }
}
