import 'package:auto_route_generator/src/models/route_config.dart';

class RoutesList {
  final List<RouteConfig> routes;
  final String inputPath;
  final int? inputHash;

  const RoutesList({
    required this.routes,
    required this.inputPath,
    required this.inputHash,
  });

  Map<String, dynamic> toJson() {
    return {
      'routes': List.unmodifiable(this.routes.map((e) => e.toJson())),
      'inputPath': this.inputPath,
      'inputHash': this.inputHash,
    };
  }

  factory RoutesList.fromJson(Map<String, dynamic> map) {
    return RoutesList(
      routes: List.unmodifiable(
          (map['routes'] as List<dynamic>).map((e) => RouteConfig.fromJson(e))),
      inputPath: map['inputPath'] as String,
      inputHash: map['inputHash'] as int?,
    );
  }
}
