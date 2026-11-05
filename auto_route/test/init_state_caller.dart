import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// A page that shows 'Splash' and calls [onInitState] with its router from
/// its initState, while it is being built, as a splash page that leaves
/// itself does (#853).
class InitStateCaller extends StatefulWidget {
  /// Calls [onInitState] once, from initState.
  const new(this.onInitState, {super.key});

  /// Given the router of the page, from initState.
  final void Function(StackRouter router) onInitState;

  @override
  State<InitStateCaller> createState() => _InitStateCallerState();
}

class _InitStateCallerState extends State<InitStateCaller> {
  @override
  void initState() {
    super.initState();
    widget.onInitState(context.router);
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Splash'));
}
