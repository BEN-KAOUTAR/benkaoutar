import 'package:flutter/material.dart';

class SpriteAvatar extends StatelessWidget {
  final int index;
  final double size;

  const SpriteAvatar({super.key, required this.index, required this.size});

  @override
  Widget build(BuildContext context) {
    // Safety check for 28 avatars (0-27)
    if (index < 0 || index > 27) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.person_outline_rounded, color: Colors.grey),
      );
    }

    // Files are saved as avatar_1.png to avatar_28.png (1-indexed) in assets/images/avatars/
    final assetPath = 'assets/images/avatars/avatar_${index + 1}.png';

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.withValues(alpha: 0.1),
          child: const Icon(Icons.person_outline_rounded, color: Colors.grey),
        ),
      ),
    );
  }
}
