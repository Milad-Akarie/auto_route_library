import 'package:auto_route_generator/src/models/route_config.dart';
import 'package:auto_route_generator/src/models/route_parameter_config.dart';
import 'package:lean_builder/builder.dart';
import 'package:lean_builder/element.dart';

import '../build_utils.dart';
import 'lean_route_parameter_resolver.dart';
import 'lean_type_resolver.dart';

/// extracts route configs from class fields and their meta data
class LeanRouteConfigResolver {
  final Resolver _resolver;
  final LeanTypeResolver _typeResolver;

  /// Default constructor
  LeanRouteConfigResolver(this._resolver, this._typeResolver);

  /// Resolves a [ClassElement] into a consumable [RouteConfig]
  RouteConfig resolve(Element element, ConstObject routePage) {
    var isDeferred = routePage.getBool('deferredLoading')?.value;
    throwIf(
      element is! ClassElement,
      '${element.name} is not a class element',
      element: element,
    );

    final classElement = element as ClassElement;
    final page = classElement.thisType;
    // final autoRouteWrapperChecker = _resolver.typeCheckerOf<AutoRouteWrapper>();
    final hasWrappedRoute = false; //autoRouteWrapperChecker.isAssignableFrom(classElement);
    var pageType = _typeResolver.resolveType(page);
    var className = page.name;

    var name = routePage.getString('name')?.value;
    final constructor = classElement.unnamedConstructor;
    throwIf(
      constructor == null,
      'Route pages must have an unnamed constructor',
    );
    var hasConstConstructor = false;
    var params = constructor!.parameters;
    var parameters = <ParamConfig>[];
    if (params.isNotEmpty) {
      if (constructor.isConst && params.length == 1 && params.first.type.name == 'Key') {
        hasConstConstructor = true;
      } else {
        final paramResolver = LeanRouteParameterResolver(_resolver, _typeResolver);
        for (ParameterElement p in constructor.parameters) {
          parameters.add(paramResolver.resolve(p));
        }
      }
    }

    throwIf(
      parameters.where((e) => e.isUrlFragment).length > 1,
      'Only one parameter can be annotated with @urlFragment',
      element: element,
    );

    var pathParameters = parameters.where((element) => element.isPathParam);

    if (parameters.any((p) => p.isPathParam || p.isQueryParam)) {
      var unParsableRequiredArgs =
          parameters.where((p) => (p.isRequired || p.isPositional) && !p.isPathParam && !p.isQueryParam);
      if (unParsableRequiredArgs.isNotEmpty) {
        print(
            '\nWARNING => Because [$className] has required parameters ${unParsableRequiredArgs.map((e) => e.paramName)} '
            'that can not be parsed from path,\n@PathParam() and @QueryParam() annotations will be ignored.\n');
      }
    }

    if (pathParameters.isNotEmpty) {
      for (var pParam in pathParameters) {
        throwIf(
          !validPathParamTypes.contains(pParam.type.name),
          "Parameter [${pParam.name}] must be of a type that can be parsed from a [String] because it will also obtain it's value from a path\nvalid types: $validPathParamTypes",
        );
      }
    }

    return RouteConfig(
      className: className,
      name: name,
      hasWrappedRoute: hasWrappedRoute,
      parameters: parameters,
      hasConstConstructor: hasConstConstructor,
      pageType: pageType,
      deferredLoading: isDeferred,
    );
  }
}
