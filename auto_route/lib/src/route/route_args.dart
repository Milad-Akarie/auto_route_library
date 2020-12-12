import 'package:equatable/equatable.dart';

abstract class RouteArgs extends Equatable {
  final List<Object> props;
  const RouteArgs(this.props);
}
