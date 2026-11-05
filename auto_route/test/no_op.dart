import 'package:flutter/foundation.dart';

/// Does nothing, for a button that only has to be enabled or a callback whose
/// result a test doesn't read. It builds an object and drops it.
const VoidCallback noOp = Object.new;

/// Does nothing with its argument, for a reply or removal callback a test
/// doesn't read. It hashes the argument and drops the number.
const void Function(Object?) ignoreArgument = identityHashCode;
