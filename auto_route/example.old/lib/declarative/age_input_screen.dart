import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// Second step of the declarative example: asks for an age.
// age submit page
@RoutePage()
class AgeInputScreen extends StatefulWidget {
  /// Takes the callback that receives the age when the user submits it.
  const new({required this.onAgeSubmitted, super.key});

  /// Called with the entered number when the user submits the age.
  ///
  /// The text is parsed as an integer, so a non-numeric entry throws a
  /// [FormatException].
  final ValueChanged<int> onAgeSubmitted;

  @override
  State<AgeInputScreen> createState() => _AgeInputScreenState();
}

class _AgeInputScreenState extends State<AgeInputScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const .all(16),
          child: Column(
            children: [
              const Text('Enter your age'),
              TextField(controller: _controller, textAlign: .center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  widget.onAgeSubmitted(int.parse(_controller.text));
                },
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
