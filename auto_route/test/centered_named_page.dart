import 'package:material_ui/material_ui.dart';

/// A page that shows [name] in its center, for tests that only need a page to land on.
class CenteredNamedPage extends StatelessWidget {
  const CenteredNamedPage(this.name, {super.key});

  /// The text the page shows.
  final String name;

  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Text(name)));
}
