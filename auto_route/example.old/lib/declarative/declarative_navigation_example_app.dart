import 'package:example/declarative/dec_router.dart';
import 'package:material_ui/material_ui.dart';

/// Root widget of the declarative navigation example.
///
/// Asks for a name and an age, then shows both, with the visible step chosen by
/// the data entered so far.
class DeclarativeNavigationExampleApp extends StatelessWidget {
  /// Creates the app, which builds its own [DecRouter].
  new({super.key});
  final _router = DecRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router.config());
  }
}
