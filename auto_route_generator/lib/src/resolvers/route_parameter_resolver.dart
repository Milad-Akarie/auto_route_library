import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
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
    var paramName = parameterElement.name ?? '';
    if (paramName.startsWith('_')) {
      paramName = paramName.replaceFirst("_", '');
    }
    var pathParamAnnotation = _pathParamChecker.firstAnnotationOfExact(parameterElement);
    var queryParamAnnotation = _queryParamChecker.firstAnnotationOfExact(parameterElement);

    var nameOrAlias = paramName;
    var isInheritedPathParam = false;
    final isUrlFragment = _urlFragmentChecker.hasAnnotationOfExact(parameterElement);

    // A value parsed from the url is parsed by the type a typedef stands for.
    final isParsedFromUrl = pathParamAnnotation != null || queryParamAnnotation != null || isUrlFragment;
    var type = _typeResolver.resolveType(paramType, skipAlias: isParsedFromUrl);

    if (pathParamAnnotation != null) {
      isInheritedPathParam = pathParamAnnotation.getField('_inherited')?.toBoolValue() == true;
      final paramAlias = pathParamAnnotation.getField('name')?.toStringValue();
      if (paramAlias != null) {
        nameOrAlias = paramAlias;
      }
    }
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

    final isUrlParam = pathParamAnnotation != null || queryParamAnnotation != null;
    if (isUrlParam && type.name == 'List' && type.typeArguments.length == 1) {
      final item = type.typeArguments.single;
      final isText = const {'String', 'Object', 'dynamic'}.contains(item.name);
      // Only a query param converts its items.
      final isConverted =
          queryParamAnnotation != null && (const {'int', 'double', 'num', 'bool'}.contains(item.name) || item.isEnum);
      final kind = queryParamAnnotation != null ? 'query' : 'path';
      throwIf(
        !isText && !isConverted,
        '${parameterElement.displayName}: a List $kind param can hold '
        '${queryParamAnnotation != null ? 'String, int, double, num, bool or enum' : 'String'} items, not ${item.name}',
        element: parameterElement,
      );
    }

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
      defaultValueImport: _resolveDefaultValueImport(parameterElement),
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
        defaultValueImport: _resolveDefaultValueImport(paramElement),
        isRequired: paramElement.isRequiredNamed,
        isPositional: paramElement.isPositional,
        hasRequired: paramElement.isRequired,
        isOptional: paramElement.isOptional,
        isNamed: paramElement.isNamed);
  }

  /// Resolves the import of the declaration a default value names: a
  /// top-level function or constant such as `defaultTitleResolver`, or the
  /// class or enum in `Colors.red`. Returns `null` for any other value.
  String? _resolveDefaultValueImport(FormalParameterElement parameterElement) {
    final initializer = parameterElement.constantInitializer;
    final element = switch (initializer) {
      SimpleIdentifier() => initializer.element,
      PrefixedIdentifier() => initializer.prefix.element,
      _ => null,
    };
    if (element == null || element.enclosingElement is! LibraryElement) return null;
    return _typeResolver.resolveImport(element);
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
