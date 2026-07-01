import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/app_colors.dart';

/// Drop-in replacement for [Image.network] that transparently supports
/// three kinds of sources, since this app mixes all of them depending on
/// what's wired up:
///  - Real network URLs (`http://`/`https://`) — cached, with a shimmer
///    skeleton while loading
///  - Local device files (`file://` paths, e.g. a profile photo just
///    picked from the gallery, or the Mock storage backend's stand-in
///    "upload") — read straight off disk via [Image.file]
///  - Bundled asset paths (e.g. `assets/images/...`) — via [Image.asset]
///
/// All three fall back to the same neutral placeholder icon on error,
/// so a missing/broken image never crashes the app.
class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  bool get _isNetwork => url.startsWith('http://') || url.startsWith('https://');
  bool get _isLocalFile => url.startsWith('file://') || url.startsWith('/');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? BorderRadius.zero;

    Widget child;
    if (_isNetwork) {
      child = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, _) => _shimmer(isDark),
        errorWidget: (context, _, __) => _errorPlaceholder(isDark),
      );
    } else if (_isLocalFile) {
      final path = url.startsWith('file://') ? Uri.parse(url).toFilePath() : url;
      child = Image.file(
        File(path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, _, __) => _errorPlaceholder(isDark),
      );
    } else {
      // Bundled asset path (e.g. assets/images/...).
      child = Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, _, __) => _errorPlaceholder(isDark),
      );
    }

    return ClipRRect(borderRadius: radius, child: child);
  }

  Widget _shimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.cardDark : AppColors.borderLight,
      highlightColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: Container(width: width, height: height, color: Colors.grey),
    );
  }

  Widget _errorPlaceholder(bool isDark) {
    return Container(
      width: width,
      height: height,
      color: isDark ? AppColors.cardDark : AppColors.borderLight,
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        size: 28,
      ),
    );
  }
}
