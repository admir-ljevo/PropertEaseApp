class Country {
  int? id;
  String? name;

  Country({this.id, this.name});

  factory Country.fromJson(Map<String, dynamic> json) => Country(
        id: json['id'] as int?,
        name: json['name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
