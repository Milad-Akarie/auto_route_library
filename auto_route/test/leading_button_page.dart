import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// A page with an automatic leading button in its app bar, showing [name].
class LeadingButtonPage extends StatelessWidget {
  const new(this.name, {super.key});

  /// The text the page shows.
  final String name;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const AutoLeadingButton()),
    body: Text(name),
  );
}
