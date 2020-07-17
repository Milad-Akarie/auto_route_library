extension UriX on Uri {
  String get normalizedPath =>
      hasQueryParams || hasFragment ? toString() : path;

  bool get hasQueryParams => queryParameters?.isNotEmpty == true;
}
