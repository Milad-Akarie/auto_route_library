import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// First step of the declarative example: asks for a name.
@RoutePage()
class NameInputScreen extends StatefulWidget {
  /// Takes the callback that receives the name when the user submits it.
  const new({required this.onNameSubmitted, super.key});

  /// Called with the entered text when the user submits the name.
  final ValueChanged<String> onNameSubmitted;

  @override
  State<NameInputScreen> createState() => _NameInputScreenState();
}

class _NameInputScreenState extends State<NameInputScreen> {
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
              const Text('Enter your name'),
              TextField(controller: _controller, textAlign: .center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  widget.onNameSubmitted(_controller.text);
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
