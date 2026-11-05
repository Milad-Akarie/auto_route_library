import 'package:build/build.dart';

/// The output a builder with one output writes.
extension BuildStepPrimaryOutput on BuildStep {
  /// The first of [BuildStep.allowedOutputs], failing with a message that
  /// names the input when the builder has none.
  AssetId get primaryOutput =>
      allowedOutputs.firstOrNull ??
      (throw StateError('${inputId.path} has no allowed output to write.'));
}
