import 'package:cupertino_ui/cupertino_ui.dart';

/// A custom error class for missing required parameters
class MissingRequiredParameterError extends FlutterError {
  /// default construct
  MissingRequiredParameterError(String message)
      : super.fromParts(<DiagnosticsNode>[
          ErrorSummary('Missing or invalid required parameter'),
          ErrorDescription(message),
        ]);
}
