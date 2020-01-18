import 'package:source_gen/source_gen.dart';

/// Extracts and holds router configs
/// to be used in [RouterClassGenerator]

class RouterConfig {
  bool generateNavigator = true;
  bool generateRouteList = false;

  RouterConfig.fromAnnotation(ConstantReader annotation) {
    if (annotation.peek('generateNavigator') != null) {
      generateNavigator = annotation.peek('generateNavigator').boolValue;
    }

    if (annotation.peek('generateRouteList') != null) {
      generateRouteList = annotation.peek('generateRouteList').boolValue;
    }
  }
}
