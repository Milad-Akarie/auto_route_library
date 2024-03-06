import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/src/models/resolved_type.dart';

import 'model.dart';

@RoutePage()
class TestPage {
  final String param1;
  final ResolvedType param2;
  final Generice<int> generice;

  TestPage(
    this.param1, {
    required String x,
    required this.param2,
    required this.generice,
  });
}
