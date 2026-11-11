import 'package:code_builder/code_builder.dart';

/// The Dart source [spec] writes when [emitter] emits it.
///
/// [Spec.accept] hands back a [StringSink], whose own `toString` says nothing
/// about the code. The buffer it writes to does.
String emitSource(Spec spec, DartEmitter emitter) {
  final buffer = StringBuffer();
  spec.accept(emitter, buffer);
  return buffer.toString();
}
