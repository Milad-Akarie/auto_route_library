import 'package:auto_route/auto_route.dart';

// a simple container for all navigation keys.
typedef GuardResolver = T Function<T>([String name]);

class NavigationService {
  // ensure we only have one instance of the container
  static final NavigationService _instance = NavigationService._internal();
  Map<Type, ExtendedNavigator> _navigatorKeys;
  final _registeredGuards = <Type, RouteGuard>{};

  Map<Type, RouteGuard> get registeredGuards => _registeredGuards;

  void _registerGuard(RouteGuard guard) {
    _registeredGuards[guard.runtimeType] = guard;
  }

  GuardResolver guardResolver;
  factory NavigationService() {
    return _instance;
  }

  RouteGuard _getGuardByType(Type gaurdType) {
    print(NavigationService()._registeredGuards.toString());
    final guard = NavigationService()._registeredGuards[gaurdType];
    if (guard == null) {
      throw ('$gaurdType is not registered! \n did you forget to call NavigationService.registerGaurd()?');
    }
    return guard;
  }

  static void registerGuard(RouteGuard guard) {
    NavigationService()._registerGuard(guard);
  }

  NavigationService._internal() {
    _navigatorKeys = {};
  }

  static ExtendedNavigator findOrCreate<T>(
      {Map<String, List<Type>> guardedRoutes}) {
    // initiate keys lazily
    return NavigationService()._navigatorKeys[T] ??=
        ExtendedNavigator(guardedRoutes);
  }

  static ExtendedNavigator find<T>(Map<String, List<Type>> guardedRoutes) {
    return NavigationService()._navigatorKeys[T];
  }

  static RouteGuard getGuardByType(Type guardType) {
    return NavigationService()._getGuardByType(guardType);
  }
}
