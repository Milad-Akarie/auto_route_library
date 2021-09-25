import 'package:flutter/material.dart';

import '../../../auto_route.dart';

class AutoBackButton extends StatelessWidget {
  final Color? color;
  final bool showIfParentCanPop;

  const AutoBackButton({
    Key? key,
    this.color,
    this.showIfParentCanPop = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final scope = AutoRouter.of(context, watch: true);
    if (scope.canPopSelfOrChildren ||
        (showIfParentCanPop && scope.parent()?.canPopSelfOrChildren == true)) {
      return BackButton(
        color: color,
        onPressed: () => scope.popTop(AutoBackButtonState.of(context)?.value),
      );
    }
    return const SizedBox.shrink();
  }
}

class AutoBackButtonState extends InheritedWidget {
  final ValueNotifier _state = ValueNotifier(null);

  AutoBackButtonState({
    required Widget child,
  }) : super(child: child);

  set value(dynamic value) => this._state.value = value;
  dynamic get value => _state.value;

  @override
  bool updateShouldNotify(covariant AutoBackButtonState oldWidget) {
    return value != oldWidget.value;
  }

  static AutoBackButtonState? of(BuildContext context, {bool watch = false}) {
    if (watch) {
      return context.dependOnInheritedWidgetOfExactType<AutoBackButtonState>();
    }
    return context.findAncestorWidgetOfExactType<AutoBackButtonState>();
  }
}
