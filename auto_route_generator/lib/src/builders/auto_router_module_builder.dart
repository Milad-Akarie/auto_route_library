import 'auto_router_builder_base.dart';

class AutoRouterModuleBuilder extends AutoRouterBuilderBase {
  AutoRouterModuleBuilder({super.options})
      : super(
          generatedExtension: '.module.dart',
          allowSyntaxErrors: true,
          annotationName: 'AutoRouterConfig.module',
        );
}
