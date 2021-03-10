import 'package:flutter/material.dart';

import '../../auto_route.dart';

class StackEntryScope extends InheritedWidget {
  final StackEntryItem entry;

  StackEntryScope({required this.entry, required Widget child}) : super(child: child);

  static StackEntryItem? of(BuildContext context) {
    var scope = context.dependOnInheritedWidgetOfExactType<StackEntryScope>();
    assert(scope != null);
    return scope?.entry;
  }

  @override
  bool updateShouldNotify(covariant StackEntryScope oldWidget) {
    return entry != oldWidget.entry;
  }
}
