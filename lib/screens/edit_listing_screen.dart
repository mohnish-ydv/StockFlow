import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../core/api.dart';
import '../core/models.dart';
import '../core/theme.dart';
import '../widgets/product_image.dart';

class EditListingScreen extends StatefulWidget {
  final StockFlowApi api;
  final Listing item;

  const EditListingScreen({super.key, required this.api, required this.item});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  static const maxMedia = 8;
  static const maxVideos = 2;
  static const maxVideoSeconds = 30.0;

  late final TextEditingController title;
  late final TextEditingController description;
  late final TextEditingController price;
  late final TextEditingController originalPrice;
  late final TextEditingController quantity;
  late final TextEditingController moq;
  late String category;
  bool busy = false;
  bool mediaChanged = false;
  final picker = ImagePicker();
  late final List<_EditMedia> media;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    title = TextEditingController(text: item.title);
    description = TextEditingController(text: item.description);
    price = TextEditingController(text: item.sellingPrice.toStringAsFixed(item.sellingPrice % 1 == 0 ? 0 : 2));
    originalPrice = TextEditingController(text: item.originalPrice == null ? '' : item.originalPrice!.toStringAsFixed(item.originalPrice! % 1 == 0 ? 0 : 2));
    quantity = TextEditingController(text: '${item.availableQty}');
    moq = TextEditingController(text: '${item.moq}');
    category = item.categorySlug;
    media = item.media
        .map((m) => _EditMedia.remote(
              url: m.url,
              mediaType: m.type,
              mimeType: m.mimeType,
              sizeBytes: m.sizeBytes,
              durationSeconds: m.durationSeconds,
            ))
        .toList();
    if (media.isEmpty && item.imageUrl.isNotEmpty) {
      media.add(_EditMedia.remote(url: item.imageUrl, mediaType: 'image', mimeType: 'image/jpeg'));
    }
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    price.dispose();
    originalPrice.dispose();
    quantity.dispose();
    moq.dispose();
    super.dispose();
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addMedia() async {
    final remaining = maxMedia - media.length;
    if (remaining <= 0) {
      _message('Maximum $maxMedia media items reached.');
      return;
    }
    try {
      final List<XFile> files;
      if (remaining == 1) {
        final single = await picker.pickMedia(imageQuality: 82, maxWidth: 1800);
        files = single == null ? <XFile>[] : <XFile>[single];
      } else {
        files = await picker.pickMultipleMedia(limit: remaining, imageQuality: 82, maxWidth: 1800);
      }
      if (files.isEmpty) return;
      final accepted = <_EditMedia>[];
      var videoCount = media.where((x) => x.isVideo).length;
      for (final file in files) {
        final mime = (file.mimeType ?? _mimeFromName(file.name)).toLowerCase();
        final bytes = await file.readAsBytes();
        if (mime.startsWith('video/')) {
          if (videoCount >= maxVideos) {
            _message('Maximum $maxVideos videos per listing.');
            continue;
          }
          if (bytes.lengthInBytes > 10 * 1024 * 1024) {
            _message('${file.name}: video must be 10 MB or smaller.');
            continue;
          }
          final duration = await _videoDuration(file.path);
          if (duration == null || duration <= 0 || duration > maxVideoSeconds) {
            _message('${file.name}: video must be ${maxVideoSeconds.toInt()} seconds or shorter.');
            continue;
          }
          accepted.add(_EditMedia.local(file: file, bytes: bytes, mediaType: 'video', mimeType: mime, durationSeconds: duration));
          videoCount++;
        } else {
          final normalized = ['image/jpeg', 'image/png', 'image/webp'].contains(mime) ? mime : 'image/jpeg';
          if (bytes.lengthInBytes > 5 * 1024 * 1024) {
            _message('${file.name}: photo must be 5 MB or smaller.');
            continue;
          }
          accepted.add(_EditMedia.local(file: file, bytes: bytes, mediaType: 'image', mimeType: normalized));
        }
      }
      if (!mounted || accepted.isEmpty) return;
      setState(() {
        media.addAll(accepted.take(maxMedia - media.length));
        mediaChanged = true;
      });
    } catch (_) {
      _message('Could not open the media picker.');
    }
  }

