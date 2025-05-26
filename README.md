# State Saver Package

Simple and effective solution for storing data in Flutter applications.

## Features

- Simple API for saving and retrieving data
- Automatic JSON conversion
- Automatic saving when app closes
- Easy storage for complex objects

## Installation

```yaml
dependencies:
  state_saver_package: ^1.0.3
```

## Usage

### Basic Setup

```dart
void main() {
  stateSaverListener(); // Start listening for app closure
  runApp(MyApp());
}
```

### Saving Data

```dart
// Save object
await saveState('user', userObject);
```

### Loading Data

```dart
// Load object directly
final user = await loadState<User>(
  'user',
  fromJson: User.fromJson,
);
```

### Automatic Saving

```dart
// Will run when app closes
saveOnStateAction(() async {
  await saveState('user', userObject);
});
```

## Example

```dart
class Profile {
  String name;
  int age;
  double rating;
  bool isActive;
  List<String> tags;

  Profile({
    this.name = '',
    this.age = 0,
    this.rating = 0.0,
    this.isActive = false,
    List<String>? tags,
  })

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'rating': rating,
    'isActive': isActive,
    'tags': tags,
  };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    name: json['name'] ?? '',
    age: json['age'] ?? 0,
    rating: json['rating']?.toDouble() ?? 0.0,
    isActive: json['isActive'] ?? false,
    tags: List<String>.from(json['tags'] ?? []),
  );
}

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Profile _profile = Profile();
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
    
    saveOnStateAction(() async {
      await saveState('profile', _profile);
    });
  }
  
  Future<void> _loadProfile() async {
    final profile = await loadState<Profile>(
      'profile',
      fromJson: Profile.fromJson,
    );
    
    if (profile != null) {
      setState(() => _profile = profile);
    }
  }
  
  // Widget build...
}
```