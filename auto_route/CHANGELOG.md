## [0.3.0] Breaking Changes!
- Add global route customization
Use MaterialAutoRouter, CupertinoAutoRouter or CustomAutoRouter instead of AutoRouter
- Navigator key is now accessed by calling Router.navigator.key instead of Router.navigatorKey.
- Add Route guards
- Add optional returnType param in all AutoRoute types.
- Remove generate Navigator Key optionality.
- Fix generate error when using dynamic vars in route widget constructors
## [0.2.2]

- Add option to generate a list with all route names
- change generating navigator key is now optional
- Fix prevent importing system library files
- Change generated route path name are now Kabab cased (url-friendly)
- Add ability to use custom path names in all route types
- Update README file

## [0.2.1]

- add Route Wrapper
- add initial flag as a property in all route types
- change prefix const route names with class name.
- add fullscreenDialog property to @CustomRoute()

## [0.2.0+1]

- format README file

## [0.2.0]

### Breaking Changes!

- change to using a single config file instead of annotating the actual widget class due to performance issues.
- add @MaterialRoute(), @CupertinoRoute() and @CustomRoute() annotations
- remove @AutoRoute() annotation and add @AutoRouter()
- handle required parameters.
- add navigating with a global navigator key [without context].
- support nested navigators.

## [0.1.1]

- code formatting.

## [0.1.0]

- initial release.
