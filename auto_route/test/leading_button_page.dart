import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// A page with an automatic leading button in its app bar, showing the name.
class LeadingButtonPage extends StatelessWidget {
  const new(this._name, {super.key});

  /// The text the page shows.
  final String _name;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(leading: const AutoLeadingButton()),
    body: Text(_name),
  );
}
