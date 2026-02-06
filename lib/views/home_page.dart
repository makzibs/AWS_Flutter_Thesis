import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:demo_flutter_aws/views/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const _profileBaseUrl =
      'https://bj48gy3srd.execute-api.eu-north-1.amazonaws.com';

  final _secureStorage = const FlutterSecureStorage();

  final String _defaultAvatarUrl =
      'https://p7.hiclipart.com/preview/980/37/223/computer-icons-user-profile-avatar-person-png-clipart.jpg';

  String _displayName = 'User';

  bool _loading = true;
  bool _profileExists = false;
  String? _error;

  String? _profileFullName;
  String? _profileBio;
  List<String> _profileHobbies = [];
  String _profilePictureUrl = '';

  final List<String> _uploadedImageUrls = [
    'https://images.unsplash.com/photo-1503023345310-bd7c1de61c7d?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxzZWFyY2h8Mnx8aHVtYW58ZW58MHx8MHx8&w=1000&q=80',
    'https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg?auto=compress&cs=tinysrgb&dpr=1&w=500',
    'https://media.istockphoto.com/id/1386479313/photo/happy-millennial-afro-american-business-woman-posing-isolated-on-white.jpg?s=612x612&w=0&k=20&c=8ssXDNTpOk_adog_20E_lB-vts2vut62KnjsVwFN6kI=',
    'https://t4.ftcdn.net/jpg/03/64/21/11/360_F_364211147_1qgLVxv1Tcq0Ohz3FawUfrtONzz8nq3e.jpg',
  ];

  @override
  void initState() {
    super.initState();
    _initHome();
  }

  Future<void> _initHome() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final idToken = await _secureStorage.read(key: 'idToken');
    if (idToken == null) {
      setState(() {
        _displayName = 'User';
        _profileExists = false;
        _error = 'Not logged in (missing token). Please sign in again.';
        _loading = false;
      });
      return;
    }

    final nameFromToken = _getNameFromIdToken(idToken);
    setState(() {
      _displayName = nameFromToken ?? 'User';
    });

    await _loadProfile(idToken);
  }

  Future<void> _loadProfile(String idToken) async {
    try {
      final res = await http.get(
        Uri.parse('$_profileBaseUrl/profile'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;

        setState(() {
          _profileExists = true;

          _profileFullName = (data['fullName'] ?? '').toString();
          _profileBio = (data['bio'] ?? '').toString();

          _profileHobbies = (data['hobbies'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();

          _profilePictureUrl = (data['profilePictureUrl'] ?? '').toString();

          _loading = false;
        });
        return;
      }

      if (res.statusCode == 404) {
        setState(() {
          _profileExists = false;
          _profileFullName = null;
          _profileBio = null;
          _profileHobbies = [];
          _profilePictureUrl = '';
          _loading = false;
        });
        return;
      }

      if (res.statusCode == 401) {
        setState(() {
          _profileExists = false;
          _error = 'Unauthorized (token expired). Please sign in again.';
          _loading = false;
        });
        return;
      }

      setState(() {
        _profileExists = false;
        _error = 'Failed to load profile: ${res.statusCode} ${res.body}';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _profileExists = false;
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _createProfile() async {
    final idToken = await _secureStorage.read(key: 'idToken');
    if (idToken == null) {
      setState(() {
        _error = 'Missing token. Please sign in again.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final res = await http.post(
      Uri.parse('$_profileBaseUrl/profile'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'fullName': _displayName,
        'bio': '',
        'hobbies': [],
        'profilePictureUrl': '',
      }),
    );

    if (res.statusCode == 201) {
      final created = jsonDecode(res.body) as Map<String, dynamic>;

      setState(() {
        _profileExists = true;
        _profileFullName = (created['fullName'] ?? '').toString();
        _profileBio = (created['bio'] ?? '').toString();
        _profileHobbies = (created['hobbies'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
        _profilePictureUrl = (created['profilePictureUrl'] ?? '').toString();
        _loading = false;
      });

      await _goToEditProfile();
      return;
    }

    setState(() {
      _error = 'Create failed: ${res.statusCode} ${res.body}';
      _loading = false;
    });
  }

  String? _getNameFromIdToken(String idToken) {
    try {
      final parts = idToken.split('.');
      if (parts.length != 3) return null;

      String normalized = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      switch (normalized.length % 4) {
        case 0:
          break;
        case 2:
          normalized += '==';
          break;
        case 3:
          normalized += '=';
          break;
        default:
          return null;
      }

      final payload = utf8.decode(base64Url.decode(normalized));
      final data = jsonDecode(payload) as Map<String, dynamic>;

      final name = data['name']?.toString();
      if (name == null || name.trim().isEmpty) return null;

      return name;
    } catch (_) {
      return null;
    }
  }

  Future<void> _goToEditProfile() async {
    final didUpdate = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfilePage(
          initialFullName: (_profileFullName?.trim().isNotEmpty ?? false)
              ? _profileFullName!
              : _displayName,
          initialBio: _profileBio ?? '',
          initialHobbies: _profileHobbies,
          initialProfilePictureUrl: _profilePictureUrl,
        ),
      ),
    );

    if (didUpdate == true) {
      await _initHome();
    }
  }

  Widget _buildAvatar() {
    final url = _profilePictureUrl.trim().isEmpty
        ? _defaultAvatarUrl
        : _profilePictureUrl.trim();

    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.grey.shade300,
      backgroundImage: NetworkImage(url),
    );
  }

  Widget _topSection(BuildContext context) {
    if (_loading) {
      return Column(
        children: const [
          SizedBox(height: 12),
          CircularProgressIndicator(),
          SizedBox(height: 12),
          Text('Loading...'),
        ],
      );
    }

    if (_error != null) {
      return Column(
        children: [
          Text(
            _displayName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _initHome, child: const Text('Retry')),
        ],
      );
    }

    if (_profileExists) {
      final shownName = (_profileFullName ?? '').trim().isEmpty
          ? _displayName
          : (_profileFullName ?? _displayName);

      final shownBio = (_profileBio ?? '').trim().isEmpty
          ? 'No bio yet'
          : (_profileBio ?? '');

      final shownHobbies = _profileHobbies.isEmpty
          ? 'No hobbies yet'
          : _profileHobbies.join(', ');

      return Column(
        children: [
          Text(
            shownName,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            shownBio,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            shownHobbies,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _goToEditProfile,
            child: const Text('Edit Profile'),
          ),
        ],
      );
    }

    return Column(
      children: [
        Text(
          _displayName,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Profile not created yet.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _createProfile,
          child: const Text('Create Profile'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildAvatar(),
            const SizedBox(height: 16),
            _topSection(context),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Uploaded Pictures',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            CarouselSlider(
              options: CarouselOptions(
                height: 200.0,
                autoPlay: true,
                enlargeCenterPage: true,
                aspectRatio: 16 / 9,
                viewportFraction: 0.8,
              ),
              items: _uploadedImageUrls.map((url) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(8.0),
                        image: DecorationImage(
                          image: NetworkImage(url),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {},
              child: const Text('Upload New Picture'),
            ),
          ],
        ),
      ),
    );
  }
}
