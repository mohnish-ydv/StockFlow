import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../core/api.dart';
import '../core/location_service.dart';
import '../core/platform_ui.dart';
import '../core/theme.dart';
import '../widgets/sf_map.dart';
import '../widgets/sf_ui.dart';

String _pretty(String value) => value
    .replaceAll('_', ' ')
    .replaceAll('-', ' ')
    .split(' ')
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

class SellScreen extends StatefulWidget {
  final StockFlowApi api;
  const SellScreen({super.key, required this.api});

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  Future<Map<String, dynamic>>? _status;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _status = widget.api.sellerStatus();

  Future<void> _refresh() async {
    await widget.api.me();
    if (!mounted) return;
    setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _status,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(padding: EdgeInsets.all(18), child: SfListSkeleton(rows: 5));
        }
        if (snapshot.hasError) {
          return _MessageState(
            icon: Icons.cloud_off_outlined,
            title: 'Seller tools unavailable',
            body: '${snapshot.error}',
            action: 'Try again',
            onTap: _refresh,
          );
        }
        final data = snapshot.data ?? const <String, dynamic>{};
        final status = '${data['sellerStatus'] ?? widget.api.currentUser?.sellerStatus ?? 'not_applied'}';
        if (status == 'approved') return _CreateListingFlow(api: widget.api);
        if (status == 'pending') return _SellerReviewState(data: data, onRefresh: _refresh);
        if (status == 'suspended' || status == 'banned') {
          return const _MessageState(
            icon: Icons.gpp_bad_outlined,
            title: 'Selling access unavailable',
            body: 'This seller profile requires an admin review before new stock can be submitted.',
          );
        }
        return _SellerApplication(
          api: widget.api,
          previous: data['application'] is Map ? Map<String, dynamic>.from(data['application'] as Map) : null,
          rejected: status == 'rejected',
          onSubmitted: _refresh,
        );
      },
    );
  }
}

class _SellerReviewState extends StatelessWidget {
  final Map<String, dynamic> data;
  final Future<void> Function() onRefresh;
  const _SellerReviewState({required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final raw = data['application'];
    final app = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 120),
        children: [
          const Center(child: Icon(Icons.fact_check_outlined, size: 58, color: StockFlowTheme.accent)),
          const SizedBox(height: 18),
          Text('Seller verification under review', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          const Text('Your business profile is in the admin verification queue. You can keep browsing while we review it.', textAlign: TextAlign.center, style: TextStyle(color: StockFlowTheme.muted, height: 1.45)),
          const SizedBox(height: 26),
          _InfoPanel(
            children: [
              _InfoLine('Business', '${app['business_name'] ?? '—'}'),
              if ('${app['legal_name'] ?? ''}'.trim().isNotEmpty) _InfoLine('Legal name', '${app['legal_name']}'),
              _InfoLine('Seller type', _pretty('${app['seller_type'] ?? 'business'}')),
              if ('${app['gstin'] ?? ''}'.trim().isNotEmpty) _InfoLine('GSTIN', '${app['gstin']}'),
              if ('${app['udyam_number'] ?? ''}'.trim().isNotEmpty) _InfoLine('Udyam', '${app['udyam_number']}'),
              _InfoLine('Location', '${app['city'] ?? ''}, ${app['state'] ?? ''} ${app['pincode'] ?? ''}'),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(onPressed: onRefresh, icon: const Icon(Icons.refresh_rounded), label: const Text('Refresh status')),
        ],
      ),
    );
  }
}

class _SellerApplication extends StatefulWidget {
  final StockFlowApi api;
  final Map<String, dynamic>? previous;
  final bool rejected;
  final Future<void> Function() onSubmitted;
  const _SellerApplication({required this.api, required this.onSubmitted, this.previous, this.rejected = false});

  @override
  State<_SellerApplication> createState() => _SellerApplicationState();
}

class _SellerApplicationState extends State<_SellerApplication> {
  late final TextEditingController business;
  late final TextEditingController legalName;
  late final TextEditingController designation;
  late final TextEditingController gstin;
  late final TextEditingController pan;
  late final TextEditingController udyam;
  late final TextEditingController website;
  late final TextEditingController years;
  late final TextEditingController warehouses;
  late final TextEditingController volume;
  late final TextEditingController address;
  late final TextEditingController city;
  late final TextEditingController state;
  late final TextEditingController pincode;
  late final TextEditingController description;
  String sellerType = 'retailer';
  final Set<String> categories = <String>{};
  bool busy = false;

  static const _categoryOptions = ['electronics','mobiles','fashion','home-kitchen','furniture','industrial','automotive','beauty','sports','books','other'];

