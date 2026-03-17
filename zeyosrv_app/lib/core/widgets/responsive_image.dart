import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ResponsiveImage extends StatelessWidget {
  final String path;
  final BoxFit fit;

  const ResponsiveImage({super.key, required this.path, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // On Web, Image.network handles blob URLs (which XFile.path provides)
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
             return const Center(child: Icon(Icons.error));
        },
      );
    } else {
      // On Mobile, use Image.file
      return Image.file(
        File(path),
        fit: fit,
      );
    }
  }
}