  Future<double?> _videoDuration(String path) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(path));
      await controller.initialize();
      return controller.value.duration.inMilliseconds / 1000;
    } catch (_) {
      return null;
    } finally {
      await controller?.dispose();
    }
  }

  String _mimeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  bool _validate() {
    if (title.text.trim().length < 3) {
      _message('Add a clearer product title.');
      return false;
    }
    if (description.text.trim().length < 10) {
      _message('Add a useful product description.');
      return false;
    }
    if (double.tryParse(price.text.trim()) == null || double.parse(price.text.trim()) < 0) {
      _message('Enter a valid selling price.');
      return false;
    }
    final qty = int.tryParse(quantity.text.trim());
    final minimum = int.tryParse(moq.text.trim());
    if (qty == null || qty < 1 || minimum == null || minimum < 1 || minimum > qty) {
      _message('Check available quantity and MOQ.');
      return false;
    }
    if (media.isEmpty || !media.any((x) => !x.isVideo)) {
      _message('Keep at least one product photo.');
      return false;
    }
    return true;
  }

  Future<List<Map<String, dynamic>>> _mediaPayload() async {
    final result = <Map<String, dynamic>>[];
    for (final entry in media) {
      if (entry.isRemote) {
        result.add({
          'url': entry.url,
          'mediaType': entry.mediaType,
          'mimeType': entry.mimeType,
          'sizeBytes': entry.sizeBytes,
          'durationSeconds': entry.durationSeconds,
        });
      } else {
        final upload = await widget.api.uploadMedia(
          entry.bytes!,
          entry.mimeType,
          durationSeconds: entry.durationSeconds,
        );
        result.add({
          'url': '${upload['url'] ?? ''}',
          'storagePath': '${upload['storagePath'] ?? ''}',
          'mediaType': '${upload['mediaType'] ?? entry.mediaType}',
          'mimeType': '${upload['mimeType'] ?? entry.mimeType}',
          'sizeBytes': upload['sizeBytes'] ?? entry.bytes!.lengthInBytes,
          'durationSeconds': upload['durationSeconds'] ?? entry.durationSeconds,
        });
      }
    }
    return result;
  }

  Future<void> _submit() async {
    if (busy || !_validate()) return;
    setState(() => busy = true);
    try {
      final payload = <String, dynamic>{
        'listingId': widget.item.id,
        'title': title.text.trim(),
        'description': description.text.trim(),
        'categorySlug': category,
        'sellingPrice': price.text.trim(),
        'originalPrice': originalPrice.text.trim(),
        'availableQty': quantity.text.trim(),
        'minimumOrderQuantity': moq.text.trim(),
      };
      if (mediaChanged) payload['media'] = await _mediaPayload();
      await widget.api.resubmitListing(payload);
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      _message(e.message);
    } catch (_) {
      _message('Could not resubmit this listing. Try again.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rejection = (widget.item.moderationNote ?? '').trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Fix listing')),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: FilledButton(
          onPressed: busy ? null : _submit,
          child: busy
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Resubmit for review'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
        children: [
          if (rejection.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD3CC)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.feedback_outlined, color: StockFlowTheme.danger, size: 20),
                  const SizedBox(width: 9),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Admin feedback', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(rejection, style: const TextStyle(fontSize: 12.5, height: 1.4)),
                  ])),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],
          Row(children: [
            Expanded(child: Text('Photos & videos', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800))),
            Text('${media.length}/$maxMedia', style: const TextStyle(color: StockFlowTheme.muted, fontSize: 12)),
          ]),
          const SizedBox(height: 6),
          const Text('Replace anything the moderator flagged. Keep at least one photo; up to 2 videos, 30 sec each.', style: TextStyle(color: StockFlowTheme.muted, fontSize: 11.5, height: 1.35)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: media.length + (media.length < maxMedia ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                if (index == media.length) {
                  return InkWell(
                    onTap: _addMedia,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 92,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: StockFlowTheme.lineStrong)),
                      child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate_outlined), SizedBox(height: 5), Text('Add media', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700))]),
                    ),
                  );
                }
                final entry = media[index];
                return Stack(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(width: 108, height: 100, child: entry.isVideo ? _VideoThumb(entry: entry) : _ImageThumb(entry: entry)),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: InkWell(
                      onTap: () {
                        if (media.length == 1) return _message('A listing needs at least one photo.');
                        setState(() { media.removeAt(index); mediaChanged = true; });
                      },
                      child: Container(width: 26, height: 26, decoration: BoxDecoration(color: Colors.black.withValues(alpha: .66), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 17)),
                    ),
                  ),
                  if (entry.isVideo) const Positioned(left: 6, bottom: 6, child: _MediaBadge(label: 'VIDEO')),
                  if (index == 0 && !entry.isVideo) const Positioned(left: 6, bottom: 6, child: _MediaBadge(label: 'COVER')),
                ]);
              },
            ),
          ),
          const SizedBox(height: 20),
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Product title')),
          const SizedBox(height: 10),
          TextField(controller: description, minLines: 4, maxLines: 7, decoration: const InputDecoration(labelText: 'Description')),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const ['electronics','mobiles','fashion','home-kitchen','furniture','industrial','automotive','beauty','sports','books','other']
                .map((value) => DropdownMenuItem(value: value, child: Text(value.replaceAll('-', ' '))))
                .toList(),
            onChanged: (value) => setState(() => category = value ?? category),
          ),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: price, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Selling price', prefixText: '₹ '))),
            const SizedBox(width: 9),
            Expanded(child: TextField(controller: originalPrice, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Reference price', prefixText: '₹ '))),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: quantity, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Available quantity'))),
            const SizedBox(width: 9),
            Expanded(child: TextField(controller: moq, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'MOQ'))),
          ]),
        ],
      ),
    );
  }
}