  @override
  void initState() {
    super.initState();
    final p = widget.previous ?? const <String, dynamic>{};
    TextEditingController c(String key) => TextEditingController(text: '${p[key] ?? ''}');
    business = c('business_name'); legalName = c('legal_name'); designation = c('contact_designation'); gstin = c('gstin'); pan = c('pan'); udyam = c('udyam_number'); website = c('website'); years = c('years_in_business'); warehouses = c('warehouse_count'); volume = c('monthly_stock_volume'); address = c('address'); city = c('city'); state = c('state'); pincode = c('pincode'); description = c('description');
    sellerType = '${p['seller_type'] ?? 'retailer'}';
    final rawCats = p['primary_categories'];
    if (rawCats is List) categories.addAll(rawCats.map((e) => '$e'));
  }

  @override
  void dispose() {
    for (final c in [business,legalName,designation,gstin,pan,udyam,website,years,warehouses,volume,address,city,state,pincode,description]) { c.dispose(); }
    super.dispose();
  }

  void _msg(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _submit() async {
    if (business.text.trim().length < 2 || address.text.trim().length < 5 || city.text.trim().isEmpty || state.text.trim().isEmpty || !RegExp(r'^\d{6}$').hasMatch(pincode.text.trim())) {
      _msg('Complete your business name and full 6-digit business address.');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.api.applySeller({
        'businessName': business.text.trim(),
        'legalName': legalName.text.trim(),
        'contactDesignation': designation.text.trim(),
        'sellerType': sellerType,
        'gstin': gstin.text.trim().toUpperCase(),
        'pan': pan.text.trim().toUpperCase(),
        'udyamNumber': udyam.text.trim(),
        'website': website.text.trim(),
        'yearsInBusiness': years.text.trim(),
        'warehouseCount': warehouses.text.trim(),
        'monthlyStockVolume': volume.text.trim(),
        'primaryCategories': categories.toList(),
        'address': address.text.trim(),
        'city': city.text.trim(),
        'state': state.text.trim(),
        'pincode': pincode.text.trim(),
        'description': description.text.trim(),
      });
      if (!mounted) return;
      _msg('Seller profile submitted for verification.');
      await widget.onSubmitted();
    } on ApiException catch (e) {
      _msg(e.message);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reason = '${widget.previous?['review_note'] ?? ''}'.trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
      children: [
        Text(widget.rejected ? 'Improve seller verification' : 'Become a verified seller', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 7),
        Text(widget.rejected ? 'Review the admin feedback, update your business profile and submit again.' : 'Business details help StockFlow keep the marketplace trustworthy. Tax/registration IDs are optional.', style: const TextStyle(color: StockFlowTheme.muted, height: 1.45)),
        if (widget.rejected && reason.isNotEmpty) ...[
          const SizedBox(height: 16),
          _ReviewFeedback(reason: reason),
        ],
        const SizedBox(height: 24),
        const _FormHeading(icon: Icons.storefront_outlined, title: 'Business identity', subtitle: 'Required basics plus optional verification signals'),
        const SizedBox(height: 12),
        TextField(controller: business, decoration: const InputDecoration(labelText: 'Business / shop name *')),
        const SizedBox(height: 10),
        TextField(controller: legalName, decoration: const InputDecoration(labelText: 'Legal business name (optional)')),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: sellerType,
          decoration: const InputDecoration(labelText: 'Seller type *'),
          items: const ['retailer','wholesaler','distributor','manufacturer','liquidator','other'].map((value) => DropdownMenuItem(value: value, child: Text(_pretty(value)))).toList(),
          onChanged: (value) => setState(() => sellerType = value ?? sellerType),
        ),
        const SizedBox(height: 10),
        TextField(controller: designation, decoration: const InputDecoration(labelText: 'Your role / designation (optional)')),
        const SizedBox(height: 22),
        const _FormHeading(icon: Icons.verified_user_outlined, title: 'Registration details', subtitle: 'Optional — helps admin review established businesses faster'),
        const SizedBox(height: 12),
        TextField(controller: gstin, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'GSTIN (optional)', hintText: '22AAAAA0000A1Z5')),
        const SizedBox(height: 10),
        TextField(controller: pan, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'PAN (optional)')),
        const SizedBox(height: 10),
        TextField(controller: udyam, decoration: const InputDecoration(labelText: 'Udyam / MSME number (optional)')),
        const SizedBox(height: 10),
        TextField(controller: website, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Website (optional)')),
        const SizedBox(height: 22),
        const _FormHeading(icon: Icons.inventory_2_outlined, title: 'Business capacity', subtitle: 'Optional operational context for marketplace review'),
        const SizedBox(height: 12),
        Row(children: [Expanded(child: TextField(controller: years, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Years in business'))), const SizedBox(width: 10), Expanded(child: TextField(controller: warehouses, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Warehouses')))]),
        const SizedBox(height: 10),
        TextField(controller: volume, decoration: const InputDecoration(labelText: 'Typical monthly surplus volume (optional)', hintText: 'e.g. 500–1,000 pieces')),
        const SizedBox(height: 12),
        const Text('Primary stock categories', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 7, runSpacing: 7, children: _categoryOptions.map((value) => FilterChip(label: Text(_pretty(value)), selected: categories.contains(value), onSelected: (selected) => setState(() => selected ? categories.add(value) : categories.remove(value)))).toList()),
        const SizedBox(height: 22),
        const _FormHeading(icon: Icons.location_on_outlined, title: 'Business address', subtitle: 'Used only for verification and operations'),
        const SizedBox(height: 12),
        TextField(controller: address, maxLines: 2, decoration: const InputDecoration(labelText: 'Full business address *', hintText: 'Building, street, area/locality')),
        const SizedBox(height: 10),
        Row(children: [Expanded(child: TextField(controller: city, decoration: const InputDecoration(labelText: 'City *'))), const SizedBox(width: 10), Expanded(child: TextField(controller: state, decoration: const InputDecoration(labelText: 'State *')))]),
        const SizedBox(height: 10),
        TextField(controller: pincode, maxLength: 6, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Pincode *', counterText: '')),
        const SizedBox(height: 10),
        TextField(controller: description, maxLines: 3, decoration: const InputDecoration(labelText: 'About your business / stock (optional)')),
        const SizedBox(height: 22),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: busy ? null : _submit, icon: busy ? const SizedBox(width: 18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(Icons.verified_rounded), label: Text(widget.rejected ? 'Resubmit for verification' : 'Submit for verification'))),
      ],
    );
  }
}

