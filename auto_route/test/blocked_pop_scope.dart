import 'package:material_ui/material_ui.dart';

/// A PopScope that blocks every pop and tells [onBlockedPop] about each one it
/// blocked.
class BlockedPopScope extends StatelessWidget {
  const new({required this.onBlockedPop, required this.child, super.key});

  /// Called when a pop was attempted and blocked.
  final VoidCallback onBlockedPop;

  /// The page the scope guards.
  final Widget child;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) onBlockedPop();
    },
    child: child,
  );
}
