import 'auto_router_builder_base.dart';

class AutoRouterModuleBuilder extends AutoRouterBuilderBase {
  AutoRouterModuleBuilder({super.options})
      : super(
          // gm stands for generated module
          generatedExtension: '.gm.dart',
          allowSyntaxErrors: true,
          annotationName: 'AutoRouterConfig.module',
        );
}
