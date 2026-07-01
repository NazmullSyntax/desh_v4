import 'package:flutter/material.dart';
import 'app_network_image.dart';

/// Full-screen image preview with pinch-to-zoom, used from destination
/// galleries (hero image, place detail slider, etc.) so a tap on any photo
/// opens an immersive, swipeable, zoomable view — matching the
/// "Full Screen Preview" + "Image Zoom" requirement for every destination.
class FullscreenGalleryViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? heroTagPrefix;

  const FullscreenGalleryViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTagPrefix,
  });

  /// Convenience opener: pushes the viewer as a fullscreen route.
  static void open(
    BuildContext context, {
    required List<String> imageUrls,
    int initialIndex = 0,
    String? heroTagPrefix,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, __) => FadeTransition(
          opacity: animation,
          child: FullscreenGalleryViewer(
            imageUrls: imageUrls,
            initialIndex: initialIndex,
            heroTagPrefix: heroTagPrefix,
          ),
        ),
      ),
    );
  }

  @override
  State<FullscreenGalleryViewer> createState() => _FullscreenGalleryViewerState();
}

class _FullscreenGalleryViewerState extends State<FullscreenGalleryViewer> {
  late final PageController _controller = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final url = widget.imageUrls[i];
                final child = InteractiveViewer(
                  minScale: 1,
                  maxScale: 5,
                  child: Center(
                    child: AppNetworkImage(url: url, fit: BoxFit.contain),
                  ),
                );
                if (widget.heroTagPrefix == null) return child;
                return Hero(tag: '${widget.heroTagPrefix}_$i', child: child);
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            if (widget.imageUrls.length > 1)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Text(
                  '${_index + 1} / ${widget.imageUrls.length}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
