import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/src/models/route_parameter_config.dart';
import 'package:auto_route_generator/src/resolvers/type_resolver.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

final _pathParamChecker = TypeChecker.fromRuntime(PathParam);
final _queryParamChecker = TypeChecker.fromRuntime(QueryParam);

class RouteParameterResolver {
  final TypeResolver _typeResolver;

  RouteParameterResolver(this._typeResolver);

  ParamConfig resolve(ParameterElement parameterElement) {
    final paramType = parameterElement.type;
    if (paramType is FunctionType) {
      return _resolveFunctionType(parameterElement);
    }
    var type = _typeResolver.resolveType(paramType);
    var pathParamAnnotation =
        _pathParamChecker.firstAnnotationOfExact(parameterElement);
    var paramAlias;
    if (pathParamAnnotation != null) {
      paramAlias = pathParamAnnotation.getField('name')?.toStringValue();
    }
    var queryParamAnnotation =
        _queryParamChecker.firstAnnotationOfExact(parameterElement);
    if (queryParamAnnotation != null) {
      paramAlias = queryParamAnnotation.getField('name')?.toStringValue();

      throwIf(
        !type.isNullable && !parameterElement.hasDefaultValue,
        'QueryParams must be nullable or have default value',
        element: parameterElement,
      );
    }

    throwIf(
      pathParamAnnotation != null && queryParamAnnotation != null,
      '${parameterElement.name} can not be both a pathParam and a queryParam!',
      element: parameterElement,
    );

    return ParamConfig(
      type: type,
      element: parameterElement,
      name: parameterElement.name.replaceFirst("_", ''),
      alias: paramAlias,
      isPositional: parameterElement.isPositional,
      hasRequired: parameterElement.hasRequired,
      isRequired: parameterElement.isRequiredNamed,
      isOptional: parameterElement.isOptional,
      isNamed: parameterElement.isNamed,
      isPathParam: pathParamAnnotation != null,
      isQueryParam: queryParamAnnotation != null,
      defaultValueCode: parameterElement.defaultValueCode,
    );
  }

  ParamConfig _resolveFunctionType(ParameterElement paramElement) {
    var type = paramElement.type as FunctionType;
    return FunctionParamConfig(
        returnType: _typeResolver.resolveType(type.returnType),
        type: _typeResolver.resolveType(type),
        params: type.parameters.map(resolve).toList(),
        element: paramElement,
        name: paramElement.name,
        defaultValueCode: paramElement.defaultValueCode,
        isRequired: paramElement.isRequiredNamed,
        isPositional: paramElement.isPositional,
        hasRequired: paramElement.hasRequired,
        isOptional: paramElement.isOptional,
        isNamed: paramElement.isNamed);
  }

  static List<PathParamConfig> extractPathParams(String path) {
    return RegExp(r':([^/]+)').allMatches(path).map((m) {
      var paramName = m.group(1);
      var isOptional = false;
      if (paramName!.endsWith('?')) {
        isOptional = true;
        paramName = paramName.substring(0, paramName.length - 1);
      }
      return PathParamConfig(
        name: paramName,
        isOptional: isOptional,
      );
    }).toList();
  }
}
