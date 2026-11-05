import 'package:material_ui/material_ui.dart';

/// A page that shows [name], for tests that only need a page to land on.
class NamedPage extends StatelessWidget {
  const NamedPage(this.name, {super.key});

  /// The text the page shows.
  final String name;

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(name));
}
