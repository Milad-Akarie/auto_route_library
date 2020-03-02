# ChangeLog
## [0.3.2]

- Fix generic arguments are not imported.

## [0.3.1]

- Fix Compilation Fails in flutter 1.15.+
- Fix third party imports src instead of library
- Fix guardedRoutes is generated even if it's empty
- Add support for custom unknown route screen
- upgrade analyzer min restrain to 0.39.2

## [0.3.0] Breaking Changes!

- Add global route customization
  Use MaterialAutoRouter, CupertinoAutoRouter or CustomAutoRouter instead of AutoRouter
- Navigator key is now accessed by calling Router.navigator.key instead of Router.navigatorKey.
- Add Route guards
- Add optional returnType param in all AutoRoute types.
- Remove generate Navigator Key option.
- Fix generate error when using dynamic vars in route widget constructors

## [0.2.2]

- Add option to generate a list with all route names
- change generating navigator key is now optional
- Fix prevent importing system library files
- Change generated route path name are now Kabab cased (url-friendly)
- Add ability to use custom path names in all route types
- Update README file

## [0.2.1+3]

- fix custom route not generating custom properties

## [0.2.1+2]

- fix @required is missing in arguments holder class

## [0.2.1+1]

- fix dependency conflict

## [0.2.1]

- add Route Wrapper
- add initial flag as a property in all route types
- change prefix const route names with class name.
- add fullscreenDialog property to @CustomRoute()

## [0.2.0]

### Breaking Changes!

- change to using a single config file instead of annotating the actual widget class due to performance issues.
- add @MaterialRoute(), @CupertinoRoute() and @CustomRoute() annotations
- remove @AutoRoute() annotation and add @AutoRouter()
- handle required parameters.
- add navigating with a global navigator key [without context].
- support nested navigators.

## [0.1.3]

- fix more dependencies resolving conflict.

## [0.1.2]

- fix dependencies resolving conflict.

## [0.1.1]

- code formatting.

## [0.1.0]

- initial release.
