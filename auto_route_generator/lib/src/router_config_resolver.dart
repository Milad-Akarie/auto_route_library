import 'package:analyzer/dart/element/element.dart';
import 'package:auto_route/auto_route_annotations.dart';
import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/utils.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

const TypeChecker guardsChecker = TypeChecker.fromRuntime(GuardedBy);
const TypeChecker autoRouteChecker = TypeChecker.fromRuntime(AutoRoute);
const TypeChecker unknownRouteChecker = TypeChecker.fromRuntime(UnknownRoute);

// extracts route configs from class fields
class RouterConfigResolver {
  final RouteConfig _globConfig;
  final _routeConfig = RouteConfig();
  final Resolver _resolver;

  RouterConfigResolver(this._globConfig, this._resolver);

  Future<RouteConfig> resolve(FieldElement field) async {
    final type = field.type;

    if (type.element is! ClassElement) {
      throw ('\n[${type.getDisplayString()}] is not a class');
    }

    final classElement = type.element as ClassElement;

    _routeConfig.isUnknownRoute =
        unknownRouteChecker.hasAnnotationOfExact(field);

    if (_routeConfig.isUnknownRoute) {
      final params = classElement.unnamedConstructor.parameters ?? [];
      if (params.isEmpty ||
          params.length > 1 ||
          params.first.type.getDisplayString() != 'String') {
        throw ("\nUnknowRoute must have a defualt constructor with a positional String Parameter, MyUnknownRoute(String routeName)\n");
      }
    }

    _extractRouteMetaData(field);

    guardsChecker
        .firstAnnotationOfExact(field)
        ?.getField('guards')
        ?.toListValue()
        ?.map((g) => g.toTypeValue())
        ?.forEach((guard) {
      _routeConfig.guards.add(RouteGuardConfig(
          type: guard.getDisplayString(), import: getImport(guard.element)));
    });

    final import = getImport(type.element);

    if (import != null) {
      _routeConfig.imports.add(import);
    }
    _routeConfig.name = field.name;
    _routeConfig.className = type.getDisplayString();

    _routeConfig.hasWrapper = classElement.allSupertypes
        .map<String>((el) => el.getDisplayString())
        .contains('AutoRouteWrapper');

    final constructor = classElement.unnamedConstructor;
    if (constructor != null && constructor.parameters.isNotEmpty) {
      _routeConfig.parameters = [];
      for (ParameterElement p in constructor.parameters) {
        _routeConfig.parameters
            .add(await RouteParameterResolver(_resolver).resolve(p));
      }
    }

    return _routeConfig;
  }

  void _extractRouteMetaData(FieldElement field) {
    final routeAnnotation = autoRouteChecker.firstAnnotationOf(field);

    ConstantReader autoRoute;
    if (routeAnnotation != null) {
      autoRoute = ConstantReader(routeAnnotation);
      _routeConfig.initial = autoRoute.peek('initial')?.boolValue;
    }
    if (autoRoute == null || _routeConfig.initial == true) {
      _routeConfig.routeType = _globConfig.routeType;
      if (_globConfig.routeType == RouteType.custom) {
        _routeConfig.transitionBuilder = _globConfig.transitionBuilder;
        _routeConfig.durationInMilliseconds =
            _globConfig.durationInMilliseconds;
        _routeConfig.customRouteBarrierDismissible =
            _globConfig.customRouteBarrierDismissible;
        _routeConfig.customRouteOpaque = _globConfig.customRouteOpaque;
      }
      return;
    }

    _routeConfig.fullscreenDialog =
        autoRoute.peek('fullscreenDialog')?.boolValue;
    _routeConfig.maintainState = autoRoute.peek('maintainState')?.boolValue;
    _routeConfig.pathName = autoRoute.peek('name')?.stringValue;
    final returnType = autoRoute.peek('returnType')?.typeValue;
    if (returnType != null) {
      _routeConfig.returnType = returnType.getDisplayString();
      final import = getImport(returnType.element);
      if (import != null) {
        _routeConfig.imports.add(import);
      }
    }

    if ((autoRoute.instanceOf(TypeChecker.fromRuntime(MaterialRoute)))) {
      _routeConfig.routeType = RouteType.material;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(CupertinoRoute))) {
      _routeConfig.routeType = RouteType.cupertino;
      _routeConfig.cupertinoNavTitle = autoRoute.peek('title')?.stringValue;
    } else if (autoRoute.instanceOf(TypeChecker.fromRuntime(CustomRoute))) {
      _routeConfig.routeType = RouteType.custom;
      _routeConfig.durationInMilliseconds =
          autoRoute.peek('durationInMilliseconds')?.intValue;
      _routeConfig.customRouteOpaque = autoRoute.peek('opaque')?.boolValue;
      _routeConfig.customRouteBarrierDismissible =
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
        _routeConfig.transitionBuilder =
            CustomTransitionBuilder(functionName, import);
      }
    } else {
      _routeConfig.routeType = _globConfig.routeType;
    }
  }
}
