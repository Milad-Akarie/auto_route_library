// holds the name and path of the passed
// transition builder function
class CustomTransitionBuilder {
  String name;
  String import;

  CustomTransitionBuilder(this.name, this.import);

  CustomTransitionBuilder.fromJson(Map json) {
    name = json['name'];
    import = json['import'];
  }

  Map<String, dynamic> toJson() => {"import": import, "name": name};
}
