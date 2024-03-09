bool hasRouteAnnotation(List<int> byteArray) {
  List<int> targetSequence = [0x40, 0x52, 0x6F, 0x75, 0x74, 0x65]; // ASCII values for '@Route'
  for (int i = 0; i < byteArray.length; i++) {
    if (byteArray[i] == targetSequence[0]) {
      for (int j = 1; j < targetSequence.length; j++) {
        if (byteArray[i + j] != targetSequence[j]) {
          break;
        }
        if (j == targetSequence.length - 1) {
          return true;
        }
      }
    }
  }
  return false;
}
