import 'package:material_ui/material_ui.dart';

/// A tab page with a title, a text and a button, each carrying the label.
class TitledTabPage extends StatelessWidget {
  const new(this._label, {super.key});

  /// The word the page's title, text and button carry.
  final String _label;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('$_label title')),
    body: Column(
      children: [
        Text('$_label text'),
        ElevatedButton(onPressed: null, child: Text('$_label button')),
      ],
    ),
  );
}
