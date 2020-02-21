import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route_generator/route_config_visitor.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker guardsChecker = TypeChecker.fromRuntime(GuardedBy);
const TypeChecker autoRouteChecker = TypeChecker.fromRuntime(AutoRoute);

// extracts route configs from class fields
class RouterConfigVisitor extends SimpleElementVisitor {
  final routeConfigs = List<RouteConfig>();
  final RouteConfig _globConfig;

  RouterConfigVisitor(this._globConfig);

  @override
  RouteConfig visitFieldElement(FieldElement field) {
    final type = field.type;
    if (type.element is! ClassElement) {
      return null;
    }

    final routeConfig = RouteConfig();
    _extractMetaData(field, routeConfig);

    guardsChecker
        .firstAnnotationOfExact(field)
        ?.getField('guards')
        ?.toListValue()
        ?.map((g) => g.toTypeValue())
        ?.forEach((guard) {
      routeConfig.guards.add(
          RouteGuardConfig(type: guard.name, import: getImport(guard.element)));
    });

    final import = getImport(type.element);

    if (import != null) {
      routeConfig.imports.add(import);
    }
    routeConfig.name = field.name;
    routeConfig.className = type.name;

    final classElement = type.element as ClassElement;
    routeConfig.hasWrapper = classElement.allSupertypes
        .map<String>((el) => el.name)
        .contains('AutoRouteWrapper');
    final constructor = (type.element as ClassElement).unnamedConstructor;
    if (constructor != null && constructor.parameters.isNotEmpty) {
      routeConfig.parameters = constructor.parameters
          .map((p) => RouteParamConfig.fromParameterElement(p))
          .toList();
    }

    routeConfigs.add(routeConfig);
    return routeConfig;
  }

  void _extractMetaData(Element field, RouteConfig routeConfig) {
    final routeAnnotation = autoRouteChecker.firstAnnotationOf(field);
    if (routeAnnotation == null) {
      routeConfig.routeType = _globConfig.routeType;
      if (_globConfig.routeType == RouteType.custom) {
        routeConfig.transitionBuilder = _globConfig.transitionBuilder;
        routeConfig.durationInMilliseconds = _globConfig.durationInMilliseconds;
        routeConfig.customRouteBarrierDismissible =
            _globConfig.customRouteBarrierDismissible;
        routeConfig.customRouteOpaque = _globConfig.customRouteOpaque;
      }
      return;
    }

    final autoRoute = ConstantReader(routeAnnotation);

    routeConfig.fullscreenDialog =
        autoRoute.peek('fullscreenDialog')?.boolValue;
    routeConfig.maintainState = autoRoute.peek('maintainState')?.boolValue;
    routeConfig.initial = autoRoute.peek('initial')?.boolValue;
    routeConfig.pathName = autoRoute.peek('name')?.stringValue;
    final returnType = autoRoute.peek('returnType')?.typeValue;
    if (returnType != null) {
      routeConfig.returnType = returnType.name;
      final import = getImport(returnType.element);
      if (import != null) {
        routeConfig.imports.add(import);
      }
    }

    if ((autoRoute.instanceOf(TypeChecker.fromRuntime(MaterialRoute)))) {
      routeConfig.routeType = RouteType.material;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(CupertinoRoute))) {
      routeConfig.routeType = RouteType.cupertino;
      routeConfig.cupertinoNavTitle = autoRoute.peek('title')?.stringValue;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(CustomRoute))) {
      routeConfig.routeType = RouteType.custom;
      routeConfig.durationInMilliseconds =
          autoRoute.peek('durationInMilliseconds')?.intValue;
      routeConfig.customRouteOpaque = autoRoute.peek('opaque')?.boolValue;
      routeConfig.customRouteBarrierDismissible =
          autoRoute.peek('barrierDismissible')?.boolValue;
      final function =
          autoRoute.peek('transitionsBuilder')?.objectValue?.toFunctionValue();
      if (function != null) {
        final displayName = function.displayName.replaceFirst(RegExp('^_'), '');
        final functionName = (function.isStatic &&
                function.enclosingElement?.displayName != null)
            ? '${function.enclosingElement.displayName}.$displayName'
            : displayName;

        var import;
        if (function.enclosingElement?.name != 'TransitionsBuilders') {
          import = getImport(function);
        }
        routeConfig.transitionBuilder =
            CustomTransitionBuilder(functionName, import);
      }
    } else {
      routeConfig.routeType = _globConfig.routeType;
    }
  }
}
