import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/src/models/route_parameter_config.dart';
import 'package:lean_builder/builder.dart';
import 'package:lean_builder/element.dart';
import 'package:lean_builder/type.dart';

import '../build_utils.dart';
import 'lean_type_resolver.dart';

/// Resolves route parameters
class LeanRouteParameterResolver {
  final LeanTypeResolver _typeResolver;
  final Resolver _resolver;

  late final _pathParamChecker = _resolver.typeCheckerOf<PathParam>();
  late final _queryParamChecker = _resolver.typeCheckerOf<QueryParam>();
  late final _urlFragmentChecker = _resolver.typeCheckerOf<UrlFragment>();

  /// Default constructor
  LeanRouteParameterResolver(this._resolver, this._typeResolver);

  /// Resolves a ParameterElement into a consumable [ParamConfig]
  ParamConfig resolve(ParameterElement parameterElement) {
    final paramType = parameterElement.type;
    if (paramType is FunctionType) {
      return _resolveFunctionType(parameterElement);
    }
    var type = _typeResolver.resolveType(paramType);
    final paramName = parameterElement.name.replaceFirst("_", '');
    var pathParamObj = _pathParamChecker.firstAnnotationOfExact(parameterElement)?.constant as ConstObject?;

    var nameOrAlias = paramName;
    var isInheritedPathParam = false;
    final isUrlFragment = _urlFragmentChecker.hasAnnotationOfExact(parameterElement);

    if (pathParamObj != null) {
      isInheritedPathParam = pathParamObj.getBool('_inherited')?.value == true;
      final paramAlias = pathParamObj.getString('name')?.value;
      if (paramAlias != null) {
        nameOrAlias = paramAlias;
      }
    }
    var queryParamObj = _queryParamChecker.firstAnnotationOfExact(parameterElement)?.constant as ConstObject?;
    if (queryParamObj != null) {
      final paramAlias = queryParamObj.getString('name')?.value;
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
      [isUrlFragment, pathParamObj != null, queryParamObj != null].where((e) => e).length > 1,
      '${parameterElement.name} can only be annotated with one of @PathParam, @QueryParam or @urlFragment',
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
      hasRequired: parameterElement.hasRequired,
      isRequired: parameterElement.isRequiredNamed,
      isOptional: parameterElement.isOptional,
      isNamed: parameterElement.isNamed,
      isPathParam: pathParamObj != null,
      isInheritedPathParam: isInheritedPathParam,
      isQueryParam: queryParamObj != null,
      isUrlFragment: isUrlFragment,
      defaultValueCode: parameterElement.defaultValueCode,
    );
  }

  ParamConfig _resolveFunctionType(ParameterElement paramElement) {
    var type = paramElement.type as FunctionType;
    return FunctionParamConfig(
        returnType: _typeResolver.resolveType(type.returnType),
        type: _typeResolver.resolveType(type),
        params: type.parameters.map(resolve).toList(),
        name: paramElement.name,
        defaultValueCode: paramElement.defaultValueCode,
        isRequired: paramElement.isRequiredNamed,
        isPositional: paramElement.isPositional,
        hasRequired: paramElement.hasRequired,
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
