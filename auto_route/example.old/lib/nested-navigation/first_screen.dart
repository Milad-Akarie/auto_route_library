import 'package:auto_route/auto_route.dart';
import 'package:example/nested-navigation/nested_router.gr.dart';
import 'package:material_ui/material_ui.dart';

/// Child page with a button that opens `SecondScreen` in the host's nested
/// router.
@RoutePage()
class FirstScreen extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.pushRoute(const SecondRoute()),
          child: const Text('Go to second screen'),
        ),
      ),
    );
  }
}
