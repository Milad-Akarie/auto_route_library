import 'package:material_ui/material_ui.dart';

/// A page that shows the name in its center, for tests that only need a page to land on.
class CenteredNamedPage extends StatelessWidget {
  const new(this._name, {super.key});

  /// The text the page shows.
  final String _name;

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(_name)));
}
