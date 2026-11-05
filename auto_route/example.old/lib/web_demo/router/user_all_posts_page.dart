import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/router/web_app_router.gr.dart';
import 'package:material_ui/material_ui.dart';

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
