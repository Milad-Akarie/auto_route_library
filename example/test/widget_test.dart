// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:auto_route/auto_route.dart';
import 'package:flutter/widgets.dart';

void main() {
//	var template = '/users/:id/role/:title';
//	var url = '/users/4/role/admin';
   print(_buildPathPattern("/users/:id"));
}

Pattern _buildPathPattern(String template) {
  return '^${template.replaceAllMapped(RegExp(r':([^/]+)|([*])'), (m) {
    print(m.group(0));
    return '(?<${m.group(1)}>[^/]+)';
  })}';
}