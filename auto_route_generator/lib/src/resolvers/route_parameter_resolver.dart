import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_route/annotations.dart';
import 'package:auto_route_generator/build_utils.dart';
import 'package:auto_route_generator/src/models/route_parameter_config.dart';
import 'package:auto_route_generator/src/models/url_param_type.dart';
import 'package:auto_route_generator/src/resolvers/type_resolver.dart';
import 'package:source_gen/source_gen.dart';

const _pathParamChecker = TypeChecker.typeNamed(PathParam, inPackage: 'auto_route');
const _queryParamChecker = TypeChecker.typeNamed(QueryParam, inPackage: 'auto_route');
const _urlFragmentChecker = TypeChecker.typeNamed(UrlFragment, inPackage: 'auto_route');

/// Resolves route parameters
class RouteParameterResolver {
  /// Default constructor
  RouteParameterResolver(this._typeResolver);
  final TypeResolver _typeResolver;

  /// Resolves a ParameterElement into a consumable [ParamConfig]
  ParamConfig resolve(FormalParameterElement parameterElement) {
    final paramType = parameterElement.type;
    throwIf(
      _holdsInvalidType(paramType),
      'The type of ${parameterElement.displayName} in ${parameterElement.enclosingElement?.enclosingElement?.displayName} '
      'could not be resolved. '
      'If it is declared in a file another builder generates, make that builder run before auto_route_generator, '
      'with runs_before in its build.yaml or global_options in yours.',
      element: parameterElement,
    );
    if (paramType is FunctionType && paramType.alias == null) {
      return _resolveFunctionType(parameterElement);
    }
    var paramName = parameterElement.name ?? '';
    if (paramName.startsWith('_')) {
      paramName = paramName.replaceFirst('_', '');
    }
    final pathParamAnnotation = _pathParamChecker.firstAnnotationOfExact(parameterElement);
    final queryParamAnnotation = _queryParamChecker.firstAnnotationOfExact(parameterElement);

    var nameOrAlias = paramName;
    var isInheritedPathParam = false;
    final isUrlFragment = _urlFragmentChecker.hasAnnotationOfExact(parameterElement);

    // A value parsed from the url is parsed by the type a typedef stands for.
    final isParsedFromUrl = pathParamAnnotation != null || queryParamAnnotation != null || isUrlFragment;
    final type = _typeResolver.resolveType(paramType, skipAlias: isParsedFromUrl);

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
    if (isUrlParam && urlCollectionTypes.contains(type.name) && type.typeArguments.length == 1) {
      final item = type.typeArguments.single;
      final itemType = UrlParamType.of(item);
      final isText = itemType?.isTextItem ?? false;
      // Only a query param converts its items.
      final isConverted = queryParamAnnotation != null && (itemType?.isListItem ?? false);
      final kind = queryParamAnnotation != null ? 'query' : 'path';
      throwIf(
        !isText && !isConverted,
        '${parameterElement.displayName}: a ${type.name} $kind param can hold '
        '${queryParamAnnotation != null ? 'String, int, double, num, bool or enum' : 'String'} items, not ${item.name}',
        element: parameterElement,
      );
    }

    if (isUrlFragment) {
      throwIf(type.name != 'String', 'UrlFragments must be of type String', element: parameterElement);
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
      defaultValueSymbol: _defaultValueSymbol(parameterElement),
    );
  }

  /// Whether [type] or a type inside it is one the analyzer could not
  /// resolve, such as a class from a generated file that isn't written yet.
  /// Written out, such a type is the undefined name `InvalidType`.
  static bool _holdsInvalidType(DartType type) => switch (type) {
    InvalidType() => true,
    InterfaceType(:final typeArguments) => typeArguments.any(_holdsInvalidType),
    FunctionType(:final returnType, :final formalParameters) =>
      _holdsInvalidType(returnType) || formalParameters.any((p) => _holdsInvalidType(p.type)),
    RecordType(:final positionalFields, :final namedFields) =>
      positionalFields.any((f) => _holdsInvalidType(f.type)) || namedFields.any((f) => _holdsInvalidType(f.type)),
    _ => false,
  };

  ParamConfig _resolveFunctionType(FormalParameterElement paramElement) {
    final type = paramElement.type as FunctionType;
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
      isNamed: paramElement.isNamed,
    );
  }

  /// Resolves the import of the declaration a default value names: a
  /// top-level function or constant such as `defaultTitleResolver`, or the
  /// class or enum in `Colors.red`. In a list or set literal such as
  /// `const [Sort.asc]`, the first such declaration. Returns `null` for any
  /// other value.
  String? _resolveDefaultValueImport(FormalParameterElement parameterElement) {
    final initializer = parameterElement.constantInitializer;
    final element = switch (initializer) {
      SimpleIdentifier() => initializer.element,
      PrefixedIdentifier() => initializer.prefix.element,
      final ListLiteral literal => _firstDeclarationIn(literal),
      final SetOrMapLiteral literal => _firstDeclarationIn(literal),
      _ => null,
    };
    if (element == null || element.enclosingElement is! LibraryElement) return null;
    return _typeResolver.resolveImport(element);
  }

  /// The name of the declaration a list or set default holds, which the
  /// generated code writes with the import's prefix; `null` for any other
  /// default.
  String? _defaultValueSymbol(FormalParameterElement parameterElement) {
    final initializer = parameterElement.constantInitializer;
    if (initializer is! ListLiteral && initializer is! SetOrMapLiteral) return null;
    return _firstDeclarationIn(initializer!)?.name;
  }

  /// The first top-level declaration, such as the enum in `Sort.asc`, that
  /// the collection literal [literal] names, or `null` when it names none.
  Element? _firstDeclarationIn(Expression literal) {
    final finder = _DeclarationFinder();
    literal.accept(finder);
    return finder.found;
  }

  /// Extracts path parameters from a route path
  static List<PathParamConfig> extractPathParams(String path) {
    return RegExp(':([^/]+)').allMatches(path).map((m) {
      var paramName = m.group(1);
      var isOptional = false;
      if (paramName!.endsWith('?')) {
        isOptional = true;
        paramName = paramName.substring(0, paramName.length - 1);
      }
      return PathParamConfig(name: paramName, isOptional: isOptional);
    }).toList();
  }
}

/// Finds the first identifier in an expression that names a top-level
/// declaration.
class _DeclarationFinder extends RecursiveAstVisitor<void> {
  /// The declaration found, or `null`.
  Element? found;

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final element = node.element;
    if (found == null && element != null && element.enclosingElement is LibraryElement) {
      found = element;
    }
  }
}
