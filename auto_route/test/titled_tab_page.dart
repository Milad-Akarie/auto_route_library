import 'package:material_ui/material_ui.dart';

import 'no_op.dart';

/// A tab page with a title, a text and a button, each carrying [label].
class TitledTabPage extends StatelessWidget {
  const new(this.label, {super.key});

  /// The word the page's title, text and button carry.
  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('$label title')),
    body: Column(
      children: [
        Text('$label text'),
        ElevatedButton(onPressed: noOp, child: Text('$label button')),
      ],
    ),
  );
}
