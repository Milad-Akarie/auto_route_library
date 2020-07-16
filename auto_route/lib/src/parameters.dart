class Parameters {
  final Map<String, String> _params;

  Parameters(Map<String, String> params) : _params = params ?? {};

  Map<String, String> get rawMap => _params;

  ParameterValue operator [](String key) => ParameterValue._(_params[key]);

  @override
  String toString() {
    return _params.toString();
  }
}

class ParameterValue {
  final dynamic _value;

  const ParameterValue._(this._value);

  dynamic get value => _value;

  String get stringValue => _value;

  int get intValue => _value == null ? null : int.tryParse(_value);

  double get doubleValue => _value == null ? null : double.tryParse(_value);

  num get numValue => _value == null ? null : num.tryParse(_value);

  bool get boolValue {
    switch (_value?.toLowerCase()) {
      case 'true':
        return true;
      case 'false':
        return false;
      default:
        return null;
    }
  }
}
