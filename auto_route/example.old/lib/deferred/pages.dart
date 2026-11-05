import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

// Two pages in one library, only the first asking to load on demand. Dart
// defers a whole library, so the generated router loads both on demand.

@RoutePage(deferredLoading: true)
class DeferredFirstPage extends StatelessWidget {
  const DeferredFirstPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('First page'));
}

@RoutePage()
class DeferredSecondPage extends StatelessWidget {
  const DeferredSecondPage({super.key});

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Text('Second page'));
}
