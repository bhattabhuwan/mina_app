import 'dart:io';

import 'package:flutter/material.dart';

ImageProvider? profileImageProvider(String? imagePathOrUrl) {
  if (imagePathOrUrl == null || imagePathOrUrl.trim().isEmpty) {
    return null;
  }

  final value = imagePathOrUrl.trim();
  final uri = Uri.tryParse(value);
  if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
    return NetworkImage(value);
  }

  final file = File(value);
  return file.existsSync() ? FileImage(file) : null;
}

class ProfileAvatar extends StatelessWidget {
  final String? imagePathOrUrl;
  final double radius;
  final double iconSize;
  final Color? backgroundColor;
  final bool showCameraBadge;

  const ProfileAvatar({
    super.key,
    required this.imagePathOrUrl,
    required this.radius,
    required this.iconSize,
    this.backgroundColor,
    this.showCameraBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final image = profileImageProvider(imagePathOrUrl);
    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? Colors.blue.shade300,
      backgroundImage: image,
      child: image == null
          ? Icon(Icons.person, size: iconSize, color: Colors.white)
          : null,
    );

    if (!showCameraBadge) return avatar;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        avatar,
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
        ),
      ],
    );
  }
}
