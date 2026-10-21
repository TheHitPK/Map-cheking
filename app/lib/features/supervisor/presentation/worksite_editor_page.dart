import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../../../core/strings.dart';
import '../data/supervisor_api.dart';

/// Create or edit a worksite: tap the map (or type coordinates) for the centre, slider for the radius.
class WorksiteEditorPage extends ConsumerStatefulWidget {
  const WorksiteEditorPage({super.key, this.worksite});

  final Worksite? worksite;

  @override
  ConsumerState<WorksiteEditorPage> createState() => _WorksiteEditorPageState();
}

class _WorksiteEditorPageState extends ConsumerState<WorksiteEditorPage> {
  static const _defaultCenter = LatLng(39.8283, -98.5795); // contiguous US
  /// Backend accepts 20–2000 m (66–6561 ft).
  static const _minRadiusFt = 70.0, _maxRadiusFt = 6500.0;

  final _form = GlobalKey<FormState>();
  final _map = MapController();
  late final _name = TextEditingController(text: widget.worksite?.name);
  late final _address = TextEditingController(text: widget.worksite?.address);
  late final _lat = TextEditingController(text: widget.worksite?.lat.toStringAsFixed(6));
  late final _lon = TextEditingController(text: widget.worksite?.lon.toStringAsFixed(6));
  late double _radius = (widget.worksite?.radiusMeters ?? 100).toDouble(); // metres
  late bool _active = widget.worksite?.active ?? true;
  late LatLng? _center = widget.worksite == null ? null : LatLng(widget.worksite!.lat, widget.worksite!.lon);
  bool _saving = false;
  bool _locating = false;

  @override
  void dispose() {
    for (final c in [_name, _address, _lat, _lon]) {
      c.dispose();
    }
    super.dispose();
  }

  void _setCenter(LatLng p, {bool move = false}) {
    setState(() => _center = p);
    _lat.text = p.latitude.toStringAsFixed(6);
    _lon.text = p.longitude.toStringAsFixed(6);
    if (move) _map.move(p, 17);
  }

  void _centerFromFields() {
    final lat = double.tryParse(_lat.text.replaceAll(',', '.'));
    final lon = double.tryParse(_lon.text.replaceAll(',', '.'));
    if (lat != null && lon != null && lat.abs() <= 90 && lon.abs() <= 180) {
      setState(() => _center = LatLng(lat, lon));
      _map.move(_center!, _map.camera.zoom);
    }
  }

  Future<void> _useMyLocation() async {
    setState(() => _locating = true);
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        throw Exception(S.locationDenied);
      }
      final p = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 20)));
      _setCenter(LatLng(p.latitude, p.longitude), move: true);
    } catch (e) {
      if (mounted) showMessage(context, S.myLocationFailed, error: true);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_center == null) {
      showMessage(context, S.tapMapFirst, error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(supervisorApiProvider).saveWorksite(id: widget.worksite?.id, body: {
        'name': _name.text.trim(),
        'address': _address.text.trim(),
        'lat': _center!.latitude,
        'lon': _center!.longitude,
        'radiusMeters': _radius.round().clamp(20, 2000),
        'active': _active,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) showMessage(context, '$e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final map = _MapPicker(controller: _map, center: _center, radius: _radius, fallback: _defaultCenter, onTap: _setCenter);
    final form = _buildForm(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.worksite == null ? S.newSite : S.editSite),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Space.sm),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
              child: _saving ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text(S.save),
            ),
          ),
        ],
      ),
      body: wide
          ? Row(children: [
              SizedBox(width: 420, child: SingleChildScrollView(padding: const EdgeInsets.all(Space.xl), child: form)),
              const VerticalDivider(width: 1),
              Expanded(child: map),
            ])
          : ListView(padding: const EdgeInsets.all(Space.lg), children: [
              ClipRRect(borderRadius: BorderRadius.circular(16), child: SizedBox(height: 320, child: map)),
              const SizedBox(height: Space.lg),
              form,
            ]),
    );
  }

  Widget _buildForm(BuildContext context) {
    final t = Theme.of(context);
    final coord = FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'));
    return Form(
      key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(labelText: S.siteName),
          textCapitalization: TextCapitalization.sentences,
          validator: (v) => (v == null || v.trim().length < 2) ? S.siteNameRequired : null,
        ),
        const SizedBox(height: Space.lg),
        TextFormField(
          controller: _address,
          decoration: const InputDecoration(labelText: S.address),
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: Space.xl),
        Text(S.siteCenter, style: t.textTheme.titleSmall),
        const SizedBox(height: Space.xs),
        Text(S.siteCenterHelp,
            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        const SizedBox(height: Space.md),
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _lat,
              decoration: const InputDecoration(labelText: S.latitude),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [coord],
              onEditingComplete: _centerFromFields,
            ),
          ),
          const SizedBox(width: Space.md),
          Expanded(
            child: TextFormField(
              controller: _lon,
              decoration: const InputDecoration(labelText: S.longitude),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              inputFormatters: [coord],
              onEditingComplete: _centerFromFields,
            ),
          ),
        ]),
        const SizedBox(height: Space.md),
        OutlinedButton.icon(
          onPressed: _locating ? null : _useMyLocation,
          icon: _locating
              ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.my_location),
          label: const Text(S.useMyLocation),
        ),
        const SizedBox(height: Space.xl),
        Text(S.allowedRadius(Fmt.distance(_radius)), style: t.textTheme.titleSmall),
        // Edited in feet (US), stored in metres.
        Slider(
          value: (_radius * Fmt.feetPerMeter).clamp(_minRadiusFt, _maxRadiusFt),
          min: _minRadiusFt,
          max: _maxRadiusFt,
          divisions: ((_maxRadiusFt - _minRadiusFt) / 10).round(),
          label: Fmt.distance(_radius),
          semanticFormatterCallback: (v) => '${v.round()} feet',
          onChanged: (v) => setState(() => _radius = v / Fmt.feetPerMeter),
        ),
        Text(S.radiusHelp,
            style: t.textTheme.bodySmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
        if (widget.worksite != null) ...[
          const SizedBox(height: Space.lg),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _active,
            onChanged: (v) => setState(() => _active = v),
            title: const Text(S.siteActive),
            subtitle: const Text(S.siteActiveHelp),
          ),
        ],
      ]),
    );
  }
}

class _MapPicker extends StatelessWidget {
  const _MapPicker({required this.controller, required this.center, required this.radius, required this.fallback, required this.onTap});

  final MapController controller;
  final LatLng? center;
  final double radius;
  final LatLng fallback;
  final void Function(LatLng) onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Semantics(
      label: S.mapSemantics,
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: center ?? fallback,
          initialZoom: center == null ? 4 : 17,
          onTap: (_, p) => onTap(p),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.asistencia',
          ),
          if (center != null) ...[
            CircleLayer(circles: [
              CircleMarker(
                point: center!,
                radius: radius,
                useRadiusInMeter: true,
                color: c.primary.withValues(alpha: 0.18),
                borderColor: c.primary,
                borderStrokeWidth: 2,
              ),
            ]),
            MarkerLayer(markers: [
              Marker(point: center!, width: 40, height: 40, alignment: Alignment.topCenter,
                  child: Icon(Icons.location_on, size: 40, color: c.primary)),
            ]),
          ],
          const RichAttributionWidget(attributions: [TextSourceAttribution('© OpenStreetMap')]),
        ],
      ),
    );
  }
}
