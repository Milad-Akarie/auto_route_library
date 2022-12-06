import 'package:analyzer/dart/element/element.dart' show ClassElement;

import 'route_config.dart';

class RouterConfig {
  final String routerClassName;
  final String? replaceInRouteName;
  final bool deferredLoading;
  final bool usesPartBuilder;
  final String import;

  const RouterConfig({
    required this.routerClassName,
    this.replaceInRouteName,
    this.deferredLoading = false,
    this.usesPartBuilder = false,
    required this.import,
  });

  Map<String, dynamic> toJson() {
    return {
      'routerClassName': this.routerClassName,
      'replaceInRouteName': this.replaceInRouteName,
      'deferredLoading': this.deferredLoading,
      'usesPartBuilder': this.usesPartBuilder,
      'import': this.import,
    };
  }

  factory RouterConfig.fromJson(Map<String, dynamic> map) {
    return RouterConfig(
      routerClassName: map['routerClassName'] as String,
      replaceInRouteName: map['replaceInRouteName'] as String?,
      deferredLoading: map['deferredLoading'] as bool,
      usesPartBuilder: map['usesPartBuilder'] as bool,
      import: map['import'] as String,
    );
  }
}
