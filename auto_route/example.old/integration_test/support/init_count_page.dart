import 'package:material_ui/material_ui.dart';

/// A page that shows 'Home' and calls [onInit] from its initState, so a test
/// counts how often the page is built anew.
class InitCountPage extends StatefulWidget {
  /// Calls [onInit] once per state.
  const new(this.onInit, {super.key});

  /// Called from initState.
  final VoidCallback onInit;

  @override
  State<InitCountPage> createState() => _InitCountPageState();
}

class _InitCountPageState extends State<InitCountPage> {
  @override
  void initState() {
    super.initState();
    widget.onInit();
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Text('Home'));
}