class _PickedMedia {
  final XFile file;
  final Uint8List bytes;
  final String mime;
  final bool isVideo;
  final double? durationSeconds;
  const _PickedMedia({required this.file, required this.bytes, required this.mime, required this.isVideo, this.durationSeconds});
}

class _CreateListingFlow extends StatefulWidget {
  final StockFlowApi api;
  const _CreateListingFlow({required this.api});

  @override
  State<_CreateListingFlow> createState() => _CreateListingFlowState();
}

class _CreateListingFlowState extends State<_CreateListingFlow> {
  static const maxMedia = 8;
  static const maxVideos = 2;
  static const maxVideoSeconds = 30.0;

  final title = TextEditingController();
  final note = TextEditingController();
  final description = TextEditingController();
  final brand = TextEditingController();
  final price = TextEditingController();
  final originalPrice = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final moq = TextEditingController(text: '1');
  final house = TextEditingController();
  final street = TextEditingController();
  final locality = TextEditingController();
  final district = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final pincode = TextEditingController();
  final landmark = TextEditingController();
  final List<_PickedMedia> media = [];
  final ImagePicker picker = ImagePicker();

  int step = 0;
  String category = 'other';
  String condition = 'New Dead Stock';
  String unit = 'piece';
  String inventoryType = 'single';
  bool negotiable = true;
  bool pickup = true;
  bool shipping = false;
  bool cod = false;
  bool aiBusy = false;
  bool locationBusy = false;
  bool submitBusy = false;
  double? latitude;
  double? longitude;
  double? accuracyMeters;
  String uploadStatus = '';

  @override
  void initState() {
    super.initState();
    city.text = widget.api.currentUser?.city ?? '';
    state.text = widget.api.currentUser?.state ?? '';
  }

  @override
  void dispose() {
    for (final c in [title,note,description,brand,price,originalPrice,quantity,moq,house,street,locality,district,city,state,pincode,landmark]) { c.dispose(); }
    super.dispose();
  }

