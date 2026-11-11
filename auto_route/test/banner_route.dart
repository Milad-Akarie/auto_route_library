import 'package:material_ui/material_ui.dart';

/// A route that is not modal: it shows a 'Banner' text at the top of the
/// screen and leaves the rest of the screen to the page under it, as a
/// Flushbar does.
class BannerRoute extends OverlayRoute<void> {
  @override
  Iterable<OverlayEntry> createOverlayEntries() => [
    OverlayEntry(
      builder: (_) => const Align(
        alignment: Alignment.topCenter,
        child: SizedBox(height: 100, child: Text('Banner')),
      ),
    ),
  ];
}
