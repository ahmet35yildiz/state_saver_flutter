class Profile {
  String name;
  int age;
  double rating;
  bool isActive;
  List<String> tags;
  DateTime lastUpdated;

  Profile({
    this.name = '',
    this.age = 0,
    this.rating = 0.0,
    this.isActive = false,
    List<String>? tags,
    DateTime? lastUpdated,
  })  : tags = tags ?? [],
        lastUpdated = lastUpdated ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'rating': rating,
        'isActive': isActive,
        'tags': tags,
        'lastUpdated': lastUpdated.toIso8601String(),
      };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        name: json['name'] ?? '',
        age: json['age'] ?? 0,
        rating: json['rating']?.toDouble() ?? 0.0,
        isActive: json['isActive'] ?? false,
        tags: List<String>.from(json['tags'] ?? []),
        lastUpdated: json['lastUpdated'] != null
            ? DateTime.parse(json['lastUpdated'])
            : DateTime.now(),
      );
}
