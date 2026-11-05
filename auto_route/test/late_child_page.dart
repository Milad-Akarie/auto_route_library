import 'dart:async';

import 'package:material_ui/material_ui.dart';

/// A page showing 'Screen B' that adds a 'New Child' text 3 seconds after it
/// starts, rebuilding itself wherever it then is.
class LateChildPage extends StatefulWidget {
  const new({super.key});

  @override
  State<LateChildPage> createState() => _LateChildPageState();
}

class _LateChildPageState extends State<LateChildPage> {
  Timer? _timer;
  var _isNewChildShown = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(
      const Duration(seconds: 3),
      () => setState(() => _isNewChildShown = true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        const Text('Screen B'),
        if (_isNewChildShown) const Text('New Child'),
      ],
    ),
  );
}
