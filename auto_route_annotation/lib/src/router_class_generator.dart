import 'package:auto_route_annotation/src/route_builder_config.dart';
import 'package:auto_route_annotation/src/string_utils.dart';

class RouterClassGenerator {
  final List<RouteConfig> routes;

  final StringBuffer _stringBuffer = StringBuffer();

  RouterClassGenerator(this.routes);

  // helper functions
  _write(Object obj) => _stringBuffer.write(obj);

  _writeln([Object obj]) => _stringBuffer.writeln(obj);

  _newLine() => _stringBuffer.writeln();

  String generate() {
    _generateImports();
    _newLine();
    _writeln("class Router {");
    _generateRouteNames();
    _generateRouteGeneratorFunction();

    _generateNeededFunctions();

    // close router class
    _writeln("}");
    _generateArgumentHolders();
    return _stringBuffer.toString();
  }

  void _generateImports() {
    _writeln("import 'package:flutter/material.dart';");
    routes.forEach((r) => _writeln(r.import));
  }

  void _generateRouteNames() {
    _newLine();
    routes.forEach((r) {
      final routeName = _generateRouteName(r);
      return _writeln(" static const $routeName = '/${routeName}';");
    });
  }

  String _generateRouteName(RouteConfig r) {
    String routeName = _routeNameFromClassName(r.className);
    if (r.name != null) {
      final strippedName = r.name.replaceAll(r"\s", "");
      if (strippedName.isNotEmpty) routeName = strippedName;
    }
    return routeName;
  }

  _routeNameFromClassName(String className) {
    final name = toLowerCamelCase(className);
    return "${name}Route";
  }

  void _generateRouteGeneratorFunction() {
    _newLine();
    _writeln("static Route<dynamic> onGenerateRoute(RouteSettings settings) {");
    _writeln("final args = settings.arguments;");
    _writeln("switch (settings.name) {");
    routes.forEach((r) => generateRoute(r));

    _generateUnknownRoutePage();
    // close switch case
    _writeln("}");
    _newLine();

    // close onGenerateRoute function
    _writeln("}");
  }

  generateRoute(RouteConfig r) {
    _writeln("case ${_generateRouteName(r)}:");

    StringBuffer constructorParams = StringBuffer("");

    if (r.parameters != null && r.parameters.isNotEmpty) {
      if (r.parameters.length == 1) {
        final param = r.parameters[0];

        // throw in exception if passed args are not the same as declared args
        _writeln("_checkArgsType<${param.type}>(args);");
        _writeln("final typedArgs = args as ${param.type};");

        if (param.isPositional)
          constructorParams.write("typedArgs");
        else {
          constructorParams.write("${param.name}: typedArgs");
          if (param.defaultValueCode != null) constructorParams.write(" ?? ${param.defaultValueCode}");
        }
      } else {
        // throw in exception if passed args are not the same as declared args
        _writeln("_checkArgsType<${r.className}Arguments>(args);");

        _writeln("final typedArgs = args as ${r.className}Arguments ?? ${r.className}Arguments();");

        r.parameters.asMap().forEach((i, param) {
          if (param.isPositional)
            constructorParams.write("typedArgs.${param.name}");
          else
            constructorParams.write("${param.name}:typedArgs.${param.name}");

          if (i != r.parameters.length - 1) constructorParams.write(",");
        });
      }
    }
    _write(
        "return MaterialPageRoute(builder: (_) => ${r.className}(${constructorParams.toString()}), settings: settings");
    if (r.fullscreenDialog != null) _write(",fullscreenDialog:${r.fullscreenDialog.toString()}");
    if (r.maintainState != null) _write(",maintainState:${r.maintainState.toString()}");
    _writeln(");");
    _writeln("break;");
  }

  void _generateUnknownRoutePage() {
    _writeln("default:");
    _writeln(
        "return MaterialPageRoute(builder: (_) => \n Scaffold(body: \n Container(color: Colors.redAccent,\n child: Center(\n  child: Text(\n 'Route name \${settings.name} is not registered'),),),),);");
  }

  void _generateArgumentHolders() {
    _newLine();
    _writeln("//----------------------------------------------");
    final routesWithArgsHolders = routes.where((r) => r.parameters != null && r.parameters.length > 1);
    routesWithArgsHolders.forEach((r) {
      _generateArgsHolder(r);
    });
  }

  void _generateArgsHolder(RouteConfig r) {
    _writeln("//${r.className} arguments holder class");
    final argsClassName = "${r.className}Arguments";

    _writeln("class $argsClassName{");
    r.parameters.forEach((param) {
      _writeln("final ${param.type} ${param.name};");
    });

    _writeln("$argsClassName({");
    r.parameters.asMap().forEach((i, param) {
      _write("this.${param.name}");
      if (param.defaultValueCode != null) _write(" = ${param.defaultValueCode}");
      if (i != r.parameters.length - 1) _write(",");
    });
    _writeln("});");

    _writeln("}");
  }

  void _generateNeededFunctions() {
    _newLine();
    _writeln("static void _checkArgsType<T>(Object args) {");
    _writeln("if (args != null && args is! T)");
    _writeln("throw ('Arguments Mistype: expected \${T.toString()} passed \${args.runtimeType}');\n}");
  }
}
