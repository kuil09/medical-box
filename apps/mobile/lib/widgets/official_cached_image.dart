import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';

class OfficialCachedImage extends ConsumerWidget {
  const OfficialCachedImage({
    required this.imageUrl,
    required this.placeholderBuilder,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    super.key,
  });

  final String? imageUrl;
  final WidgetBuilder placeholderBuilder;
  final BoxFit fit;
  final double? width;
  final double? height;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uri = Uri.tryParse(imageUrl ?? '');
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return placeholderBuilder(context);
    }

    final state = ref.watch(officialImageBytesProvider(uri.toString()));
    return state.when(
      data: (bytes) {
        if (bytes == null || bytes.isEmpty) {
          return placeholderBuilder(context);
        }
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          alignment: alignment,
          gaplessPlayback: true,
          errorBuilder: (context, _, _) => placeholderBuilder(context),
        );
      },
      loading: () => placeholderBuilder(context),
      error: (_, _) => placeholderBuilder(context),
    );
  }
}
