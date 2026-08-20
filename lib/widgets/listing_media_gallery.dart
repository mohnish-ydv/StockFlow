import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../core/models.dart';
import '../core/theme.dart';
import 'product_image.dart';

class ListingMediaGallery extends StatefulWidget {
  final Listing listing;
  final double height;

  const ListingMediaGallery({super.key, required this.listing, this.height = 360});

  @override
  State<ListingMediaGallery> createState() => _ListingMediaGalleryState();
}

class _ListingMediaGalleryState extends State<ListingMediaGallery> {
  final PageController _page = PageController();
  int _index = 0;

  List<ListingMedia> get _items => widget.listing.media.isEmpty
      ? [ListingMedia(id: 'fallback', url: widget.listing.imageUrl, type: 'image', mimeType: 'image/jpeg', sortOrder: 0, sizeBytes: 0)]
      : widget.listing.media;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          controller: _page,
          itemCount: items.length,
          onPageChanged: (value) => setState(() => _index = value),
          itemBuilder: (context, index) {
            final item = items[index];
            if (item.isVideo) return _NetworkVideo(url: item.url);
            return ProductImage(url: item.url, category: widget.listing.categorySlug, fit: BoxFit.cover);
          },
        ),
        if (items.length > 1)
          Positioned(
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(color: const Color(0xC9000000), borderRadius: BorderRadius.circular(999)),
              child: Text('${_index + 1}/${items.length}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          ),
        if (items.length > 1)
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  items.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: i == _index ? 18 : 6,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i == _index ? Colors.white : Colors.white54,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _NetworkVideo extends StatefulWidget {
  final String url;
  const _NetworkVideo({required this.url});

  @override
  State<_NetworkVideo> createState() => _NetworkVideoState();
}

class _NetworkVideoState extends State<_NetworkVideo> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
      await controller.initialize();
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_failed) {
      return const ColoredBox(
        color: StockFlowTheme.panel2,
        child: Center(child: Icon(Icons.videocam_off_outlined, color: StockFlowTheme.muted, size: 42)),
      );
    }
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(
        color: Color(0xFF111318),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
      );
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          controller.value.isPlaying ? controller.pause() : controller.play();
        });
      },
      child: ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio == 0 ? 16 / 9 : controller.value.aspectRatio,
                child: VideoPlayer(controller),
              ),
            ),
            if (!controller.value.isPlaying)
              const Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xB9000000), shape: BoxShape.circle),
                  child: Padding(
                    padding: EdgeInsets.all(15),
                    child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
                  ),
                ),
              ),
            const Positioned(
              left: 12,
              top: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xB9000000), borderRadius: BorderRadius.all(Radius.circular(999))),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.videocam_rounded, color: Colors.white, size: 14), SizedBox(width: 5), Text('Video', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700))]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
