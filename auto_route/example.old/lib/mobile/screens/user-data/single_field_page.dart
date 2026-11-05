import 'package:material_ui/material_ui.dart';

class SingleFieldPage extends StatefulWidget {
  const SingleFieldPage({
    super.key,
    this.message = '',
    this.willPopMessage = '',
    this.onNext,
  });
  final String message;
  final String willPopMessage;
  final void Function(String)? onNext;

  @override
  SingleFieldPageState createState() => .new();
}

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
