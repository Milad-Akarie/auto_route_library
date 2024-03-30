import 'package:analyzer/dart/ast/ast.dart';
import 'package:auto_route_generator/src/models/resolved_type.dart';
import 'package:auto_route_generator/src/models/route_parameter_config.dart';
import 'package:auto_route_generator/utils.dart';

import '../ast_extensions.dart';
import 'ast_type_resolver.dart';

/// Resolves route parameters
class AstParameterResolver {
  final AstTypeResolver _typeResolver;

  /// Default constructor
  AstParameterResolver(this._typeResolver);

  /// Resolves a ParameterElement into a consumable [ParamConfig]
  ParamConfig resolve(TypedParam typedParam) {
    final paramType = typedParam.type;
    if (paramType is GenericFunctionType) {
      return _resolveFunctionType(typedParam);
    }
    final ResolvedType type;
    if (paramType == null && typedParam.isSuper && typedParam.name == 'key') {
      type = ResolvedType(
        name: 'Key',
        import: 'package:flutter/material.dart',
        isNullable: true,
      );
    } else {
      type = _typeResolver.resolveType(paramType);
    }

    final paramName = typedParam.name.replaceFirst("_", '');
    var pathParamAnnotation = typedParam.pathParamAnnotation;

    var nameOrAlias = paramName;
    var isInheritedPathParam = false;
    if (pathParamAnnotation != null) {
      isInheritedPathParam = pathParamAnnotation.getBoolValue('_inherited') ?? false;
      final paramAlias = pathParamAnnotation.getStringValue('name');
      if (paramAlias != null) {
        nameOrAlias = paramAlias;
      }
    }
    var queryParamAnnotation = typedParam.queryParamAnnotation;
    if (queryParamAnnotation != null) {
      final paramAlias = queryParamAnnotation.getStringValue('name');
      if (paramAlias != null) {
        nameOrAlias = paramAlias;
      }
      // throwIf(
      //   !type.isNullable && !typedParam.hasDefaultValue,
      //   'QueryParams must be nullable or have default value',
      // );
    }

    throwIf(
      pathParamAnnotation != null && queryParamAnnotation != null,
      '${typedParam.name} can not be both a pathParam and a queryParam!',
    );

    return ParamConfig(
      type: type,
      name: paramName,
      alias: nameOrAlias,
      isPositional: typedParam.isPositional,
      isRequired: typedParam.isRequiredNamed,
      isOptional: typedParam.isOptional,
      isNamed: typedParam.isNamed,
      isPathParam: pathParamAnnotation != null,
      isInheritedPathParam: isInheritedPathParam,
      isQueryParam: queryParamAnnotation != null,
      defaultValueCode: typedParam.defaultValueCode,
    );
  }

  ParamConfig _resolveFunctionType(TypedParam typedParam) {
    final type = typedParam.type as GenericFunctionType;
    return FunctionParamConfig(
      type: _typeResolver.resolveType(type),
      returnType: _typeResolver.resolveType(type.returnType),
      params: type.parameters.typedParams.map(resolve).toList(),
      name: typedParam.name,
      defaultValueCode: typedParam.defaultValueCode,
      isRequired: typedParam.isRequiredNamed,
      isPositional: typedParam.isPositional,
      isOptional: typedParam.isOptional,
      isNamed: typedParam.isNamed,
    );
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
