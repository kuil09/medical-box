import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../theme.dart';

class OfficialMedicineThumbnail extends StatelessWidget {
  const OfficialMedicineThumbnail({
    required this.imageUrl,
    required this.fallbackIcon,
    this.size = 46,
    this.backgroundColor = MedicalBoxColors.sky,
    this.borderRadius = 15,
    super.key,
  });

  final String? imageUrl;
  final Object fallbackIcon;
  final double size;
  final Color backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(imageUrl ?? '');
    final canLoadImage =
        uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: MedicalBoxColors.line),
      ),
      child: canLoadImage
          ? Image.network(
              uri.toString(),
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : _fallback(),
              errorBuilder: (_, __, ___) => _fallback(),
            )
          : _fallback(),
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
