import 'package:example/nested-navigation/nested_router.dart';
import 'package:material_ui/material_ui.dart';

/// Root widget of the nested navigation example.
class NestedNavigationApp extends StatelessWidget {
  /// Creates the app, which builds its own [NestedRouter].
  new({super.key});

  /// The router of this app.
  final nestedRouter = NestedRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: nestedRouter.config());
  }
}
