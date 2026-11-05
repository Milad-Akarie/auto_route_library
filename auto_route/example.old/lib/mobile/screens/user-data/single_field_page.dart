import 'package:material_ui/material_ui.dart';

/// A step of the user data flow: a message, one text field and a next button
/// that stays disabled while the field is empty.
class SingleFieldPage extends StatefulWidget {
  /// Takes the texts and the [onNext] callback.
  const new({
    super.key,
    this.message = '',
    this.willPopMessage = '',
    this.onNext,
  });

  /// The prompt shown above the text field.
  final String message;

  /// The text of the snack bar shown when the user leaves this page.
  final String willPopMessage;

  /// Called with the entered text when the user presses next; `null` does
  /// nothing.
  final void Function(String)? onNext;

  @override
  SingleFieldPageState createState() => .new();
}

/// State of [SingleFieldPage]; holds the entered text.
class SingleFieldPageState extends State<SingleFieldPage> {
  String _text = '';
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.willPopMessage)),
        );
      },
      child: Scaffold(
        key: _scaffoldKey,
        body: Column(
          children: [
            const SizedBox(height: 100),
            Text(widget.message),
            Padding(
              padding: const .symmetric(horizontal: 32, vertical: 24),
              child: TextField(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                onChanged: (t) {
                  setState(() {
                    _text = t;
                  });
                },
              ),
            ),
            ElevatedButton(
              onPressed: _text.isEmpty
                  ? null
                  : () {
                      widget.onNext?.call(_text);
                    },
              child: const Text('Next'),
            ),
          ],
        ),
      ),
    );
  }
}