  void _msg(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  String _mime(XFile file) {
    final direct = file.mimeType?.toLowerCase();
    if (direct != null && direct.isNotEmpty) return direct;
    final name = file.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.mp4')) return 'video/mp4';
    if (name.endsWith('.mov')) return 'video/quicktime';
    return 'image/jpeg';
  }

  Future<double?> _videoDuration(XFile file) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.file(File(file.path));
      await controller.initialize();
      return controller.value.duration.inMilliseconds / 1000;
    } catch (_) {
      return null;
    } finally {
      await controller?.dispose();
    }
  }

  Future<void> _pickMedia() async {
    final remaining = maxMedia - media.length;
    if (remaining <= 0) { _msg('Maximum $maxMedia media items reached.'); return; }
    try {
      final List<XFile> files;
      if (remaining == 1) {
        final single = await picker.pickMedia(imageQuality: 82, maxWidth: 1800);
        files = single == null ? <XFile>[] : <XFile>[single];
      } else {
        files = await picker.pickMultipleMedia(limit: remaining, imageQuality: 82, maxWidth: 1800);
      }
      if (files.isEmpty) return;
      final accepted = <_PickedMedia>[];
      var videoCount = media.where((m) => m.isVideo).length;
      for (final file in files) {
        final mime = _mime(file), isVideo = mime.startsWith('video/'), bytes = await file.readAsBytes();
        if (isVideo) {
          if (videoCount >= maxVideos) { _msg('Maximum $maxVideos videos per listing.'); continue; }
          if (bytes.length > 10 * 1024 * 1024) { _msg('${file.name}: video must be 10 MB or smaller.'); continue; }
          final duration = await _videoDuration(file);
          if (duration == null || duration <= 0 || duration > maxVideoSeconds) { _msg('${file.name}: video must be $maxVideoSeconds seconds or shorter.'); continue; }
          videoCount++;
          accepted.add(_PickedMedia(file: file, bytes: bytes, mime: mime, isVideo: true, durationSeconds: duration));
        } else {
          if (!['image/jpeg','image/png','image/webp'].contains(mime)) { _msg('${file.name}: use JPG, PNG or WebP.'); continue; }
          if (bytes.length > 5 * 1024 * 1024) { _msg('${file.name}: image must be 5 MB or smaller.'); continue; }
          accepted.add(_PickedMedia(file: file, bytes: bytes, mime: mime, isVideo: false));
        }
      }
      if (!mounted) return;
      setState(() => media.addAll(accepted.take(maxMedia - media.length)));
    } catch (e) {
      _msg('Could not select media: $e');
    }
  }

  Future<void> _generateAi() async {
    if (title.text.trim().length < 3) { _msg('Add a clear product title first.'); return; }
    setState(() => aiBusy = true);
    try {
      final draft = await widget.api.aiListingAssist(title: title.text.trim(), note: note.text.trim());
      if (!mounted) return;
      setState(() {
        if ('${draft['suggestedTitle'] ?? ''}'.trim().isNotEmpty) title.text = '${draft['suggestedTitle']}';
        description.text = '${draft['description'] ?? description.text}';
        category = '${draft['categorySlug'] ?? category}';
      });
    } on ApiException catch (e) { _msg(e.message); } finally { if (mounted) setState(() => aiBusy = false); }
  }

  void _applyAddress(SfResolvedAddress a) {
    setState(() {
      latitude=a.latitude; longitude=a.longitude; accuracyMeters=a.accuracyMeters;
      if (a.addressLine1.isNotEmpty) house.text=a.addressLine1;
      if (a.street.isNotEmpty) street.text=a.street;
      if (a.locality.isNotEmpty) locality.text=a.locality;
      if (a.district.isNotEmpty) district.text=a.district;
      if (a.city.isNotEmpty) city.text=a.city;
      if (a.state.isNotEmpty) state.text=a.state;
      if (a.pincode.isNotEmpty) pincode.text=a.pincode;
    });
  }

  Future<void> _currentLocation() async {
    if (locationBusy) return;
    setState(() => locationBusy = true);
    try { _applyAddress(await SfLocationService.currentAddress()); }
    on SfLocationException catch (e) {
      _msg(e.message);
      if (e.canOpenSettings && mounted) {
        final open = await showDialog<bool>(context: context, builder: (context) => AlertDialog(title: const Text('Location access'), content: Text(e.message), actions: [TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('Not now')), FilledButton(onPressed:()=>Navigator.pop(context,true),child:Text(e.issue==SfLocationIssue.serviceDisabled?'Open location settings':'Open app settings'))]));
        if (open == true) await SfLocationService.openSettingsFor(e.issue);
      }
    } finally { if (mounted) setState(() => locationBusy = false); }
  }

  Future<void> _chooseOnMap() async {
    SfResolvedAddress? initial;
    if (latitude != null && longitude != null) {
      initial = SfResolvedAddress(latitude: latitude!, longitude: longitude!, accuracyMeters: accuracyMeters ?? 0, addressLine1: house.text, street: street.text, locality: locality.text, district: district.text, city: city.text, state: state.text, pincode: pincode.text, landmark: landmark.text, country: 'India', addressResolved: true);
    }
    final result = await Navigator.push<SfResolvedAddress>(context, SfPlatform.route(context, (_) => SfLocationPickerScreen(initialAddress: initial)));
    if (result != null) _applyAddress(result);
  }

  bool _validateStep() {
    if (step == 0) {
      if (!media.any((m) => !m.isVideo)) { _msg('Add at least one real product photo.'); return false; }
      if (title.text.trim().length < 3 || description.text.trim().length < 10) { _msg('Add a clear title and useful description.'); return false; }
    } else if (step == 1) {
      final p=double.tryParse(price.text), q=int.tryParse(quantity.text), m=int.tryParse(moq.text);
      if (p == null || p < 0 || q == null || q < 1 || m == null || m < 1 || m > q) { _msg('Check price, available quantity and MOQ.'); return false; }
    } else if (step == 2) {
      if (house.text.trim().isEmpty || (street.text.trim().isEmpty && locality.text.trim().isEmpty) || city.text.trim().isEmpty || state.text.trim().isEmpty || !RegExp(r'^\d{6}$').hasMatch(pincode.text.trim())) { _msg('Complete house/building, street/locality, city, state and 6-digit pincode.'); return false; }
      if (!pickup && !shipping) { _msg('Enable pickup or shipping.'); return false; }
    }
    return true;
  }

  Future<void> _submit() async {
    if (!_validateStep() || submitBusy) return;
    setState(() { submitBusy=true; uploadStatus='Preparing media…'; });
    try {
      final uploaded=<Map<String,dynamic>>[];
      for (var i=0;i<media.length;i++) {
        if (mounted) setState(() => uploadStatus='Uploading media ${i+1} of ${media.length}…');
        final m=media[i];
        final result=await widget.api.uploadMedia(m.bytes,m.mime,durationSeconds:m.durationSeconds);
        uploaded.add({
          'url':'${result['url'] ?? ''}', 'storagePath':'${result['storagePath'] ?? ''}', 'mediaType':m.isVideo?'video':'image', 'mimeType':m.mime, 'sizeBytes':m.bytes.length, if(m.durationSeconds!=null)'durationSeconds':m.durationSeconds,
        });
      }
      if (mounted) setState(() => uploadStatus='Submitting for admin review…');
      final item=await widget.api.createListing({
        'title':title.text.trim(),'description':description.text.trim(),'brand':brand.text.trim(),'categorySlug':category,'condition':condition,
        'sellingPrice':double.parse(price.text),'originalPrice':originalPrice.text.trim(),'availableQty':int.parse(quantity.text),'minimumOrderQuantity':int.parse(moq.text),
        'unit':unit,'inventoryType':inventoryType,'negotiable':negotiable,'pickupEnabled':pickup,'shippingEnabled':shipping,'codEnabled':shipping&&cod,
        'city':city.text.trim(),'state':state.text.trim(),'pincode':pincode.text.trim(),'media':uploaded,
      });
      await widget.api.saveListingLocation(listingId:item.id,addressLine1:house.text.trim(),street:street.text.trim(),locality:locality.text.trim(),district:district.text.trim(),city:city.text.trim(),state:state.text.trim(),pincode:pincode.text.trim(),landmark:landmark.text.trim(),latitude:latitude,longitude:longitude,accuracyMeters:accuracyMeters);
      if (!mounted) return;
      await showDialog<void>(context: context, builder: (context) => AlertDialog(icon: const Icon(Icons.fact_check_rounded,color:StockFlowTheme.accent,size:36), title: const Text('Submitted for review'), content: const Text('Your stock is not public yet. An admin will review the listing and media. If anything needs changes, the rejection reason will appear in My stock.'), actions: [FilledButton(onPressed:()=>Navigator.pop(context),child:const Text('Done'))]));
      _reset();
    } on ApiException catch(e){_msg(e.message);} catch(e){_msg('Could not submit stock: $e');}
    finally{if(mounted)setState(() {submitBusy=false;uploadStatus='';});}
  }

  void _reset() {
    for(final c in [title,note,description,brand,price,originalPrice,quantity,moq,house,street,locality,district,pincode,landmark]){c.clear();}
    quantity.text='1';moq.text='1';city.text=widget.api.currentUser?.city??'';state.text=widget.api.currentUser?.state??'';
    setState(() {media.clear();step=0;category='other';condition='New Dead Stock';unit='piece';inventoryType='single';negotiable=true;pickup=true;shipping=false;cod=false;latitude=null;longitude=null;accuracyMeters=null;});
  }

  @override
  Widget build(BuildContext context) {
    const labels=['Describe stock','Price & quantity','Fulfilment','Review'];
    return Scaffold(
      appBar: AppBar(title: const Text('Post stock')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(18,6,18,10), child: Column(children:[Row(children:[Text('Step ${step+1} of 4',style:const TextStyle(color:StockFlowTheme.muted,fontSize:11.5,fontWeight:FontWeight.w700)),const Spacer(),Text(labels[step],style:const TextStyle(fontSize:11.5,fontWeight:FontWeight.w800))]),const SizedBox(height:8),LinearProgressIndicator(value:(step+1)/4,minHeight:4,borderRadius:BorderRadius.circular(99))])),
        Expanded(child: AnimatedSwitcher(duration:const Duration(milliseconds:180),child:KeyedSubtree(key:ValueKey(step),child:switch(step){0=>_stepDescribe(),1=>_stepPrice(),2=>_stepFulfilment(),_=>_stepReview()}))),
        _bottomBar(),
      ]),
    );
  }

  Widget _stepDescribe() => ListView(padding:const EdgeInsets.fromLTRB(18,14,18,28),children:[
    Text('Show buyers the real stock',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:6),const Text('Add up to 8 media items. At least one photo is required; up to 2 videos, each 30 seconds / 10 MB max.',style:TextStyle(color:StockFlowTheme.muted,height:1.4)),const SizedBox(height:16),
    _MediaPicker(items:media,onAdd:_pickMedia,onRemove:(i)=>setState(()=>media.removeAt(i))),const SizedBox(height:18),
    TextField(controller:title,maxLength:140,decoration:const InputDecoration(labelText:'Product title *',hintText:'e.g. 80 units sealed LED bulbs')),const SizedBox(height:8),
    TextField(controller:note,maxLength:180,decoration:const InputDecoration(labelText:'One-line factual note (optional)')),const SizedBox(height:6),
    SizedBox(width:double.infinity,child:FilledButton.tonalIcon(onPressed:aiBusy?null:_generateAi,icon:aiBusy?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.auto_awesome_rounded),label:Text(aiBusy?'Generating…':'Generate description & category with AI'))),const SizedBox(height:14),
    DropdownButtonFormField<String>(initialValue:category,decoration:const InputDecoration(labelText:'Category *'),items:const ['electronics','mobiles','fashion','home-kitchen','furniture','industrial','automotive','beauty','sports','books','other'].map((v)=>DropdownMenuItem(value:v,child:Text(_pretty(v)))).toList(),onChanged:(v)=>setState(()=>category=v??category)),const SizedBox(height:10),
    TextField(controller:description,maxLines:5,maxLength:2200,decoration:const InputDecoration(labelText:'Detailed description *',alignLabelWithHint:true)),const SizedBox(height:10),
    TextField(controller:brand,decoration:const InputDecoration(labelText:'Brand / manufacturer (optional)')),const SizedBox(height:10),
    DropdownButtonFormField<String>(initialValue:condition,decoration:const InputDecoration(labelText:'Condition'),items:const ['New Dead Stock','Open Box','Like New','Used / Good','Refurbished'].map((v)=>DropdownMenuItem(value:v,child:Text(v))).toList(),onChanged:(v)=>setState(()=>condition=v??condition)),
  ]);

  Widget _stepPrice() => ListView(padding:const EdgeInsets.fromLTRB(18,14,18,28),children:[
    Text('Price the lot clearly',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:16),
    TextField(controller:price,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Selling price per unit *',prefixText:'₹ ')),const SizedBox(height:10),
    TextField(controller:originalPrice,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Reference / original price (optional)',prefixText:'₹ ')),const SizedBox(height:10),
    Row(children:[Expanded(child:TextField(controller:quantity,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Available qty *'))),const SizedBox(width:10),Expanded(child:TextField(controller:moq,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'MOQ *')))]),const SizedBox(height:10),
    Row(children:[Expanded(child:DropdownButtonFormField<String>(initialValue:unit,decoration:const InputDecoration(labelText:'Unit'),items:const ['piece','box','set','kg','lot'].map((v)=>DropdownMenuItem(value:v,child:Text(_pretty(v)))).toList(),onChanged:(v)=>setState(()=>unit=v??unit))),const SizedBox(width:10),Expanded(child:DropdownButtonFormField<String>(initialValue:inventoryType,decoration:const InputDecoration(labelText:'Stock type'),items:const ['single','bulk'].map((v)=>DropdownMenuItem(value:v,child:Text(_pretty(v)))).toList(),onChanged:(v)=>setState(()=>inventoryType=v??inventoryType)))]),const SizedBox(height:14),
    SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('Price can be negotiated',style:TextStyle(fontWeight:FontWeight.w700)),subtitle:const Text('Negotiation happens only through protected StockFlow deal flow.'),value:negotiable,onChanged:(v)=>setState(()=>negotiable=v)),
  ]);

  Widget _stepFulfilment() => ListView(padding:const EdgeInsets.fromLTRB(18,14,18,28),children:[
    Text('Fulfilment & stock location',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:6),const Text('Exact coordinates and address stay private. Buyers see only the city/state and an approximate 10 km area on the listing map.',style:TextStyle(color:StockFlowTheme.muted,height:1.4)),const SizedBox(height:16),
    _SwitchRow(icon:Icons.storefront_outlined,title:'Local pickup',subtitle:'StockFlow coordinates the pickup process.',value:pickup,onChanged:(v)=>setState(()=>pickup=v)),
    _SwitchRow(icon:Icons.local_shipping_outlined,title:'Shipping available',subtitle:'Allow delivery / checkout.',value:shipping,onChanged:(v)=>setState(()=>shipping=v)),
    _SwitchRow(icon:Icons.payments_outlined,title:'Cash on delivery',subtitle:'Available only when shipping is enabled.',value:shipping&&cod,onChanged:shipping?(v)=>setState(()=>cod=v):null),const SizedBox(height:18),
    Row(children:[Expanded(child:OutlinedButton.icon(onPressed:locationBusy?null:_currentLocation,icon:locationBusy?const SizedBox(width:17,height:17,child:CircularProgressIndicator(strokeWidth:2)):const Icon(Icons.my_location_rounded),label:const Text('Use current location'))),const SizedBox(width:10),Expanded(child:OutlinedButton.icon(onPressed:_chooseOnMap,icon:const Icon(Icons.map_outlined),label:const Text('Choose on map')))]),
    if(latitude!=null)...[const SizedBox(height:9),Row(children:[const Icon(Icons.check_circle_rounded,color:StockFlowTheme.success,size:17),const SizedBox(width:6),Expanded(child:Text('Map position attached privately • ${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)}',style:const TextStyle(color:StockFlowTheme.textSecondary,fontSize:11.5)))])],const SizedBox(height:16),
    TextField(controller:house,decoration:const InputDecoration(labelText:'House / Shop / Building *')),const SizedBox(height:10),TextField(controller:street,decoration:const InputDecoration(labelText:'Street / Road *')),const SizedBox(height:10),
    TextField(controller:locality,decoration:const InputDecoration(labelText:'Area / Locality *')),const SizedBox(height:10),TextField(controller:district,decoration:const InputDecoration(labelText:'District (optional)')),const SizedBox(height:10),
    Row(children:[Expanded(child:TextField(controller:city,decoration:const InputDecoration(labelText:'City / Town *'))),const SizedBox(width:10),Expanded(child:TextField(controller:state,decoration:const InputDecoration(labelText:'State *')))]),const SizedBox(height:10),
    TextField(controller:pincode,maxLength:6,keyboardType:TextInputType.number,decoration:const InputDecoration(labelText:'Pincode *',counterText:'')),const SizedBox(height:10),TextField(controller:landmark,decoration:const InputDecoration(labelText:'Landmark (optional)')),
  ]);

  Widget _stepReview() {
    final photoCount=media.where((m)=>!m.isVideo).length,videoCount=media.where((m)=>m.isVideo).length;
    return ListView(padding:const EdgeInsets.fromLTRB(18,14,18,28),children:[
      Text('Review before submission',style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:6),const Text('Nothing goes live immediately. StockFlow admin reviews the listing, media and marketplace safety before approval.',style:TextStyle(color:StockFlowTheme.muted,height:1.4)),const SizedBox(height:18),
      _InfoPanel(children:[_InfoLine('Title',title.text.trim()),_InfoLine('Media','$photoCount photo${photoCount==1?'':'s'}${videoCount>0?' • $videoCount video${videoCount==1?'':'s'}':''}'),_InfoLine('Category',_pretty(category)),_InfoLine('Price','₹${price.text} / $unit'),_InfoLine('Stock','${quantity.text} $unit • MOQ ${moq.text}'),_InfoLine('Location','${locality.text.isEmpty?city.text:locality.text}, ${state.text} ${pincode.text}')]),
      const SizedBox(height:14),Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:StockFlowTheme.brandWash,borderRadius:BorderRadius.circular(16)),child:const Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Icon(Icons.policy_outlined,color:StockFlowTheme.accent),SizedBox(width:10),Expanded(child:Text('After submission: Pending review → Admin approves and listing becomes public, or rejects with a reason you can fix and resubmit.',style:TextStyle(fontSize:12.5,height:1.4))) ])),
      if(submitBusy)...[const SizedBox(height:18),LinearProgressIndicator(borderRadius:BorderRadius.circular(99)),const SizedBox(height:8),Text(uploadStatus,textAlign:TextAlign.center,style:const TextStyle(color:StockFlowTheme.muted,fontSize:11.5))],
    ]);
  }

  Widget _bottomBar() => SafeArea(top:false,child:Container(padding:const EdgeInsets.fromLTRB(16,10,16,12),decoration:const BoxDecoration(color:StockFlowTheme.surface,border:Border(top:BorderSide(color:StockFlowTheme.line))),child:Row(children:[
    if(step>0)...[SizedBox(width:104,child:OutlinedButton(onPressed:submitBusy?null:()=>setState(()=>step--),child:const Text('Back'))),const SizedBox(width:10)],
    Expanded(child:FilledButton(onPressed:submitBusy?null:(){if(step<3){if(_validateStep())setState(()=>step++);}else{_submit();}},child:Text(step==3?'Submit for review':'Continue'))),
  ])));
}

