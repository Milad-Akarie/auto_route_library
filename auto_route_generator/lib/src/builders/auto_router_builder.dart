import 'auto_router_builder_base.dart';

/// a [Builder] for router generation
class AutoRouterBuilder extends AutoRouterBuilderBase {
  /// Default constructor
  AutoRouterBuilder({super.options})
      : super(
          // gr stands for generated router.
          generatedExtension: '.gr.dart',
          allowSyntaxErrors: true,
          annotationName: 'AutoRouterConfig',
        );
}
