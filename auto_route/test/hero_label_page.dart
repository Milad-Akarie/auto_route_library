import 'package:material_ui/material_ui.dart';

/// A page whose Hero holds the label, with the tag every page using it shares.
class HeroLabelPage extends StatelessWidget {
  const new(this._label, {super.key});

  /// The text inside the Hero.
  final String _label;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Hero(tag: 'hero', child: Text(_label)),
    ),
  );
}
