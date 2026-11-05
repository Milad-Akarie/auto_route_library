import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

part 'deferred_second_page.dart';

// Two pages in one library, only the first asking to load on demand. Dart
// defers a whole library, so the generated router loads both on demand.

/// A page that asks to be loaded on demand.
///
/// Its library also holds [DeferredSecondPage], which does not ask, and Dart
/// defers a whole library.
@RoutePage(deferredLoading: true)
class DeferredFirstPage extends StatelessWidget {
  /// Creates the page, which shows a fixed text.
  const new({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('First page'));
}
