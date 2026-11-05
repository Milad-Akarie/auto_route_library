/// Does nothing, for a button that only has to be enabled or a callback whose
/// result a test doesn't read.
void noOp() {
  return;
}

/// Does nothing with its argument, for a reply or removal callback a test
/// doesn't read.
void ignoreArgument(Object? argument) {
  return;
}
