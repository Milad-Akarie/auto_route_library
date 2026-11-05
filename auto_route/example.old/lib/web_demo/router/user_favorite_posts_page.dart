import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

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
