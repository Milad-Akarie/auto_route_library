import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// An [AutoRouter] under a [HeroControllerScope] of its own, so Heroes fly
/// between its pages.
class HeroScopedRouter extends StatefulWidget {
  const new({super.key});

  @override
  State<HeroScopedRouter> createState() => _HeroScopedRouterState();
}

class _HeroScopedRouterState extends State<HeroScopedRouter> {
  final _controller = HeroController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      HeroControllerScope(controller: _controller, child: const AutoRouter());
}
