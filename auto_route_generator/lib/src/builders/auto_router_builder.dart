import 'auto_router_builder_base.dart';

class AutoRouterBuilder extends AutoRouterBuilderBase {
  AutoRouterBuilder({super.options})
      : super(
          // gr stands for generated router.
          generatedExtension: '.gr.dart',
          allowSyntaxErrors: true,
          annotationName: 'AutoRouterConfig',
        );
}