class _MediaPicker extends StatelessWidget {
  final List<_PickedMedia> items;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  const _MediaPicker({required this.items,required this.onAdd,required this.onRemove});

  @override
  Widget build(BuildContext context) => SizedBox(height:126,child:ListView.separated(scrollDirection:Axis.horizontal,itemCount:items.length+1,separatorBuilder:(_,__)=>const SizedBox(width:9),itemBuilder:(context,index){
    if(index==items.length)return InkWell(onTap:onAdd,borderRadius:BorderRadius.circular(18),child:Container(width:112,decoration:BoxDecoration(color:StockFlowTheme.brandWash,borderRadius:BorderRadius.circular(18),border:Border.all(color:StockFlowTheme.lineStrong)),child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(Icons.add_photo_alternate_outlined,color:StockFlowTheme.accent,size:30),const SizedBox(height:7),Text(items.isEmpty?'Add media':'Add more',style:const TextStyle(fontSize:11.5,fontWeight:FontWeight.w800)),const SizedBox(height:2),Text('${items.length}/8',style:const TextStyle(fontSize:10,color:StockFlowTheme.muted))])));
    final m=items[index];return Stack(children:[ClipRRect(borderRadius:BorderRadius.circular(18),child:Container(width:112,height:126,color:m.isVideo?const Color(0xFF111318):StockFlowTheme.panel2,child:m.isVideo?Column(mainAxisAlignment:MainAxisAlignment.center,children:[const Icon(Icons.play_circle_fill_rounded,color:Colors.white,size:38),const SizedBox(height:5),Text('${m.durationSeconds?.round() ?? 0}s',style:const TextStyle(color:Colors.white,fontSize:10.5))]):Image.memory(m.bytes,fit:BoxFit.cover))),Positioned(left:7,bottom:7,child:Container(padding:const EdgeInsets.symmetric(horizontal:7,vertical:4),decoration:BoxDecoration(color:const Color(0xC9000000),borderRadius:BorderRadius.circular(999)),child:Text(index==0&&!m.isVideo?'Cover':m.isVideo?'Video':'Photo',style:const TextStyle(color:Colors.white,fontSize:9.5,fontWeight:FontWeight.w700)))),Positioned(right:5,top:5,child:IconButton.filledTonal(style:IconButton.styleFrom(backgroundColor:const Color(0xD9FFFFFF),minimumSize:const Size(32,32),padding:EdgeInsets.zero),onPressed:()=>onRemove(index),icon:const Icon(Icons.close_rounded,size:17))) ]);
  }));
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;final String title;final String subtitle;final bool value;final ValueChanged<bool>? onChanged;
  const _SwitchRow({required this.icon,required this.title,required this.subtitle,required this.value,required this.onChanged});
  @override Widget build(BuildContext context)=>ListTile(contentPadding:EdgeInsets.zero,leading:Icon(icon,color:StockFlowTheme.accent),title:Text(title,style:const TextStyle(fontSize:13.5,fontWeight:FontWeight.w700)),subtitle:Text(subtitle,style:const TextStyle(fontSize:11,color:StockFlowTheme.muted)),trailing:Switch(value:value,onChanged:onChanged));
}

