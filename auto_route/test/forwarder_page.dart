import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// A page that pushes [forwardTo] from its initState, as in #729, and shows a
/// 'Next' button that pushes [next].
class ForwarderPage extends StatefulWidget {
  /// Pushes [forwardTo] once built; 'Next' pushes [next].
  const new({required this.forwardTo, required this.next, super.key});

  /// The route pushed from initState.
  final PageRouteInfo forwardTo;

  /// The route the 'Next' button pushes.
  final PageRouteInfo next;

  @override
  State<ForwarderPage> createState() => _ForwarderPageState();
}

class _ForwarderPageState extends State<ForwarderPage> {
  @override
  void initState() {
    super.initState();
    unawaited(context.router.push(widget.forwardTo));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: TextButton(
      onPressed: () => unawaited(context.router.push(widget.next)),
      child: const Text('Next'),
    ),
  );
}
