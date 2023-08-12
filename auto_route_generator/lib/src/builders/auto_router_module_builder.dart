import 'auto_router_builder_base.dart';

/// a [Builder] for router module generation
class AutoRouterModuleBuilder extends AutoRouterBuilderBase {
  /// Default constructor
  AutoRouterModuleBuilder({super.options})
      : super(
          // gm stands for generated module
          generatedExtension: '.gm.dart',
          allowSyntaxErrors: true,
          annotationName: 'AutoRouterConfig.module',
        );
}
