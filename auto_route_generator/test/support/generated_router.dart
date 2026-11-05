/// What one run of both builders produced.
class GeneratedRouter {
  /// Creates the result of one run.
  const GeneratedRouter(this.source, this.errors, this.compileErrors);

  /// The generated `.gr.dart` source, or `null` when the build wrote none.
  final String? source;

  /// The errors the build reported.
  final List<String> errors;

  /// The analyzer errors in the router library and its generated part, so a
  /// test can check that the generated code compiles.
  final List<String> compileErrors;

  @override
  String toString() => 'build errors: $errors\ncompile errors: $compileErrors\n${source ?? 'no source'}';
}
