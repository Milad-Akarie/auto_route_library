import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/router_class_generator.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

const routesMapChecker = TypeChecker.fromRuntime(RoutesList);
const autoRouteChecker = TypeChecker.fromRuntime(AutoRoute);

class AutoRouteGenerator extends GeneratorForAnnotation<AutoRouter> {
  @override
  dynamic generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    // throw if annotation is used for a none class element
    throwIf(
      element is! ClassElement,
      '${element.name} is not a class element',
      element: element,
    );

    // ensure router config classes are prefixed with $
    // to use the stripped name for the generated class
//    throwIf(
//      !element.displayName.startsWith(r'$'),
//      'Class name must be prefixed with \$',
//      element: element,
//    );

    final autoRoutes = (element as ClassElement).fields.firstWhere((field) => routesMapChecker.hasAnnotationOfExact(field), orElse: () {
      throwError('Can not find a routes list. Did you forget to annotate your routesList with @RoutesList()?', element: element);
      return null;
    });

//    throwIf(
//      autoRoutes.type.toString() != 'List<AutoRoute>' || !autoRoutes.isConst || !autoRoutes.isStatic,
//      'Routes list must be a static const List<AutoRoute>',
//      element: autoRoutes,
//    );

    final routerClassName = '\$${element.displayName}';

    final routerConfig = RouterConfig.fromAnnotation(annotation);

//    final routes = <RouteConfig>[];
    final routerResolver = RouterConfigResolver(
      routerConfig.globalRouteConfig,
      getResolver(buildStep),
    );
    final annotatedMap = AnnotatedElement(ConstantReader(routesMapChecker.firstAnnotationOf(autoRoutes)), autoRoutes);
    final routesConfig = RoutesConfig.fromAnnotatedElement(annotatedMap);

    final routesReader = ConstantReader(autoRoutes.computeConstantValue());
    final routeConfigs = await _resolveRoutes(
      routerResolver,
      routesReader.listValue,
      namePrefix: routesConfig.routeNamePrefix,
    );

    return RouterClassGenerator(routerClassName, routeConfigs, routerConfig, routesConfig).generate();
  }

  Future<List<RouteConfig>> _resolveRoutes(
    RouterConfigResolver routerResolver,
    List<DartObject> routesList, {
    String namePrefix,
  }) async {
    final routes = <RouteConfig>[];
    for (var entry in routesList) {
      var routeReader = ConstantReader(entry);
      RouteConfig routeConfig;
      routeConfig = await routerResolver.resolve(routeReader, namePrefix);
      routes.add(routeConfig);
      var children = routeReader.peek('children')?.listValue;
      if (children != null) {
        routes.addAll(
          await _resolveRoutes(routerResolver, children, namePrefix: routeConfig.pathName),
        );
      }
    }
    return routes;
  }

  Resolver getResolver(BuildStep buildStep) => buildStep.resolver;
}
