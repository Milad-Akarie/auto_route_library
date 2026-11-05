import 'package:auto_route_generator/src/models/resolved_type.dart';
import 'package:code_builder/code_builder.dart';

/// The collections a query param can be, read from its key repeated in the
/// url.
const kUrlCollectionTypes = {'List', 'Set', 'Iterable'};

/// How the generated code reads a path or query param of one type from the
/// url, and writes it back into the url when a route is built in code.
///
/// Every type a url param can have has one entry, which [of] finds; the
/// resolvers ask it what the type allows, and the route builder asks it for
/// the code. A type with no entry is one a url can not give.
sealed class UrlParamType {
  const UrlParamType();

  /// The entry for a param read and written by the `ParamConverter`
  /// constant [name], declared in [import].
  factory UrlParamType.converter(String name, String? import) = _ConverterParam;

  /// The entry for [type], or `null` when a url can not give it.
  static UrlParamType? of(ResolvedType type) {
    if (type.isEnum) return const _EnumParam();
    if (kUrlCollectionTypes.contains(type.name) && type.typeArguments.length == 1) return const _CollectionParam();
    return _byName[type.name];
  }

  static const _byName = <String, UrlParamType>{
    'String': _GetterParam('String', inPath: true),
    'int': _GetterParam('Int', inPath: true, parsesItems: true),
    'double': _GetterParam('Double', inPath: true, parsesItems: true),
    'num': _GetterParam('Num', inPath: true, parsesItems: true),
    'bool': _GetterParam('Bool', inPath: true, parsesItems: true),
    'dynamic': _GetterParam(null, inPath: true),
    'Object': _GetterParam(null),
  };

  /// The names of the types a path segment can give, for build errors.
  static final List<String> pathTypeNames = [
    for (final entry in _byName.entries)
      if (entry.value.inPath) entry.key,
  ];

  /// Whether a path segment can give the type, not only a query param.
  bool get inPath => false;

  /// Whether a `List`, `Set` or `Iterable` query param can hold items of the
  /// type: the url gives each item as text, as it is ([isTextItem]) or for
  /// [parseItem] to convert.
  bool get isListItem => false;

  /// Whether an item of the type is the url's text as it is, so a `List` of
  /// it needs no conversion.
  bool get isTextItem => false;

  /// The code that reads the param [key] of [type] from [params], the
  /// `pathParams` or `queryParams` of the route data, falling back to
  /// [defaultValue] when given.
  Expression read(Expression params, Expression key, ResolvedType type, Expression? defaultValue);

  /// The function that converts the text of one item to [type], for a
  /// [isListItem] type that is not [isTextItem].
  Expression parseItem(ResolvedType type) => throw UnsupportedError('${type.name} items are not parsed');

  /// The code that gives the url's value for [value], a variable of [type].
  Expression write(Expression value, ResolvedType type) => value;
}

/// A type `Parameters` has a pair of readers for, `opt<name>` for a nullable
/// type and `get<name>` for the rest, or `get` alone when [name] is `null`.
final class _GetterParam extends UrlParamType {
  const _GetterParam(this.name, {this.inPath = false, this.parsesItems = false});

  final String? name;

  @override
  final bool inPath;

  /// Whether a list item of the type is parsed from its text.
  final bool parsesItems;

  @override
  bool get isListItem => true;

  @override
  bool get isTextItem => !parsesItems;

  @override
  Expression read(Expression params, Expression key, ResolvedType type, Expression? defaultValue) {
    final name = this.name;
    final method = name == null ? 'get' : '${type.isNullable ? 'opt' : 'get'}$name';
    return params.property(method).call([key, ?defaultValue]);
  }

  @override
  Expression parseItem(ResolvedType type) => switch (type.name) {
    'bool' => const CodeExpression(
      Code("(text) => text.toLowerCase() == 'true' ? true : text.toLowerCase() == 'false' ? false : null"),
    ),
    _ => refer(type.name, type.import).property('tryParse'),
  };
}

