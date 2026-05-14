import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:auto_route/annotations.dart';
import 'package:source_gen/source_gen.dart';

import '../../build_utils.dart';
import '../models/resolved_type.dart';
import 'type_resolver.dart';

final _converterChecker = TypeChecker.typeNamed(ParamConverter, inPackage: 'auto_route');

/// resolved info about the `converter:` argument on a `@PathParam` /
/// `@QueryParam`, or about an auto-detected enum type
class ConverterInfo {
  /// name of the top-level const variable referenced from the annotation
  /// (e.g. `dateConverter`); null when [isEnumAuto] is true
  final String? variableName;

  /// package URI of the library declaring [variableName]
  /// (e.g. `package:my_app/converters.dart`); null when [isEnumAuto] is true
  final String? import;

  /// true when synthesised by the generator for an enum-typed parameter
  /// without an explicit converter
  final bool isEnumAuto;

  /// the converted type `T`; used to emit the type argument on
  /// `getTyped<T>` / `optTyped<T>` calls
  final ResolvedType convertedType;

  /// default const constructor
  const ConverterInfo({
    required this.convertedType,
    this.variableName,
    this.import,
    this.isEnumAuto = false,
  });

  /// serializes to JSON for the build cache
  Map<String, dynamic> toJson() => {
        'variableName': variableName,
        'import': import,
        'isEnumAuto': isEnumAuto,
        'convertedType': convertedType.toJson(),
      };

  /// deserializes from JSON
  factory ConverterInfo.fromJson(Map<String, dynamic> map) => ConverterInfo(
        variableName: map['variableName'] as String?,
        import: map['import'] as String?,
        isEnumAuto: map['isEnumAuto'] as bool? ?? false,
        convertedType: ResolvedType.fromJson(map['convertedType']),
      );
}

/// resolves the `converter:` annotation field, or auto-detects an
/// enum-typed parameter
///
/// returns null when neither applies; throws [InvalidGenerationSourceError]
/// with an actionable message for invalid usage
ConverterInfo? resolveConverter({
  required DartObject? converterObject,
  required Element parameterElement,
  required ResolvedType parameterType,
  required DartType rawParamType,
  required TypeResolver typeResolver,
}) {
  if (converterObject != null && !converterObject.isNull) {
    return _resolveExplicitConverter(
      converterObject: converterObject,
      parameterElement: parameterElement,
      parameterType: parameterType,
      typeResolver: typeResolver,
    );
  }

  // no explicit converter; auto-detect enum types
  final element = rawParamType is InterfaceType ? rawParamType.element : null;
  if (element is EnumElement) {
    return ConverterInfo(
      convertedType: parameterType,
      isEnumAuto: true,
    );
  }
  return null;
}

ConverterInfo _resolveExplicitConverter({
  required DartObject converterObject,
  required Element parameterElement,
  required ResolvedType parameterType,
  required TypeResolver typeResolver,
}) {
  final objectType = converterObject.type;
  throwIf(
    objectType == null || !_converterChecker.isAssignableFromType(objectType),
    'The converter on [${parameterElement.displayName}] must implement '
    'ParamConverter<T>. '
    'Got: ${objectType?.getDisplayString() ?? 'unknown'}.',
    element: parameterElement,
  );

  final variable = converterObject.variable;
  throwIf(
    variable == null,
    'The converter on [${parameterElement.displayName}] must be a '
    'top-level const variable, not an inline const expression. '
    'Declare it once, e.g.\n'
    '  const myConverter = MyConverter();\n'
    'and reference it from the annotation:\n'
    '  @QueryParam(\'name\', myConverter)',
    element: parameterElement,
  );

  // confirm the converter's ParamConverter<T> type arg matches the
  // parameter's declared type
  final tArg = _extractConvertedType(objectType!);
  if (tArg != null) {
    final argDisplay = tArg.getDisplayString();
    final paramDisplay = parameterType.name;
    throwIf(
      argDisplay != paramDisplay && '$argDisplay?' != paramDisplay,
      'The converter on [${parameterElement.displayName}] handles '
      'type [$argDisplay] but the parameter is declared as '
      '[$paramDisplay].',
      element: parameterElement,
    );
  }

  // prefer the standard import resolver; fall back to the variable's declaring
  // library URI for top-level consts in the same source asset
  final import = typeResolver.resolveImport(variable) ?? variable!.library?.uri.toString();
  throwIf(
    import == null,
    'Could not resolve the import for converter '
    '[${variable!.displayName}] used on '
    '[${parameterElement.displayName}].',
    element: parameterElement,
  );

  return ConverterInfo(
    convertedType: parameterType,
    variableName: variable.displayName,
    import: import,
  );
}

/// walks [objectType]'s supertypes to find `ParamConverter<T>` and returns
/// `T`, or null if undetermined
DartType? _extractConvertedType(DartType objectType) {
  if (objectType is! InterfaceType) return null;
  for (final supertype in [objectType, ...objectType.allSupertypes]) {
    if (_converterChecker.isExactlyType(supertype) && supertype.typeArguments.isNotEmpty) {
      return supertype.typeArguments.first;
    }
  }
  return null;
}
