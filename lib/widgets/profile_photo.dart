import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_client.dart';

class ProfilePhoto extends StatefulWidget {
  const ProfilePhoto(
      {super.key,
      required this.api,
      required this.tokenProvider,
      required this.avatarUrl,
      required this.name,
      required this.onUpdated,
      this.radius = 30});
  final ApiClient api;
  final String? Function() tokenProvider;
  final String avatarUrl, name;
  final Future<void> Function() onUpdated;
  final double radius;
  @override
  State<ProfilePhoto> createState() => _ProfilePhotoState();
}

class _ProfilePhotoState extends State<ProfilePhoto> {
  bool _busy = false;
  String? _uploaded;
  Future<void> _pick() async {
    if (_busy) return;
    final token = widget.tokenProvider();
    if (token == null) return;
    setState(() => _busy = true);
    try {
      final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif'],
          withData: true);
      if (result == null) return;
      final file = result.files.single;
      if (file.bytes == null || file.size > 5 * 1024 * 1024) {
        throw const ApiException('Choose an image smaller than 5 MB.');
      }
      _uploaded =
          await widget.api.uploadProfileImage(file.bytes!, file.name, token);
      await widget.onUpdated();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Could not update profile photo. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
        child: Text(
            widget.name.trim().isEmpty
                ? '?'
                : widget.name.trim().substring(0, 1).toUpperCase(),
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: widget.radius * .75,
                color: Theme.of(context).colorScheme.onPrimaryContainer)));
    return Semantics(
        label: 'Profile photo',
        child: Stack(clipBehavior: Clip.none, children: [
          ClipOval(
              child: Container(
                  width: widget.radius * 2,
                  height: widget.radius * 2,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: (_uploaded ?? widget.avatarUrl).isEmpty
                      ? fallback
                      : Image.network(_uploaded ?? widget.avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => fallback))),
          Positioned(
              right: -8,
              bottom: -8,
              child: SizedBox(
                  width: 36,
                  height: 36,
                  child: _busy
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : IconButton.filledTonal(
                          tooltip: 'Change profile photo',
                          onPressed: _pick,
                          icon: const Icon(Icons.camera_alt, size: 18))))
        ]));
  }
}
