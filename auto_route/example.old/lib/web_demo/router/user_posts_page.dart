import 'package:auto_route/auto_route.dart';
import 'package:example/web_demo/app.dart';
import 'package:material_ui/material_ui.dart';

/// Posts of a user, with a nested router for the lists of all and favorite
/// posts.
@RoutePage()
class UserPostsPage extends StatelessWidget {
  /// Takes the user [id], which is inherited from the parent route.
  const new({@PathParam.inherit('userID') required this.id, super.key});

  /// The id of the user whose posts show.
  final int id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text('User Posts $id', style: const TextStyle(fontSize: 30)),
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
