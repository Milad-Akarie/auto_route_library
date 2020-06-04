import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/utils.dart';

class RouterClassGenerator {
  final List<RouteConfig> _routes;
  final String _className;
  final RouterConfig _routerConfig;
  final RoutesConfig _routesConfig;
  final StringBuffer _stringBuffer = StringBuffer();

  RouterClassGenerator(
    this._className,
    this._routes,
    this._routerConfig,
    this._routesConfig,
  );

  // helper functions
  void _write(Object obj) => _stringBuffer.write(obj);

  void _writeln([Object obj]) => _stringBuffer.writeln(obj);

  void _newLine() => _stringBuffer.writeln();

  String generate() {
    _generateImports();
    _generateRoutesClass();
    _generateRouterClass();
    _generateArgumentHolders();
    if (_routerConfig.generateNavigationHelper) {
      _generateNavigationHelpers();
    }
    return _stringBuffer.toString();
  }

  void _generateImports() {
    // write route imports
    final imports = {
      "'package:flutter/material.dart'",
      "'package:flutter/cupertino.dart'",
      "'package:auto_route/auto_route.dart'",
    };
    _routes.forEach((r) {
      imports.addAll(r.imports);
      if (r.transitionBuilder != null) {
        imports.add(r.transitionBuilder.import);
      }
      if (r.parameters != null) {
        r.parameters.where((p) => p.imports != null).forEach((param) {
          imports.addAll(param.imports);
        });
      }
      if (r.guards != null) {
        r.guards.forEach((g) => imports.add(g.import));
      }
    });
    imports.where((import) => import != null).forEach((import) => _writeln('import $import;'));
  }

  void _generateRoutesClass() {
    _writeln('abstract class ${_routesConfig.routesClassName} {');
    _routes.forEach((r) {
      final routeName = r.name;
//      final preFix = _routesConfig.routeNamePrefix;
      final pathName = r.pathName; //?? "$preFix${toKababCase(routeName)}";
      _writeln("static const $routeName = '$pathName';");
    });
    _writeln("static const all = {");
    _routes.forEach((r) => _write('${r.name},'));
    _write("};");
    _writeln('}');
  }

  void _generateRoutesGetterFunction() {
    _newLine();
    _writeln('@override');
    _writeln("Set<String> get allRoutes => ${_routesConfig.routesClassName}.all;");
  }

  void _generateRouteGeneratorFunction(List<RouteConfig> routes) {
    _newLine();
    _writeln('''
      @override
      Map<String, AutoRouteFactory> get routesMap => _routesMap;
    ''');

    _writeln('final _routesMap = <String, AutoRouteFactory>{');
    routes.forEach((r) {
      _writeln('${_routesConfig.routesClassName}.${r.name}: (RouteData data) {');
      _generateRoute(r);
      _writeln('},');
    });

    // close _routes map
    _writeln('};');
  }

  void _generateRoute(RouteConfig r) {
    List constructorParams = [];

    if (r.parameters?.isNotEmpty == true) {
      // if router has any required or positional params the argument class holder becomes required.
      final nullOk = !r.parameters.any((p) => p.isRequired || p.isPositional);
      // show an error page  if passed args are not the same as declared args
      final argsType = r.argumentsHolderClassName;

      _writeln('var args = data.getArgs<$argsType>(');
      if (!nullOk) {
        _write(', nullOk: false');
      }
      _write(");");
      _writeln('$argsType typedArgs = args ?? $argsType();');

      constructorParams = r.parameters.map<String>((param) {
        String getterName;
        if (param.isPathParameter) {
          getterName = "data.pathParams['${param.paramName}'].${param.getterName}";
        } else if (param.isQueryParam) {
          getterName = "data.queryParams['${param.paramName}'].${param.getterName}";
        } else {
          getterName = "typedArgs.${param.name}";
        }
        if (param.isPositional) {
          return getterName;
        } else {
          return '${param.name}:$getterName';
        }
      }).toList();
    }

    // add any empty item to add a comma at end
    // when join(',') is called
    if (constructorParams.length > 2) {
      constructorParams.add('');
    }
    final constructor = "${r.className}(${constructorParams.join(',')})${r.hasWrapper ? ".wrappedRoute(context)" : ""}";

    _generateRouteBuilder(r, constructor);
  }

  void _generateArgumentHolders() {
    final routesWithArgsHolders = Map<String, RouteConfig>();

    // make sure we only generated holder classes for
    // routes with parameters
    // also prevent duplicate class with the same name from being generated;

    _routes.where((r) => r.parameters?.isNotEmpty == true).forEach((r) => routesWithArgsHolders[r.className] = r);

    if (routesWithArgsHolders.isNotEmpty) {
      _generateBoxed('Arguments holder classes');
      routesWithArgsHolders.values.forEach(_generateArgsHolder);
    }
  }

