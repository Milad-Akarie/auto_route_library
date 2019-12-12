import 'package:auto_route_generator/route_config_visitor.dart';

import 'custom_transtion_builder.dart';

/// holds the extracted route configs
/// to be used in [RouterClassGenerator]

class RouteConfig {
  String name;
  String navigatorName;
  bool initial;
  bool fullscreenDialog;
  bool maintainState;
  String import;
  String className;
  List<RouteParameter> parameters;
  CustomTransitionBuilder transitionBuilder;
  int durationInMilliseconds;

  RouteConfig();

  Map<String, dynamic> toJson() => {
        "className": className,
        "import": import,
        if (navigatorName != null) "navigatorName": navigatorName,
        if (initial != null) "initial": initial,
        if (name != null) "name": name,
        if (transitionBuilder != null) "transitionBuilder": transitionBuilder.toJson(),
        if (durationInMilliseconds != null) "durationInMilliseconds": durationInMilliseconds,
        if (fullscreenDialog != null) "fullscreenDialog": fullscreenDialog,
        if (maintainState != null) "maintainState": maintainState,
        if (parameters != null) "parameters": parameters.map((v) => v.toJson()).toList(),
      };

  RouteConfig.fromJson(Map json) {
    name = json['name'];
    initial = json['initial'];
    className = json['className'];
    navigatorName = json['navigatorName'];
    import = json['import'];
    fullscreenDialog = json['fullscreenDialog'];
    transitionBuilder =
        json["transitionBuilder"] != null ? CustomTransitionBuilder.fromJson(json["transitionBuilder"]) : null;
    durationInMilliseconds = json["durationInMilliseconds"];
    maintainState = json['maintainState'];
    parameters = json['parameters']?.map<RouteParameter>((v) => RouteParameter.fromJson(v))?.toList();
  }

  @override
  String toString() {
    return 'RouteConfig{initial: $initial, navigatorName: $navigatorName, className: $className}';
  }
}
