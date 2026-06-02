/// contract for converting between URL parameter strings and typed values
///
/// implementations must have a `const` constructor so an instance can be
/// passed as an annotation argument, e.g. `@QueryParam('date', dateConverter)`
///
/// declare a top-level `const` variable for the converter and reference it
/// from the annotation:
///
/// ```dart
/// class DateConverter extends ParamConverter<DateTime> {
///   const DateConverter();
///
///   @override
///   DateTime fromParam(String? value) => DateTime.parse(value!);
///
///   @override
///   String toParam(DateTime value) =>
///       '${value.year}-${value.month}-${value.day}';
/// }
///
/// const dateConverter = DateConverter();
///
/// @RoutePage()
/// class EventPage extends StatelessWidget {
///   const EventPage({
///     @QueryParam('date', dateConverter) required this.date,
///   });
///   final DateTime date;
/// }
/// ```
///
/// for [Enum] types the generator auto-injects [EnumParamConverter], so
/// no explicit converter is required on the annotation
abstract class ParamConverter<T> {
  const ParamConverter();

  /// converts a raw URL string [value] (or `null` when absent) into a value
  /// of type [T]
  ///
  /// implementations should throw if [value] is non-null but cannot be parsed;
  /// [Parameters.optTyped] catches such exceptions and falls back to the default
  T fromParam(String? value);

  /// converts [value] into the URL string emitted by the generator when a
  /// route is constructed programmatically (e.g. `MyRoute(date: ...)`)
  ///
  /// should be the inverse of [fromParam]; returning `null` drops the param
  /// from query strings and substitutes empty in path segments
  String? toParam(T value);
}

/// built-in [ParamConverter] for any [Enum] type
///
/// the generator emits `const EnumParamConverter<Foo>(Foo.values)`
/// automatically when it sees `@PathParam` / `@QueryParam` on an enum-typed
/// parameter, so users rarely use this class directly
///
/// matching is by [Enum.name] (case-sensitive); throws [StateError] when no
/// value matches
class EnumParamConverter<T extends Enum> extends ParamConverter<T> {
  /// full list of enum values for [T]; pass `Foo.values`
  final List<T> values;

  const EnumParamConverter(this.values) : super();

  /// shared name -> value lookup, keyed by [values] identity so different
  /// lists (subsets, hot-reloaded `Foo.values`) get their own entries
  static final Map<List<Enum>, Map<String, Enum>> _byName = Map.identity();

  @override
  T fromParam(String? value) {
    final lookup = _byName.putIfAbsent(
      values,
      () => {for (final v in values) v.name: v},
    );
    final hit = lookup[value];
    if (hit == null) {
      throw StateError('No element');
    }
    return hit as T;
  }

  @override
  String toParam(T value) => value.name;
}
