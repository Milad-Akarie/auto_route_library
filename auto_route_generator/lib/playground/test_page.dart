import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/src/models/resolved_type.dart';

@RoutePage()
class TestPage {
  final String param1;
  final ResolvedType param2;

  TestPage({
    required this.param1,
    required this.param2,
  });
}
