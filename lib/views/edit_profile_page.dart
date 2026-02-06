import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.initialFullName,
    required this.initialBio,
    required this.initialHobbies,
    required this.initialProfilePictureUrl,
  });

  final String initialFullName;
  final String initialBio;
  final List<String> initialHobbies;
  final String initialProfilePictureUrl;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  static const _profileBaseUrl =
      'https://bj48gy3srd.execute-api.eu-north-1.amazonaws.com';

  final _secureStorage = const FlutterSecureStorage();

  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _hobbiesController;
  late final TextEditingController _profilePictureUrlController;

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialFullName);
    _bioController = TextEditingController(text: widget.initialBio);
    _hobbiesController =
        TextEditingController(text: widget.initialHobbies.join(', '));
    _profilePictureUrlController =
        TextEditingController(text: widget.initialProfilePictureUrl);

    _profilePictureUrlController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _hobbiesController.dispose();
    _profilePictureUrlController.dispose();
    super.dispose();
  }

  List<String> _parseHobbies(String input) {
    return input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    final idToken = await _secureStorage.read(key: 'idToken');
    if (idToken == null) {
      setState(() => _error = 'Missing token. Please sign in again.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final fullName = _nameController.text.trim();
    final bio = _bioController.text.trim();
    final hobbies = _parseHobbies(_hobbiesController.text);
    final profilePictureUrl = _profilePictureUrlController.text.trim();

    final res = await http.put(
      Uri.parse('$_profileBaseUrl/profile'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fullName': fullName,
        'bio': bio,
        'hobbies': hobbies,
        'profilePictureUrl': profilePictureUrl,
      }),
    );

    if (res.statusCode == 200) {
      if (!mounted) return;
      Navigator.pop(context, true);
      return;
    }

    setState(() {
      _error = 'Update failed: ${res.statusCode} ${res.body}';
      _saving = false;
    });
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _navRow({
    required String title,
    required String value,
    String? subtitle,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        ListTile(
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              value.trim().isEmpty ? 'Not set' : value,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
        ),
        if (showDivider) const Divider(height: 0),
      ],
    );
  }

  Future<void> _editField({
    required String title,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
  }) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => EditTextFieldPage(
          title: title,
          initialValue: controller.text,
          hintText: hintText,
          maxLines: maxLines,
        ),
      ),
    );

    if (result != null) {
      controller.text = result;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final avatarUrl = _profilePictureUrlController.text.trim();
    final hasAvatar = avatarUrl.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving...' : 'Save'),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_error != null) ...[
              Text(
                _error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
            Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.grey.shade300,
                  backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                  child: !hasAvatar
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  _nameController.text.trim().isEmpty
                      ? 'Your Name'
                      : _nameController.text.trim(),
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Edit your personal info',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade700),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              children: [
                _navRow(
                  title: 'Name',
                  value: _nameController.text,
                  onTap: () => _editField(
                    title: 'Name',
                    controller: _nameController,
                    hintText: 'Enter your name',
                    maxLines: 1,
                  ),
                ),
                _navRow(
                  title: 'Bio',
                  value: _bioController.text,
                  onTap: () => _editField(
                    title: 'Bio',
                    controller: _bioController,
                    hintText: 'Write something about you',
                    maxLines: 4,
                  ),
                ),
                _navRow(
                  title: 'Hobbies',
                  
                  value: _hobbiesController.text,
                  onTap: () => _editField(
                    title: 'Hobbies',
                    controller: _hobbiesController,
                    hintText: 'Film, music, gym...',
                    maxLines: 2,
                  ),
                ),
                _navRow(
                  title: 'Profile picture URL',
                  value: _profilePictureUrlController.text,
                  onTap: () => _editField(
                    title: 'Profile picture URL',
                    controller: _profilePictureUrlController,
                    hintText: 'https://...',
                    maxLines: 2,
                  ),
                  showDivider: false,
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class EditTextFieldPage extends StatefulWidget {
  const EditTextFieldPage({
    super.key,
    required this.title,
    required this.initialValue,
    this.hintText,
    this.maxLines = 1,
  });

  final String title;
  final String initialValue;
  final String? hintText;
  final int maxLines;

  @override
  State<EditTextFieldPage> createState() => _EditTextFieldPageState();
}

class _EditTextFieldPageState extends State<EditTextFieldPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: theme.colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _controller.text),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          controller: _controller,
          maxLines: widget.maxLines,
          decoration: InputDecoration(
            hintText: widget.hintText,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }
}