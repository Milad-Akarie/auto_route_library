import 'package:flutter/material.dart';

// a simple container for all navigation keys.
class NavigationKeysContainer {
  // ensure we only have one instance of the container
	static final NavigationKeysContainer _instance =
	NavigationKeysContainer._internal();
  Map<Type, GlobalKey<NavigatorState>> _navigatorKeys;

  factory NavigationKeysContainer() {
    return _instance;
  }

  NavigationKeysContainer._internal() {
    _navigatorKeys = {};
  }

  GlobalKey<NavigatorState> get<T>() {
    // initiate keys lazily
	  return _navigatorKeys[T] ??=
			  GlobalKey<NavigatorState>(debugLabel: T.toString());
  }
}