  void _generateArgsHolder(RouteConfig r) {
    _writeln('//${r.className} arguments holder class');
    final argsClassName = '${r.argumentsHolderClassName}';

    // generate fields
    _writeln('class $argsClassName{');
    final params = r.parameters.where((p) => !p.isPathParameter).toList();
    params.forEach((param) {
      _writeln('final ${param.type} ${param.name};');
    });

    // generate constructor
    _writeln('$argsClassName({');
    params.asMap().forEach((i, param) {
      if (param.isRequired || param.isPositional) {
        _write('@required ');
      }

      _write('this.${param.name}');
      if (param.defaultValueCode != null) {
        _write(' = ${param.defaultValueCode}');
      }
      if (i != params.length - 1) {
        _write(',');
      }
    });
    _writeln('});');

//    _writeln('$argsClassName._fromParams(Parameters params):');
//    params.asMap().forEach((i, param) {
//      var defaultCode = param.defaultValueCode != null ? '?? ${param.defaultValueCode}' : '';
//      _write("this.${param.name} = params['${param.name}'].${param.getterName} $defaultCode");
//      if (i != params.length - 1) {
//        _write(',');
//      } else
//        _write(';');
//    });

    // close class
    _writeln('}');
  }

  void _generateBoxed(String message) {
    _writeln('\n// '.padRight(77, '*'));
    _writeln('// $message');
    _writeln('// '.padRight(77, '*'));
    _newLine();
  }

  void _generateRouterClass() {
    _writeln('\nclass $_className extends RouterBase {');
    _generateRoutesGetterFunction();
    _generateHelperFunctions();
    _generateRouteGeneratorFunction(_routes);

    // close router class
    _writeln('}');
  }

  void _generateHelperFunctions() {
    final routesWithGuards = _routes.where((r) => r.guards != null && r.guards.isNotEmpty);

    if (routesWithGuards.isNotEmpty) {
      _writeln('@override');
      _writeln('Map<String, List<Type>> get guardedRoutes => {');
      routesWithGuards.forEach((r) {
        _write('${_routesConfig.routesClassName}.${r.name}:${r.guards.map((g) => g.type).toSet().toList()},');
      });
      _write('};');
    }
  }

  void _generateRouteBuilder(RouteConfig r, String constructor) {
    final returnType = r.returnType ?? 'dynamic';
    if (r.routeType == RouteType.cupertino) {
      _write('return CupertinoPageRoute<$returnType>(builder: (context) => $constructor, settings: data,');
      if (r.cupertinoNavTitle != null) {
        _write("title:'${r.cupertinoNavTitle}',");
      }
    } else if (r.routeType == RouteType.material) {
      _write('return MaterialPageRoute<$returnType>(builder: (context) => $constructor, settings: data,');
    } else if (r.routeType == RouteType.adaptive) {
      _write('return buildAdaptivePageRoute<$returnType>(builder: (context) => $constructor, settings: data,');
      if (r.cupertinoNavTitle != null) {
        _write("cupertinoTitle:'${r.cupertinoNavTitle}',");
      }
    } else {
      _write('return PageRouteBuilder<$returnType>(pageBuilder: (context, animation, secondaryAnimation) => $constructor, settings: data,');

      if (r.customRouteOpaque != null) {
        _write('opaque:${r.customRouteOpaque.toString()},');
      }
      if (r.customRouteBarrierDismissible != null) {
        _write('barrierDismissible:${r.customRouteBarrierDismissible.toString()},');
      }
      if (r.transitionBuilder != null) {
        _write('transitionsBuilder: ${r.transitionBuilder.name},');
      }
      if (r.durationInMilliseconds != null) {
        _write('transitionDuration: const Duration(milliseconds: ${r.durationInMilliseconds}),');
      }
    }
    // generated shared props
    if (r.fullscreenDialog != null) {
      _write('fullscreenDialog:${r.fullscreenDialog.toString()},');
    }
    if (r.maintainState != null) {
      _write('maintainState:${r.maintainState.toString()},');
    }

    _writeln(');');
  }

  void _generateNavigationHelpers() {
    _generateBoxed('Navigation helper methods extension');
    _writeln('extension ${_className}NavigationHelperMethods on XNavigatorState {');
    _routes.forEach(_generateHelperMethod);
    _writeln('}');
  }

  void _generateHelperMethod(RouteConfig route) {
    final genericType = route.returnType == null ? '' : '<${route.returnType}>';
    _write('Future$genericType push${capitalize(route.name)}(');
    // generate constructor
    if (route.parameters != null) {
      _write('{');
      route.parameters.forEach((param) {
        if (param.isRequired || param.isPositional) {
          _write('@required ');
        }

        _write('${param.type} ${param.name}');
        if (param.defaultValueCode != null) {
          _write(' = ${param.defaultValueCode}');
        }
        _write(',');
      });
      if (route.guards?.isNotEmpty == true) {
        _write('OnNavigationRejected onReject');
      }
      _write('}');
    }
    _writeln(')');
    _write(' => pushNamed$genericType(${_routesConfig.routesClassName}.${route.name}');
    if (route.parameters != null) {
      _write(',arguments: ');
      if (route.parameters.length == 1 && !_routerConfig.generateArgsHolderForSingleParameterRoutes) {
        _write('${route.parameters.first.name}');
      } else {
        _write('${route.argumentsHolderClassName}(');
        _write(route.parameters.map((p) => '${p.name}: ${p.name}').join(','));
        _write('),');
      }

      if (route.guards?.isNotEmpty == true) {
        _write('onReject:onReject,');
      }
    }
    _writeln(');\n');
  }
}
