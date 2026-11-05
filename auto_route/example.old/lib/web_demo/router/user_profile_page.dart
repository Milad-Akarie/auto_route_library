import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/app.dart';
import 'package:example/web_demo/router/web_app_router.gr.dart';
import 'package:material_ui/material_ui.dart';

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
