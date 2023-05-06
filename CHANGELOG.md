# Change Log

All notable changes to this project will be documented in this file.
See [Conventional Commits](https://conventionalcommits.org) for commit guidelines.

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

