import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

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
