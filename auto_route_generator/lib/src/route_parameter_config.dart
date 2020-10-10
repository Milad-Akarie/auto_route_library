import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route_generator/import_resolver.dart';
import 'package:source_gen/source_gen.dart';

final pathParamChecker = TypeChecker.fromRuntime(PathParam);
final queryParamChecker = TypeChecker.fromRuntime(QueryParam);

/// holds constructor parameter info to be used
/// in generating route parameters.
class RouteParamConfig {
  final String type;
  final String name;
  final String alias;
  final bool isPositional;
  final bool isRequired;
  final bool isPathParam;
  final bool isQueryParam;
  final String defaultValueCode;
  final Set<String> imports;

  RouteParamConfig({
    this.type,
    this.name,
    this.alias,
    this.isPositional,
    this.isRequired,
    this.isPathParam,
    this.isQueryParam,
    this.defaultValueCode,
    this.imports,
  });

  String get getterName {
    switch (type) {
      case 'String':
        return 'stringValue';
      case 'int':
        return 'intValue';
      case 'double':
        return 'doubleValue';
      case 'num':
        return 'numValue';
      case 'bool':
        return 'boolValue';
      default:
        return 'value';
    }
  }

  String get paramName => alias ?? name;
}

class RouteParameterResolver {
  final ImportResolver _importResolver;
  final Set<String> imports = {};

  RouteParameterResolver(this._importResolver);

  Future<RouteParamConfig> resolve(ParameterElement parameterElement) async {
    final paramType = parameterElement.type;

    var pathParam = pathParamChecker.hasAnnotationOfExact(parameterElement);
    var paramAlias;
    if (pathParam) {
      paramAlias = pathParamChecker
          .firstAnnotationOf(parameterElement)
          .getField('name')
          ?.toStringValue();
    }
    var isQuery = queryParamChecker.hasAnnotationOfExact(parameterElement);
    if (isQuery) {
      paramAlias = queryParamChecker
          .firstAnnotationOf(parameterElement)
          .getField('name')
          ?.toStringValue();
    }

    return RouteParamConfig(
        type: paramType.getDisplayString(withNullability: false),
        name: parameterElement.name.replaceFirst("_", ''),
        alias: paramAlias,
        isPositional: parameterElement.isPositional,
        isRequired: parameterElement.hasRequired,
        isPathParam: pathParam,
        isQueryParam: isQuery,
        defaultValueCode: parameterElement.defaultValueCode,
        imports: _importResolver.resolveAll(paramType));
  }
}
