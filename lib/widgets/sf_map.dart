import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/location_service.dart';
import '../core/theme.dart';

const _tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _packageName = 'com.stockflow.stockflow';

class SfApproximateLocationMap extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double radiusKm;
  final double height;

  const SfApproximateLocationMap({
    super.key,
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10,
    this.height = 210,
  });

  @override
  Widget build(BuildContext context) {
    final center = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 10.4,
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
          ),
          children: [
            TileLayer(
              urlTemplate: _tileUrl,
              userAgentPackageName: _packageName,
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: center,
                  radius: radiusKm * 1000,
                  useRadiusInMeter: true,
                  color: StockFlowTheme.accent.withValues(alpha: .14),
                  borderColor: StockFlowTheme.accent.withValues(alpha: .72),
                  borderStrokeWidth: 2,
                ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [TextSourceAttribution('OpenStreetMap contributors')],
              showFlutterMapAttribution: false,
            ),
          ],
        ),
      ),
    );
  }
}

class SfLocationPickerScreen extends StatefulWidget {
  final SfResolvedAddress? initialAddress;

  const SfLocationPickerScreen({super.key, this.initialAddress});

  @override
  State<SfLocationPickerScreen> createState() => _SfLocationPickerScreenState();
}

class _SfLocationPickerScreenState extends State<SfLocationPickerScreen> {
  final MapController _controller = MapController();
  LatLng? _center;
  bool _booting = true;
  bool _resolving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    if (widget.initialAddress != null) {
      final a = widget.initialAddress!;
      setState(() {
        _center = LatLng(a.latitude, a.longitude);
        _booting = false;
      });
      return;
    }
    try {
      final position = await SfLocationService.current();
      if (!mounted) return;
      setState(() {
        _center = LatLng(position.latitude, position.longitude);
        _booting = false;
      });
    } on SfLocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _center = const LatLng(22.9734, 78.6569);
        _booting = false;
      });
    }
  }

  Future<void> _myLocation() async {
    try {
      final position = await SfLocationService.current();
      final point = LatLng(position.latitude, position.longitude);
      _controller.move(point, 16);
      if (mounted) setState(() => _center = point);
    } on SfLocationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      if (e.canOpenSettings) {
        await SfLocationService.openSettingsFor(e.issue);
      }
    }
  }

  Future<void> _confirm() async {
    final center = _center;
    if (center == null || _resolving) return;
    setState(() => _resolving = true);
    try {
      final address = await SfLocationService.resolveCoordinates(
        center.latitude,
        center.longitude,
      );
      if (!mounted) return;
      Navigator.pop(context, address);
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose stock location'),
        actions: [
          IconButton(
            tooltip: 'My current location',
            onPressed: _booting ? null : _myLocation,
            icon: const Icon(Icons.my_location_rounded),
          ),
        ],
      ),
      body: _booting || _center == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    initialCenter: _center!,
                    initialZoom: 16,
                    minZoom: 4,
                    maxZoom: 19,
                    onPositionChanged: (camera, _) {
                      if (camera.center != _center) _center = camera.center;
                    },
                  ),
                  children: [
                    TileLayer(urlTemplate: _tileUrl, userAgentPackageName: _packageName),
                    const RichAttributionWidget(
                      attributions: [TextSourceAttribution('OpenStreetMap contributors')],
                      showFlutterMapAttribution: false,
                    ),
                  ],
                ),
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 34),
                      child: Icon(Icons.location_on_rounded, size: 48, color: StockFlowTheme.accent),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: StockFlowTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(blurRadius: 24, offset: Offset(0, 10), color: Color(0x22000000))],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Move the map to the stock location', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(
                            _error ?? 'We will reverse-fill the available street, locality, city, state and pincode. You can edit every field before submitting.',
                            style: const TextStyle(color: StockFlowTheme.muted, fontSize: 11.5, height: 1.35),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _resolving ? null : _confirm,
                              icon: _resolving
                                  ? const SizedBox(width: 17, height: 17, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.check_rounded),
                              label: Text(_resolving ? 'Finding address…' : 'Use this location'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
