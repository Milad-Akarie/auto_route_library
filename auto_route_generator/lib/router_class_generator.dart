import 'package:auto_route_generator/route_config_resolver.dart';
import 'package:auto_route_generator/utils.dart';

class RouterClassGenerator {
  final List<RouteConfig> _routes;
  final String _className;
  final RouterConfig _routerConfig;
  final StringBuffer _stringBuffer = StringBuffer();

  RouterClassGenerator(this._className, this._routes, this._routerConfig);
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
      "'package:auto_route/auto_route.dart'"
    };
    _routes.forEach((r) {
      imports.addAll(r.imports);
      if (r.transitionBuilder != null) {
        imports.add(r.transitionBuilder.import);
      }
      if (r.parameters != null) {
        r.parameters.forEach((param) {
          if (param.imports != null) imports.addAll(param.imports);
        });
      }
      if (r.guards != null) {
        r.guards.forEach((g) => imports.add(g.import));
      }
    });
    imports
        .where((import) => import != null)
        .forEach((import) => _writeln('import $import;'));
  }

  void _generateRoutesClass() {
    _writeln('abstract class ${_routerConfig.routesClassName} {');
    _routes.where((r) => !r.isUnknownRoute).forEach((r) {
      final routeName = r.name;
      final preFix = _routerConfig.useLeadingSlashes ? "/" : "";
      final pathName = r.pathName ?? "$preFix${toKababCase(routeName)}";
      if (r.initial == true) {
        _writeln("static const $routeName = '/';");
      } else {
        return _writeln("static const $routeName = '$pathName';");
      }
    });

    if (_routerConfig.generateRouteList) {
      _writeln("static const all = [");
      _routes
          .where((r) => !r.isUnknownRoute)
          .forEach((r) => _write('${r.name},'));
      _write("];");
    }
    _writeln('}');
  }

  void _generateRouteGeneratorFunction(List<RouteConfig> routes) {
    _newLine();
    _writeln('@override');
    _writeln('Route<dynamic> onGenerateRoute(RouteSettings settings) {');
    _writeln('final args = settings.arguments;');
    _writeln('switch (settings.name) {');

    routes.where((r) => !r.isUnknownRoute).forEach((r) {
      _writeln('case ${_routerConfig.routesClassName}.${r.name}:');

      _generateRoute(r);
    });

    // build unknown route error page if route is not found
    final unknowRoute =
        routes.firstWhere((r) => r.isUnknownRoute == true, orElse: () => null);
    if (unknowRoute != null) {
      _writeln('default: ');
      _generateRouteBuilder(
          unknowRoute, '${unknowRoute.className}(settings.name)');
    } else {
      _writeln('default: return unknownRoutePage(settings.name);');
    }
    // close switch case
    _writeln('}');
    _newLine();

    // close onGenerateRoute function
    _writeln('}');
  }

  void _generateRoute(RouteConfig r) {
    final constructorParams = StringBuffer('');

    if (r.parameters != null && r.parameters.isNotEmpty) {
      if (r.parameters.length == 1 &&
          !_routerConfig.generateArgsHolderForSingleParameterRoutes) {
        final param = r.parameters[0];

        // show an error page if passed args are not the same as declared args
        _writeln('if(hasInvalidArgs<${param.type}>(args');
        if (param.isRequired) {
          _write(',isRequired:true');
        }
        _write('))');
        _writeln('{return misTypedArgsRoute<${param.type}>(args);}');

        _writeln('final typedArgs = args as ${param.type}');
        if (param.defaultValueCode != null) {
          _write(' ?? ${param.defaultValueCode}');
        }
        _write(';');
        if (param.isPositional) {
          constructorParams.write('typedArgs');
        } else {
          constructorParams.write('${param.name}: typedArgs');
        }
      } else {
        // if router has any required or positinal params the argument class holder becomes required.
        final hasRequiredParams =
            r.parameters.any((p) => p.isRequired || p.isPositional);
        // show an error page  if passed args are not the same as declared args
        _writeln('if(hasInvalidArgs<${r.argumentsHolderClassName}>(args');
        if (hasRequiredParams) {
          _write(',isRequired:true');
        }
        _write('))');
        _writeln(
            '{return misTypedArgsRoute<${r.argumentsHolderClassName}>(args);}');

        _writeln('final typedArgs = args as ${r.argumentsHolderClassName}');
        if (!hasRequiredParams) {
          _write(' ?? ${r.argumentsHolderClassName}()');
        }
        _write(';');

        r.parameters.asMap().forEach((i, param) {
          if (param.isPositional) {
            constructorParams.write('typedArgs.${param.name}');
          } else {
            constructorParams.write('${param.name}:typedArgs.${param.name}');
          }
          if (i != r.parameters.length - 1) {
            constructorParams.write(',');
          }
        });
      }
    }

    final constructor =
        "${r.className}(${constructorParams.toString()})${r.hasWrapper ? ".wrappedRoute(context)" : ""}";

    _generateRouteBuilder(r, constructor);
  }

  void _generateArgumentHolders() {
    final routesWithArgsHolders = Map<String, RouteConfig>();

    // make sure we only generated holder classes for
    // routes with parameters
    // also prevent duplicate class with the same name from being generated;

    _routes.where((r) {
      return !r.isUnknownRoute &&
          r.parameters?.isNotEmpty == true &&
          (r.parameters.length > 1 ||
              _routerConfig.generateArgsHolderForSingleParameterRoutes);
    }).forEach((r) => routesWithArgsHolders[r.className] = r);

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
    r.parameters.forEach((param) {
      _writeln('final ${param.type} ${param.name};');
    });

    // generate constructor
    _writeln('$argsClassName({');
    r.parameters.asMap().forEach((i, param) {
      if (param.isRequired || param.isPositional) {
        _write('@required ');
      }

      _write('this.${param.name}');
      if (param.defaultValueCode != null) {
        _write(' = ${param.defaultValueCode}');
      }
      if (i != r.parameters.length - 1) {
        _write(',');
      }
    });
    _writeln('});');

    _writeln('}');
  }

  void _generateBoxed(String message) {
    _writeln('\n//'.padRight(77, '*'));
    _writeln('// $message');
    _writeln('//'.padRight(77, '*'));
    _newLine();
  }

  void _generateRouterClass() {
    _writeln('\nclass $_className extends RouterBase {');
    _generateHelperFunctions();
    _generateRouteGeneratorFunction(_routes);

    // close router class
    _writeln('}');
  }

  void _generateHelperFunctions() {
    final routesWithGuards =
        _routes.where((r) => r.guards != null && r.guards.isNotEmpty);

    if (routesWithGuards.isNotEmpty) {
      _writeln('@override');
      _writeln('Map<String, List<Type>> get guardedRoutes => {');
      routesWithGuards.forEach((r) {
        _write(
            '${_routerConfig.routesClassName}.${r.name}:${r.guards.map((g) => g.type).toSet().toList()},');
      });
      _write('};');
    }

    _writeln('''\n\n\n //This will probably be removed in future versions
  //you should call ExtendedNavigator.ofRouter<Router>() directly''');
    _writeln('''
    static ExtendedNavigatorState get navigator =>
      ExtendedNavigator.ofRouter<$_className>();
      ''');
  }

  void _generateRouteBuilder(RouteConfig r, String constructor) {
    final returnType = r.returnType ?? 'dynamic';
    if (r.routeType == RouteType.cupertino) {
      _write(
          'return CupertinoPageRoute<$returnType>(builder: (context) => $constructor, settings: settings,');
      if (r.cupertinoNavTitle != null) {
        _write("title:'${r.cupertinoNavTitle}',");
      }
    } else if (r.routeType == RouteType.material) {
      _write(
          'return MaterialPageRoute<$returnType>(builder: (context) => $constructor, settings: settings,');
    } else if (r.routeType == RouteType.adaptive) {
      _write(
          'return buildAdaptivePageRoute<$returnType>(builder: (context) => $constructor, settings: settings,');
      if (r.cupertinoNavTitle != null) {
        _write("cupertinoTitle:'${r.cupertinoNavTitle}',");
      }
    } else {
      _write(
          'return PageRouteBuilder<$returnType>(pageBuilder: (ctx, animation, secondaryAnimation) => $constructor, settings: settings,');

      if (r.customRouteOpaque != null) {
        _write('opaque:${r.customRouteOpaque.toString()},');
      }
      if (r.customRouteBarrierDismissible != null) {
        _write(
            'barrierDismissible:${r.customRouteBarrierDismissible.toString()},');
      }
      if (r.transitionBuilder != null) {
        _write('transitionsBuilder: ${r.transitionBuilder.name},');
      }
      if (r.durationInMilliseconds != null) {
        _write(
            'transitionDuration: const Duration(milliseconds: ${r.durationInMilliseconds}),');
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
    _writeln(
        'extension ${_className}NavigationHelperMethods on ExtendedNavigatorState {');
    _routes.where((r) => !r.isUnknownRoute).forEach(_generateHelperMethod);
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
    _write(
        ' => pushNamed$genericType(${_routerConfig.routesClassName}.${route.name}');
    if (route.parameters != null) {
      _write(',arguments: ');
      if (route.parameters.length == 1 &&
          !_routerConfig.generateArgsHolderForSingleParameterRoutes) {
        _write('${route.parameters.first.name}');
      } else {
        _write('${route.argumentsHolderClassName}(');
        _write(route.parameters.map((p) => '${p.name}: ${p.name}').join(','));
        _write(')');
      }

      if (route.guards?.isNotEmpty == true) {
        _write(',onReject:onReject');
      }
    }
    _write(');');
  }
}
