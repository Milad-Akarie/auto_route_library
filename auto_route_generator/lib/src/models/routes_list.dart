import 'package:auto_route_generator/src/models/route_config.dart';

/// A list of [RouteConfig]s
class RoutesList {
  /// Default constructor
  const RoutesList({required this.routes, required this.inputPath, required this.inputHash});

  /// Deserializes this instance from a JSON object.
  factory RoutesList.fromJson(Map<String, dynamic> map) {
    return RoutesList(
      routes: List.unmodifiable((map['routes'] as List<dynamic>).map((e) => RouteConfig.fromJson(e))),
      inputPath: map['inputPath'] as String,
      inputHash: map['inputHash'] as int?,
    );
  }

  /// The list of [RouteConfig]s
  final List<RouteConfig> routes;

  /// The input path
  final String inputPath;

  /// The input hash
  final int? inputHash;

  /// Serializes this instance to a JSON object.
  Map<String, dynamic> toJson() {
    return {
      'routes': List<dynamic>.unmodifiable(routes.map((e) => e.toJson())),
      'inputPath': inputPath,
      'inputHash': inputHash,
    };
  }
}
