import 'package:material_ui/material_ui.dart';

/// A page that shows the name, for tests that only need a page to land on.
class NamedPage extends StatelessWidget {
  const new(this._name, {super.key});

  /// The text the page shows.
  final String _name;

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(_name));
}
