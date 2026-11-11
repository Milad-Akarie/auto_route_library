import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// Shows the url of a router, rebuilt by an [AnimatedBuilder] that listens to
/// the router, with the key 'title'.
class UrlTitle extends StatelessWidget {
  const new(this._router, {super.key});

  /// The router whose url is shown, and listened to.
  final RoutingController _router;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _router,
    builder: (_, _) => Text(_router.currentUrl, key: const Key('title')),
  );
}
