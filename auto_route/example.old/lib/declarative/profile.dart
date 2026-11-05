/// The name and age collected so far by the declarative example.
///
/// A `null` field means that step is not done yet.
class Profile {
  /// Creates a profile; both fields start empty.
  const new({this.name, this.age});

  /// The entered name, or `null` before it is submitted.
  final String? name;

  /// The entered age, or `null` before it is submitted.
  final int? age;

  /// Returns a copy with [name] and [age] replaced when they are not `null`.
  Profile copyWith({String? name, int? age}) {
    return Profile(name: name ?? this.name, age: age ?? this.age);
  }
}
