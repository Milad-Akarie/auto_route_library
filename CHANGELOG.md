# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

## 2023-05-28

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.3.1`](#auto_route---v731)
 - [`auto_route_generator` - `v7.1.2`](#auto_route_generator---v712)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v7.1.2`

---

#### `auto_route` - `v7.3.1`

 - **FIX**: DeferredWidget's default loader not working,.


## 2023-05-21

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route_generator` - `v7.1.1`](#auto_route_generator---v711)

---

#### `auto_route_generator` - `v7.1.1`

 - **REFACTOR**: change module extension from .module.dart to .gm.dart.
 - **DOCS**: update CHANGELOG.md.


## 2023-05-20

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.2.0`](#auto_route---v720)
 - [`auto_route_generator` - `v7.1.0`](#auto_route_generator---v710)

---

#### `auto_route` - `v7.2.0`

 - **REVERT**: "feat: add more flexible multi package support".
 - **REFACTOR**: resolve some flutter 3.10 deprecations.
 - **FEAT**(auto_route): add `AutoRouterConfig.module` annotation.
 - **FEAT**(auto_route): add `AutoRouterModule`.
 - **FEAT**: add more flexible multi package support.
 - **DOCS**(auto_route): fix typo.

#### `auto_route_generator` - `v7.1.0`

 - **REVERT**: "feat: add more flexible multi package support".
 - **REVERT**: "cleanup".
 - **FEAT**(auto_route_generator): expose the new `autoRouterModuleBuilder` to the package surface.
 - **FEAT**(auto_route_generator): add `AutoRouterModuleBuilder`.
 - **FEAT**(auto_route_generator): update code builder (add module support + rename).
 - **FEAT**(auto_route_generator): update `RouterConfig` + `RouterConfigResolver` to match `AutoRouterConfig.module`.
 - **FEAT**: add more flexible multi package support.


## 2023-05-06

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route_generator` - `v7.0.0`](#auto_route_generator---v700)

---

#### `auto_route_generator` - `v7.0.0`

 - **FEAT**: add support to process files in micro-packages.
 - **DOCS**: add all public api docs.


## 2023-05-06

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v7.1.0`](#auto_route---v710)
 - [`auto_route_generator` - `v6.2.1`](#auto_route_generator---v621)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v6.2.1`

---

#### `auto_route` - `v7.1.0`

 - **FEAT**: add support to process files in micro-packages.


## 2023-05-06

### Changes

---

Packages with breaking changes:

 - [`auto_route` - `v7.0.0`](#auto_route---v700)

Packages with other changes:

 - [`auto_route_generator` - `v6.2.1`](#auto_route_generator---v621)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v6.2.1`

---

#### `auto_route` - `v7.0.0`

 - **FIX**: deepLinkBuilder is not called on newRoutePath.
 - **BREAKING** **CHANGE**: DefaultRouteParser.includePrefixMatches's value is now set to '!kIsWeb' instead of 'false'.


## 2023-04-27

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v6.4.0`](#auto_route---v640)
 - [`auto_route_generator` - `v6.2.1`](#auto_route_generator---v621)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v6.2.1`

---

#### `auto_route` - `v6.4.0`

 - **REFACTOR**: deprecated initialDeepLink and initialRouts.


## 2023-04-18

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v6.3.0`](#auto_route---v630)
 - [`auto_route_generator` - `v6.2.1`](#auto_route_generator---v621)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v6.2.1`

---

#### `auto_route` - `v6.3.0`

 - **REFACTOR**: make AutoRouterState and AutoTabsRouterState public.
 - **FEAT**: Bring AutoRoute.initial back.


## 2023-04-18

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v6.2.1`](#auto_route---v621)
 - [`auto_route_generator` - `v6.2.1`](#auto_route_generator---v621)

Packages with dependency updates only:

> Packages listed below depend on other packages in this workspace that have had changes. Their versions have been incremented to bump the minimum dependency versions of the packages they depend upon in this project.

 - `auto_route_generator` - `v6.2.1`

---

#### `auto_route` - `v6.2.1`

 - **REFACTOR**: make AutoRouterState and AutoTabsRouterState public.
 - **DOCS**: add all public api docs.


## 2023-04-15

### Changes

---

Packages with breaking changes:

 - There are no breaking changes in this release.

Packages with other changes:

 - [`auto_route` - `v6.2.0`](#auto_route---v620)
 - [`auto_route_generator` - `v6.2.0`](#auto_route_generator---v620)

---

#### `auto_route` - `v6.2.0`

 - **FIX**: need to always depend on RouterScope.
 - **FIX**: url state decode issue.
 - **FEAT**: Add a getter to expose child widget from AutoRoutePage.
 - **FEAT**: deferred loading for web to enable code splitting for routes.

#### `auto_route_generator` - `v6.2.0`

 - **FIX**: include nested pages imports.
 - **FIX**(generator): Bool opt type as num.
 - **FEAT**: deferred loading for web to enable code splitting for routes.

