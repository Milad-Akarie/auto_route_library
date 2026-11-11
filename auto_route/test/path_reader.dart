import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';

/// Shows 'Home' and, each time its dependencies change, adds the current
/// path and url of the router it watches to [reads], as
/// `'<currentPath> <currentUrl>'`.
class PathReader extends StatefulWidget {
  /// Records into [reads].
  const new(this.reads, {super.key});

  /// The reads so far, oldest first.
  final List<String> reads;

  @override
  State<PathReader> createState() => _PathReaderState();
}

class _PathReaderState extends State<PathReader> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = context.watchRouter;
    widget.reads.add('${router.currentPath} ${router.currentUrl}');
  }

  @override
  Widget build(BuildContext context) => const Text('Home');
}
