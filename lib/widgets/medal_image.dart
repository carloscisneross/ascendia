import 'package:flutter/material.dart';

class MedalImage extends StatelessWidget {
  final String assetPath;
  final double size;

  const MedalImage({
    super.key,
    required this.assetPath,
    this.size = 64.0,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      // This is the key for safe asset loading.
      // If the asset is not found, it will display a fallback.
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade300,
          ),
          child: Icon(
            Icons.shield_outlined,
            color: Colors.grey.shade600,
            size: size * 0.6,
          ),
        );
      },
    );
  }
}