class _FormHeading extends StatelessWidget {final IconData icon;final String title;final String subtitle;const _FormHeading({required this.icon,required this.title,required this.subtitle});@override Widget build(BuildContext context)=>Row(crossAxisAlignment:CrossAxisAlignment.start,children:[Container(width:36,height:36,decoration:BoxDecoration(color:StockFlowTheme.brandSoft,borderRadius:BorderRadius.circular(12)),child:Icon(icon,size:19,color:StockFlowTheme.accent)),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(title,style:const TextStyle(fontWeight:FontWeight.w800,fontSize:14)),const SizedBox(height:2),Text(subtitle,style:const TextStyle(color:StockFlowTheme.muted,fontSize:11.5,height:1.35))]))]);}
class _InfoPanel extends StatelessWidget {final List<Widget> children;const _InfoPanel({required this.children});@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:StockFlowTheme.panel2,borderRadius:BorderRadius.circular(18),border:Border.all(color:StockFlowTheme.line)),child:Column(children:children));}
class _InfoLine extends StatelessWidget {final String label;final String value;const _InfoLine(this.label,this.value);@override Widget build(BuildContext context)=>Padding(padding:const EdgeInsets.symmetric(vertical:7),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(width:105,child:Text(label,style:const TextStyle(color:StockFlowTheme.muted,fontSize:11.5))),Expanded(child:Text(value.isEmpty?'—':value,textAlign:TextAlign.right,style:const TextStyle(fontSize:12.5,fontWeight:FontWeight.w700))) ]));}
class _ReviewFeedback extends StatelessWidget {final String reason;const _ReviewFeedback({required this.reason});@override Widget build(BuildContext context)=>Container(padding:const EdgeInsets.all(14),decoration:BoxDecoration(color:const Color(0xFFFFF4F2),borderRadius:BorderRadius.circular(16),border:Border.all(color:const Color(0xFFFFD2CB))),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[const Icon(Icons.error_outline_rounded,color:StockFlowTheme.danger),const SizedBox(width:10),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[const Text('Admin feedback',style:TextStyle(fontWeight:FontWeight.w800)),const SizedBox(height:4),Text(reason,style:const TextStyle(fontSize:12.5,height:1.4))]))]));}
class _MessageState extends StatelessWidget {final IconData icon;final String title;final String body;final String? action;final Future<void> Function()? onTap;const _MessageState({required this.icon,required this.title,required this.body,this.action,this.onTap});@override Widget build(BuildContext context)=>ListView(padding:const EdgeInsets.fromLTRB(26,80,26,120),children:[Icon(icon,size:48,color:StockFlowTheme.muted),const SizedBox(height:16),Text(title,textAlign:TextAlign.center,style:Theme.of(context).textTheme.headlineSmall),const SizedBox(height:8),Text(body,textAlign:TextAlign.center,style:const TextStyle(color:StockFlowTheme.muted,height:1.45)),if(action!=null&&onTap!=null)...[const SizedBox(height:20),FilledButton(onPressed:()=>onTap!(),child:Text(action!))]]);}
