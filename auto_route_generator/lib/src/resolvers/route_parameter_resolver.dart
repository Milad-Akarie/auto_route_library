import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_route/annotations.dart';

import 'package:auto_route_generator/src/models/route_parameter_config.dart';
import 'package:auto_route_generator/src/resolvers/type_resolver.dart';
import 'package:source_gen/source_gen.dart';

import '../../build_utils.dart';

final _pathParamChecker = TypeChecker.typeNamed(PathParam, inPackage: 'auto_route');
final _queryParamChecker = TypeChecker.typeNamed(QueryParam, inPackage: 'auto_route');
final _urlFragmentChecker = TypeChecker.typeNamed(UrlFragment, inPackage: 'auto_route');

/// Resolves route parameters
class RouteParameterResolver {
  final TypeResolver _typeResolver;

  /// Default constructor
  RouteParameterResolver(this._typeResolver);

  /// Resolves a ParameterElement into a consumable [ParamConfig]
  ParamConfig resolve(FormalParameterElement parameterElement) {
    final paramType = parameterElement.type;
    if (paramType is FunctionType && paramType.alias == null) {
      return _resolveFunctionType(parameterElement);
    }
    var type = _typeResolver.resolveType(paramType);
    final paramName = parameterElement.displayName.replaceFirst("_", '');
    var pathParamAnnotation = _pathParamChecker.firstAnnotationOfExact(parameterElement);

    var nameOrAlias = paramName;
    var isInheritedPathParam = false;
    final isUrlFragment = _urlFragmentChecker.hasAnnotationOfExact(parameterElement);

    if (pathParamAnnotation != null) {
      isInheritedPathParam = pathParamAnnotation.getField('_inherited')?.toBoolValue() == true;
      final paramAlias = pathParamAnnotation.getField('name')?.toStringValue();
      if (paramAlias != null) {
        nameOrAlias = paramAlias;
      }
    }
    var queryParamAnnotation = _queryParamChecker.firstAnnotationOfExact(parameterElement);
    if (queryParamAnnotation != null) {
      final paramAlias = queryParamAnnotation.getField('name')?.toStringValue();
      if (paramAlias != null) {
        nameOrAlias = paramAlias;
      }
      throwIf(
        !type.isNullable && !parameterElement.hasDefaultValue,
        'QueryParams must be nullable or have default value',
        element: parameterElement,
      );
    }

    throwIf(
      [isUrlFragment, pathParamAnnotation != null, queryParamAnnotation != null].where((e) => e).length > 1,
      '${parameterElement.displayName} can only be annotated with one of @PathParam, @QueryParam or @urlFragment',
      element: parameterElement,
    );

    if (isUrlFragment) {
      throwIf(
        type.name != 'String',
        'UrlFragments must be of type String',
        element: parameterElement,
      );
      throwIf(
        !type.isNullable && !parameterElement.hasDefaultValue,
        'UrlFragments must be nullable or have default value',
        element: parameterElement,
      );
    }

    return ParamConfig(
      type: type,
      name: paramName,
      alias: nameOrAlias,
      isPositional: parameterElement.isPositional,
      hasRequired: parameterElement.isRequired,
      isRequired: parameterElement.isRequiredNamed,
      isOptional: parameterElement.isOptional,
      isNamed: parameterElement.isNamed,
      isPathParam: pathParamAnnotation != null,
      isInheritedPathParam: isInheritedPathParam,
      isQueryParam: queryParamAnnotation != null,
      isUrlFragment: isUrlFragment,
      defaultValueCode: parameterElement.defaultValueCode,
    );
  }

  ParamConfig _resolveFunctionType(FormalParameterElement paramElement) {
    var type = paramElement.type as FunctionType;
    return FunctionParamConfig(
        returnType: _typeResolver.resolveType(type.returnType),
        type: _typeResolver.resolveType(type),
        params: type.formalParameters.map(resolve).toList(),
        name: paramElement.displayName,
        defaultValueCode: paramElement.defaultValueCode,
        isRequired: paramElement.isRequiredNamed,
        isPositional: paramElement.isPositional,
        hasRequired: paramElement.isRequired,
        isOptional: paramElement.isOptional,
        isNamed: paramElement.isNamed);
  }

  /// Extracts path parameters from a route path
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
