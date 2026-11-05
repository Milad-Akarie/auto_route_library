import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// Child page with a button that pops back to `FirstScreen`.
@RoutePage()
class SecondScreen extends StatelessWidget {
  /// Creates the page.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => context.maybePop(),
          child: const Text('Go Back'),
        ),
      ),
    );
  }
}
