import 'dart:math' as math;

import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_map_tiles_pmtiles/vector_map_tiles_pmtiles.dart';

import 'offline_map.dart';
import 'pasajero_controller.dart';

final _tileProvider = FutureProvider((ref) => offlineTileProvider());

LatLng _ll(GeoPoint p) => LatLng(p.lat, p.lon);

const _maxZoom = 14.0;

/// The only passenger screen: offline map, line selector and the distance/ETA card.
class PasajeroScreen extends ConsumerStatefulWidget {
  const PasajeroScreen({super.key});

  @override
  ConsumerState<PasajeroScreen> createState() => _PasajeroScreenState();
}

class _PasajeroScreenState extends ConsumerState<PasajeroScreen> {
  final _map = MapController();

  void _centerOn(GeoPoint? p) {
    if (p != null) _map.move(_ll(p), _maxZoom);
  }

  @override
  Widget build(BuildContext context) {
    // First GPS fix: bring the map to the passenger.
    ref.listen(pasajeroProvider.select((s) => s.user), (prev, next) {
      if (prev == null) _centerOn(next);
    });
    final s = ref.watch(pasajeroProvider);
    final c = ref.read(pasajeroProvider.notifier);
    final tiles = ref.watch(_tileProvider);
    final theme = Theme.of(context);
    final view = s.view;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _ll(s.user ?? maracaibo),
              initialZoom: _maxZoom,
              minZoom: 11,
              maxZoom: _maxZoom, // deepest zoom in the bundled file; overzoom renders blank on devices
              cameraConstraint: CameraConstraint.contain(
                bounds: LatLngBounds(const LatLng(10.40, -72.0), const LatLng(10.95, -71.40)),
              ),
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              if (tiles.value case final provider?)
                VectorTileLayer(
                  theme: ProtomapsThemes.lightV4(), // Protomaps builds use basemap schema v4
                  tileProviders: TileProviders({'protomaps': provider}),
                  maximumZoom: _maxZoom,
                ),
              if (view.route.length >= 2)
                PolylineLayer(polylines: [
                  Polyline(points: view.route.map(_ll).toList(), strokeWidth: 5, color: theme.colorScheme.primary),
                ]),
              MarkerLayer(markers: [
                for (final v in view.vehicles)
                  Marker(
                    point: _ll(v.at),
                    width: 40,
                    height: 40,
                    child: Transform.rotate(
                      angle: v.headingDeg * math.pi / 180,
                      child: Icon(
                        Icons.navigation,
                        size: 34,
                        color: v.veh == view.targetVeh ? theme.colorScheme.primary : theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                if (s.user case final u?)
                  Marker(point: _ll(u), width: 36, height: 36, child: Icon(Icons.person_pin_circle, size: 36, color: theme.colorScheme.error)),
              ]),
            ],
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: s.lines.any((l) => l.id == s.line) ? s.line : null,
                    hint: const Text('Elige tu línea'),
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    items: [for (final l in s.lines) DropdownMenuItem(value: l.id, child: Text(l.name))],
                    onChanged: (v) => v == null ? null : c.selectLine(v),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: () async {
          await c.refresh();
          _centerOn(ref.read(pasajeroProvider).user);
        },
        tooltip: 'Actualizar',
        child: const Icon(Icons.my_location),
      ),
      bottomNavigationBar: SafeArea(child: _EtaCard(state: s)),
    );
  }
}

class _EtaCard extends StatelessWidget {
  const _EtaCard({required this.state});

  final PasajeroState state;

  static String distance(double m) => m < 1000 ? '${(m / 10).round() * 10} m' : '${(m / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';

  static String minutes(double s) => math.max(1, (s / 60).round()).toString();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final view = state.view;
    final eta = view.eta;

    final (String title, String? subtitle) = switch (view.status) {
      _ when state.line == null => ('Elige tu línea', 'Verás dónde viene la unidad y en cuánto llega'),
      _ when state.error != null && view.vehicles.isEmpty => (state.error!, null),
      PassengerStatus.loading => ('Buscando unidades…', null),
      PassengerStatus.noVehicles => ('No hay unidades acercándose', 'Ninguna a menos de 3 km. Toca actualizar en un rato'),
      PassengerStatus.error => ('Sin conexión', 'Toca actualizar para reintentar'),
      PassengerStatus.tracking when eta == null => ('Unidad ${view.targetVeh ?? ''} en camino', 'Calculando el tiempo de llegada…'),
      PassengerStatus.tracking when eta!.arrived => ('Unidad ${view.targetVeh} llegando', 'Está a menos de 30 m'),
      PassengerStatus.tracking => (
          'Llega en ${minutes(eta!.minSeconds)}–${minutes(eta.maxSeconds)} min',
          'Unidad ${view.targetVeh} · a ${distance(eta.remainingMeters)} por la ruta',
        ),
    };

    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            if (subtitle != null) ...[const SizedBox(height: 4), Text(subtitle, style: theme.textTheme.bodyMedium)],
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text('Datos de la sesión: ${state.kb.toStringAsFixed(1)} KB', style: theme.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
