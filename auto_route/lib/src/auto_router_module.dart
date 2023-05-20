import 'package:auto_route/auto_route.dart';

/// Module initializers will implement this class
/// to be later used in the root router.
abstract class AutoRouterModule {
  /// The map holding the page names and their factories.
  Map<String, PageFactory> get pagesMap;
}
