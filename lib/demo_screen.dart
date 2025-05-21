import 'package:flutter/material.dart';
import 'package:state_saver/profile_model.dart';
import 'package:state_saver_package/state_saver_package.dart';

class DemoScreen extends StatefulWidget {
  const DemoScreen({super.key});

  @override
  State<DemoScreen> createState() => _DemoScreenState();
}

class _DemoScreenState extends State<DemoScreen> {
  Profile _profile = Profile();

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _ratingController = TextEditingController();
  final _tagController = TextEditingController();

  final _profileKey = 'profile_1';

  @override
  void initState() {
    super.initState();
    _loadProfile(_profileKey);

    // Add function to save data when application is closed
    saveOnStateAction(() async {
      await _saveProfile(_profileKey);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _ratingController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile(String key) async {
    final profile = await loadState<Profile>(
      key,
      fromJson: Profile.fromJson,
    );

    if (profile != null) {
      setState(() {
        _profile = profile;
        _updateProfileControllers();
      });
    }
  }

  Future<void> _saveProfile(String key) async {
    _profile.name = _nameController.text;
    _profile.age = int.tryParse(_ageController.text) ?? 0;
    _profile.rating = double.tryParse(_ratingController.text) ?? 0.0;
    _profile.lastUpdated = DateTime.now();

    await saveState(key, _profile);
  }

  void _updateProfileControllers() {
    _nameController.text = _profile.name;
    _ageController.text = _profile.age.toString();
    _ratingController.text = _profile.rating.toString();
  }

  void _addTag() {
    if (_tagController.text.isNotEmpty) {
      setState(() {
        _profile.tags.add(_tagController.text);
        _tagController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('State Saver Demo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              clearState(_profileKey);
              setState(() {
                _profile = Profile();
                _updateProfileControllers();
                _tagController.clear();
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data has been cleared')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PROFILE',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name (String)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ageController,
                decoration: const InputDecoration(
                  labelText: 'Age (int)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _ratingController,
                decoration: const InputDecoration(
                  labelText: 'Rating (double)',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _profile.isActive,
                    onChanged: (value) {
                      setState(() {
                        _profile.isActive = value ?? false;
                      });
                    },
                  ),
                  const Text('Active User (bool)'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Add Tag (List<String>)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addTag,
                    child: const Text('Add'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_profile.tags.isNotEmpty) ...[
                const Text('Tags:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: _profile.tags
                      .map((tag) => Chip(
                            label: Text(tag),
                            onDeleted: () {
                              setState(() {
                                _profile.tags.remove(tag);
                              });
                            },
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                'Last Updated (DateTime): ${_profile.lastUpdated.toLocal().toString().split('.').first}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
