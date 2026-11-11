part of 'deferred_widget.dart';

/// Displays a progress indicator when the widget is a deferred component
/// and is currently being installed.
class DeferredLoadingPlaceholder extends StatelessWidget {
  /// default constructor
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
