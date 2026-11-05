import 'package:material_ui/material_ui.dart';

/// A page whose Hero holds [label], with the tag every page using it shares.
class HeroLabelPage extends StatelessWidget {
  const new(this.label, {super.key});

  /// The text inside the Hero.
  final String label;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Hero(tag: 'hero', child: Text(label)),
    ),
  );
}
