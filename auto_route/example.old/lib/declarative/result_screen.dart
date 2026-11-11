import 'package:auto_route/auto_route.dart';
import 'package:example/declarative/profile.dart';
import 'package:material_ui/material_ui.dart';

/// Last step of the declarative example: shows the profile and a reset button.
@RoutePage()
class ResultScreen extends StatelessWidget {
  /// Both arguments are required.
  const new({required this.profile, required this.onReset, super.key});

  /// The name and age to show.
  final Profile profile;

  /// Called when the user presses the reset button.
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const .all(16),
          child: Column(
            children: [
              Text('Name: ${profile.name ?? 'null'}'),
              Text('Age: ${profile.age ?? 'null'}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onReset,
                child: const Text('Reset State'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
