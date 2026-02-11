import 'dart:convert';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:demo_flutter_aws/controllers/auth_controller.dart';
import 'package:demo_flutter_aws/views/edit_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final AuthController _authController = AuthController();
  static const _profileBaseUrl =
      'https://bj48gy3srd.execute-api.eu-north-1.amazonaws.com';

  final _secureStorage = const FlutterSecureStorage();

  final String _defaultAvatarUrl =
      'https://p7.hiclipart.com/preview/980/37/223/computer-icons-user-profile-avatar-person-png-clipart.jpg';
  final _imagePicker = ImagePicker();
  bool _uploading = false;

  String _displayName = 'User';

  bool _loading = true;
  bool _profileExists = false;
  String? _error;

  String? _profileFullName;
  String? _profileBio;
  List<String> _profileHobbies = [];
  String _profilePictureUrl = '';
  String _profilePictureKey = '';

  List<String> _carouselImageUrls = [];
  List<String> _carouselImageKeys = [];

  ButtonStyle _compactButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: Theme.of(context).textTheme.labelLarge,
    );
  }

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
          _profilePictureKey = (data['profilePictureKey'] ?? '').toString();
          _carouselImageUrls =
              (data['carouselImageUrls'] as List<dynamic>? ?? [])
                  .map((e) => e.toString())
                  .toList();
          _carouselImageKeys =
              (data['carouselImageKeys'] as List<dynamic>? ?? [])
                  .map((e) => e.toString())
                  .toList();
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
          _profilePictureKey = '';
          _carouselImageUrls = [];
          _carouselImageKeys = [];
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
        'profilePictureKey': '',
        'carouselImageKeys': [],
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
        _profilePictureKey = (created['profilePictureKey'] ?? '').toString();
        _carouselImageKeys = (created['carouselImageKeys'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
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
        ),
      ),
    );

    if (didUpdate == true) {
      await _initHome();
    }
  }

  Future<void> _uploadImage({required String type}) async {
    final idToken = await _secureStorage.read(key: 'idToken');
    if (idToken == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing token. Please sign in again.')),
      );
      return;
    }

    final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => _uploading = true);

    try {
      final bytes = await picked.readAsBytes();
      final ext = picked.path.split('.').last.toLowerCase();
      final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';

      // 1) get presigned PUT url + key
      final urlRes = await http.post(
        Uri.parse('$_profileBaseUrl/profile/upload-url'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'type': type, 'contentType': contentType}),
      );

      if (urlRes.statusCode != 200) {
        throw Exception(
          'upload-url failed: ${urlRes.statusCode} ${urlRes.body}',
        );
      }

      final urlData = jsonDecode(urlRes.body) as Map<String, dynamic>;
      final uploadUrl = urlData['uploadUrl'] as String;
      final key = urlData['key'] as String;
      final signedContentType =
          (urlData['contentType'] as String?) ?? contentType;

      // 2) upload to S3
      final putRes = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': signedContentType},
        body: bytes,
      );

      if (putRes.statusCode != 200) {
        throw Exception('S3 PUT failed: ${putRes.statusCode}');
      }

      // 3) update profile with the KEY (not URL)
      final Map<String, dynamic> updateBody;
      if (type == 'avatar') {
        updateBody = {'profilePictureKey': key};
      } else {
        updateBody = {
          'carouselImageKeys': [..._carouselImageKeys, key],
        };
      }

      final profileRes = await http.put(
        Uri.parse('$_profileBaseUrl/profile'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(updateBody),
      );

      if (profileRes.statusCode != 200) {
        throw Exception(
          'profile update failed: ${profileRes.statusCode} ${profileRes.body}',
        );
      }

      // 4) reload profile to get new signed GET urls
      await _initHome();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Upload complete')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _buildAvatar() {
    final url = _profilePictureUrl.trim().isEmpty
        ? _defaultAvatarUrl
        : _profilePictureUrl.trim();

    final canUpload = !_uploading && _profileExists;

    return Stack(
      alignment: Alignment.center,
      children: [
        GestureDetector(
          onTap: canUpload ? () => _uploadImage(type: 'avatar') : null,
          child: CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey.shade300,
            backgroundImage: NetworkImage(url),
            child: _uploading ? const CircularProgressIndicator() : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            color: Theme.of(context).colorScheme.primary,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: canUpload ? () => _uploadImage(type: 'avatar') : null,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
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
          ElevatedButton.icon(
            style: _compactButtonStyle(context),
            onPressed: _initHome,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
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
          ElevatedButton.icon(
            style: _compactButtonStyle(context),
            onPressed: _goToEditProfile,
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Profile'),
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
        ElevatedButton.icon(
          style: _compactButtonStyle(context),
          onPressed: _createProfile,
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Create Profile'),
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
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: () {
              _authController.signOutUser(context: context);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
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
              items: _carouselImageUrls.map((url) {
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
            ElevatedButton.icon(
              style: _compactButtonStyle(context),
              onPressed: (_uploading || !_profileExists)
                  ? null
                  : () => _uploadImage(type: 'carousel'),
              icon: const Icon(Icons.photo_library, size: 18),
              label: Text(_uploading ? 'Uploading...' : 'Upload Picture'),
            ),
          ],
        ),
      ),
    );
  }
}
