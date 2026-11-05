/// Converts a path or query param of type [T] between its text in the url and
/// its value, for a type the url can not give by itself.
///
/// A url param is read as a `String`, `int`, `double`, `num`, `bool` or enum
/// without help. Any other type, such as a value class for ids, takes a
/// converter on its annotation: `@PathParam('id', userIdConverter)` or
/// `@QueryParam('by', userIdConverter)`. The generated route then reads the
/// param with `Parameters.getTyped` or `Parameters.optTyped`, and writes it
/// back into the url with [toParam] when the route is built in code.
///
/// The converter must be a top-level `const` variable, so the generated code
/// can name it; a converter written inside the annotation fails the build.
/// Its [T] must be the param's type, without the `?`.
///
/// ```dart
/// class UserIdConverter extends ParamConverter<UserId> {
///   const UserIdConverter();
///
///   @override
///   UserId? fromParam(String value) => value.isEmpty ? null : UserId(value);
///
///   @override
///   String toParam(UserId value) => value.value;
/// }
///
/// const userIdConverter = UserIdConverter();
///
/// @RoutePage()
/// class UserPage extends StatelessWidget {
///   const UserPage({
///     super.key,
///     @PathParam('id', userIdConverter) required this.id,
///   });
///
///   final UserId id;
///   // ...
/// }
/// ```
///
/// A converter on an enum param replaces the default, which reads and writes
/// the enum by its name.
abstract class ParamConverter<T> {
  /// Lets a subclass be `const`, which an annotation argument must be.
  const new();

  /// Returns the value the url text [value] stands for, or `null` when the
  /// text is not one.
  ///
  /// `null` makes an optional param fall back to its default, or to `null`,
  /// as a number param does for text that isn't a number; a required param
  /// then fails with a `MissingRequiredParameterError` naming the key and the
  /// text. An error thrown here is not caught: it reaches the app as it is.
  ///
  /// Called only when the url has the param, each time the page is built
  /// from the url.
  T? fromParam(String value);

  /// Returns the url text for [value], which [fromParam] must read back as
  /// an equal value, so a link to the page opens it with the same param.
  String toParam(T value);
}