/// An enum, read and written by its name.
final class _EnumParam extends UrlParamType {
  const _EnumParam();

  @override
  bool get isListItem => true;

  @override
  Expression read(Expression params, Expression key, ResolvedType type, Expression? defaultValue) {
    final value = _byName(type).index(params.property('optString').call([key]));
    return defaultValue == null ? value : value.ifNullThen(defaultValue);
  }

  @override
  Expression parseItem(ResolvedType type) => Method(
    (b) => b
      ..requiredParameters.add(Parameter((parameterBuilder) => parameterBuilder..name = 'name'))
      ..lambda = true
      ..body = _byName(type).index(refer('name')).code,
  ).closure;

  @override
  Expression write(Expression value, ResolvedType type) =>
      type.isNullable ? value.nullSafeProperty('name') : value.property('name');

  Expression _byName(ResolvedType type) =>
      refer(type.name, type.import).property('values').property('asNameMap').call([]);
}

/// A `List`, `Set` or `Iterable`, read from its key repeated in the url,
/// with each item read by its own type's entry.
final class _CollectionParam extends UrlParamType {
  const _CollectionParam();

  @override
  Expression read(Expression params, Expression key, ResolvedType type, Expression? defaultValue) {
    final item = type.typeArguments.single;
    final itemType = UrlParamType.of(item);
    final parses = itemType != null && itemType.isListItem && !itemType.isTextItem;
    if (type.isList && !parses) {
      // A List of text is what `optList` and `getList` give.
      return params.property(type.isNullable ? 'optList' : 'getList').call([key, ?defaultValue]);
    }
    // `optList` reads the items as text, so each is converted to its type:
    // a number or bool by parsing it, an enum by its name. An item that
    // doesn't convert is left out. A Set is made of the items.
    var value = params.property('optList').call([key]);
    if (parses) {
      final itemRefer = refer(item.name, item.import);
      value = value.nullSafeProperty('map').call([itemType.parseItem(item)]).property('whereType').call([], {}, [
        itemRefer,
      ]);
    }
    if (type.isSet) {
      value = (parses ? value.property('toSet') : value.nullSafeProperty('toSet')).call([]);
    } else if (parses) {
      value = value.property('toList').call([]);
    }
    return defaultValue == null ? value : value.ifNullThen(defaultValue);
  }

  @override
  Expression write(Expression value, ResolvedType type) {
    final item = type.typeArguments.single;
    if (!item.isEnum) return value;
    final name = Method(
      (b) => b
        ..requiredParameters.add(Parameter((parameterBuilder) => parameterBuilder..name = 'item'))
        ..lambda = true
        ..body = UrlParamType.of(item)!.write(refer('item'), item).code,
    ).closure;
    return (type.isNullable ? value.nullSafeProperty('map') : value.property('map'))
        .call([name])
        .property('toList')
        .call([]);
  }
}

/// A param of any type, read and written by a `ParamConverter` constant.
final class _ConverterParam extends UrlParamType {
  const _ConverterParam(this.name, this.import);

  final String name;
  final String? import;

  @override
  bool get inPath => true;

  @override
  Expression read(Expression params, Expression key, ResolvedType type, Expression? defaultValue) {
    // The reader is given the type without its `?`: optTyped gives the `?`.
    final valueType = TypeReference(
      (b) => b
        ..symbol = type.name
        ..url = type.import
        ..types.addAll(type.typeArguments.map((e) => e.refer)),
    );
    return params
        .property(type.isNullable ? 'optTyped' : 'getTyped')
        .call([key, refer(name, import), ?defaultValue], {}, [valueType]);
  }

  @override
  Expression write(Expression value, ResolvedType type) {
    final text = refer(name, import).property('toParam').call([value]);
    return type.isNullable ? value.equalTo(literalNull).conditional(literalNull, text) : text;
  }
}
