import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme.dart';
import 'official_cached_image.dart';

class OfficialMedicineThumbnail extends StatelessWidget {
  const OfficialMedicineThumbnail({
    required this.imageUrl,
    required this.fallbackIcon,
    this.imageBytes,
    this.size = 46,
    this.backgroundColor = MedicalBoxColors.sky,
    this.borderRadius = 15,
    super.key,
  });

  final String? imageUrl;
  final Uint8List? imageBytes;
  final Object fallbackIcon;
  final double size;
  final Color backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: MedicalBoxColors.line),
      ),
      child: imageBytes?.isNotEmpty == true
          ? Image.memory(
              imageBytes!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            )
          : OfficialCachedImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholderBuilder: (_) => _fallback(),
            ),
    );
  }

  Widget _fallback() {
    return Center(
      child: PhosphorIcon(
        fallbackIcon,
        color: MedicalBoxColors.ink,
        size: size * 0.48,
      ),
    );
  }
}