class _EditMedia {
  final XFile? file;
  final Uint8List? bytes;
  final String url;
  final String mediaType;
  final String mimeType;
  final int sizeBytes;
  final double? durationSeconds;

  const _EditMedia._({this.file, this.bytes, required this.url, required this.mediaType, required this.mimeType, this.sizeBytes = 0, this.durationSeconds});

  factory _EditMedia.remote({required String url, required String mediaType, required String mimeType, int sizeBytes = 0, double? durationSeconds}) =>
      _EditMedia._(url: url, mediaType: mediaType, mimeType: mimeType, sizeBytes: sizeBytes, durationSeconds: durationSeconds);

  factory _EditMedia.local({required XFile file, required Uint8List bytes, required String mediaType, required String mimeType, double? durationSeconds}) =>
      _EditMedia._(file: file, bytes: bytes, url: '', mediaType: mediaType, mimeType: mimeType, sizeBytes: bytes.lengthInBytes, durationSeconds: durationSeconds);

  bool get isRemote => file == null;
  bool get isVideo => mediaType == 'video';
}

class _ImageThumb extends StatelessWidget {
  final _EditMedia entry;
  const _ImageThumb({required this.entry});

  @override
  Widget build(BuildContext context) {
    if (entry.isRemote) return ProductImage(url: entry.url, category: 'other');
    return Image.memory(entry.bytes!, fit: BoxFit.cover);
  }
}

class _VideoThumb extends StatefulWidget {
  final _EditMedia entry;
  const _VideoThumb({required this.entry});

  @override
  State<_VideoThumb> createState() => _VideoThumbState();
}

class _VideoThumbState extends State<_VideoThumb> {
  VideoPlayerController? controller;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    controller = entry.isRemote ? VideoPlayerController.networkUrl(Uri.parse(entry.url)) : VideoPlayerController.file(File(entry.file!.path));
    controller!.initialize().then((_) { if (mounted) setState(() {}); }).catchError((_) {});
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;
    if (c == null || !c.value.isInitialized) return const ColoredBox(color: Color(0xFFE8EDF7), child: Center(child: Icon(Icons.videocam_outlined)));
    return Stack(fit: StackFit.expand, children: [FittedBox(fit: BoxFit.cover, child: SizedBox(width: c.value.size.width, height: c.value.size.height, child: VideoPlayer(c))), const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 32))]);
  }
}

class _MediaBadge extends StatelessWidget {
  final String label;
  const _MediaBadge({required this.label});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: .68), borderRadius: BorderRadius.circular(999)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800, letterSpacing: .4)),
      );
}
