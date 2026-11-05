import 'package:material_ui/material_ui.dart';

/// A page with a small Hero holding [name], placed at [alignment].
class HeroBoxPage extends StatelessWidget {
  const HeroBoxPage(this.name, this.alignment, {super.key});

  /// The text inside the Hero.
  final String name;

  /// Where the Hero sits on the page.
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Align(
      alignment: alignment,
      child: Hero(
        tag: 'box',
        child: SizedBox(width: 50, height: 50, child: Text(name)),
      ),
    ),
  );
}
