import 'package:material_ui/material_ui.dart';

/// A page with a small Hero holding the name, placed at the alignment.
class HeroBoxPage extends StatelessWidget {
  const new(this._name, this._alignment, {super.key});

  /// The text inside the Hero.
  final String _name;

  /// Where the Hero sits on the page.
  final Alignment _alignment;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Align(
      alignment: _alignment,
      child: Hero(
        tag: 'box',
        child: SizedBox(width: 50, height: 50, child: Text(_name)),
      ),
    ),
  );
}
