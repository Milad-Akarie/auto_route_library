import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

class StackEntryScope extends InheritedWidget {
  final StackEntryItem entry;

  StackEntryScope({this.entry, Widget child}) : super(child: child);

  static StackEntryItem of(BuildContext context) {
    var scope = context.dependOnInheritedWidgetOfExactType<StackEntryScope>();
    assert(scope != null);
    return scope.entry;
  }

  @override
  bool updateShouldNotify(covariant StackEntryScope oldWidget) {
    return entry != oldWidget.entry;
  }
}
