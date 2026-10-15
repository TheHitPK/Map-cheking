# TransMcbo — Rastreo en vivo del transporte público (Maracaibo)

## Objetivo MVP
El pasajero ve en un mapa dónde va un carrito/bus de una línea, a qué distancia está y en cuánto llega a su posición. El chofer solo activa el GPS.

## Restricciones (no negociables)
- Datos: pasajero < 50 KB/sesión (máx 500 KB/día); chofer ≈ 10–20 KB/h.
- Android gama baja, señal intermitente, cortes eléctricos.
- Rutas NO pregrabadas: el chofer elige su línea. (Suelen ser fijas: la fase 2 las aprende de las trazas.)
- Mapa 100 % offline. UI mínima: 1 pantalla por rol.

## Stack
- Apps: Flutter, un proyecto con flavors `chofer` / `pasajero` + paquete `core`.
- Backend: Spring Boot, Java 21+, virtual threads.
- MQTT 5 con broker EMQX. Protobuf para todos los mensajes.
- Redis (GEO) = posiciones vivas. PostgreSQL + PostGIS = historial de trazas.
- GraphHopper embebido, perfil `car`, `.osm.pbf` recortado a Maracaibo.
- Infra local: docker-compose (postgis, redis, emqx, backend).

## Protocolo
- Topic `v/{linea}/{veh}`: el chofer publica con QoS 0 y `retain=true` (el suscriptor nuevo recibe la última posición al instante, sin pedirla por HTTP).
- Last Will + "fuera de servicio" → publicar payload vacío retenido (borra el retained).
- Usar Topic Alias de MQTT 5 (no repetir el string del topic en cada publish). keepalive 120 s. TLS con session resumption.
- Auth: JWT corto emitido por el backend, usado como password MQTT. ACL: chofer solo publica en su topic; pasajero solo lee `v/#`.
- `Pos` (Protobuf, ~14 B): `veh` uint32, `ts` uint32 (s), `lat`/`lon` sint32 (grados × 1e6), `spd` uint32 (km/h), `hdg` uint32 (grados / 2).
- `PosBatch` (envío tras estar sin señal): primer punto absoluto, resto en deltas sint32 (zigzag).
- Chofer publica cada ≥ 50 m o 15 s (lo que ocurra primero); detenido → heartbeat cada 60 s. Cola offline en drift.
- Pasajero: suscribe a máx 3 vehículos; desconecta MQTT en background.

## Backend — concurrencia y rendimiento
- `spring.threads.virtual.enabled=true`. I/O bloqueante va en virtual threads.
- El callback MQTT NUNCA bloquea: decodifica, valida y hace:
  - `latest.put(veh, pos)` en un `ConcurrentHashMap` (coalescing: solo importa la última posición por vehículo);
  - `offer()` a una cola acotada (`ArrayBlockingQueue`) para el historial. Si está llena, descartar y contar la métrica.
- Flusher programado cada 1 s: Redis en pipeline (`GEOADD` + `HSET` + `EXPIRE` 120 s), solo vehículos que cambiaron.
- Escritor de historial con un solo hilo: insert por lotes / `COPY` a PostGIS cada 2 s o 1000 puntos.
- Validación: descartar `ts` ≤ último recibido, velocidad implícita > 120 km/h y saltos imposibles.
- GraphHopper: singleton cargado al arranque con el grafo precompilado en disco (no reimportar en cada arranque).
- Caché Caffeine de rutas con clave `(veh, geohash7 del pasajero)` y TTL 60 s.
- HTTP (respuestas Protobuf):
  - `GET /lineas`: cacheable con ETag.
  - `GET /lineas/{id}/cercanos?lat&lon`: Redis `GEOSEARCH` en radios escalonados 3 → 8 → 20 km (gana el primero con alguno acercándose); filtra los que se acercan (rumbo hacia el pasajero / distancia decreciente); máx 3.
  - `GET /ruta?veh&lat&lon`: polyline codificada + distancia (≈ 1–2 KB).
- gzip solo para respuestas > 1 KB.
- Micrometer: msgs/s, tamaño de cola, descartes, latencia de flush.

## Apps Flutter
- Chofer: selector de línea + botón grande "En servicio". `flutter_foreground_task` + `geolocator` (precisión media, `distanceFilter` 50).
- Pasajero: mapa + selector de línea + tarjeta con distancia y ETA.
- Mapa: `flutter_map` + PMTiles vectorial offline de Maracaibo (`vector_map_tiles` + `vector_map_tiles_pmtiles`). Sin tiles online.
- ETA calculada en el teléfono:
  - snap del vehículo a la polyline (buscar desde el último índice de segmento);
  - distancia restante sobre la ruta;
  - velocidad EMA (α = 0.3, mínimo 8 km/h);
  - mostrar como rango ±25 %.
  - Desvío > 60 m en 2 lecturas seguidas → pedir ruta nueva.
- MQTT: `mqtt5_client` (no `mqtt_client`, que solo es 3.1.1 y no tiene Topic Alias).
- Estado: riverpod. Persistencia: drift (+ `drift_flutter`; `drift_dev`/`build_runner` solo dev). Mostrar en modo debug los KB consumidos en la sesión.

## Convenciones para Claude
- Respuestas breves; no expliques lo obvio.
- Ediciones puntuales; no reescribas archivos completos.
- No agregues dependencias fuera de este archivo sin preguntar.
- Antes de cada tarea: plan en ≤ 15 líneas y espera mi OK.
- Tests: JUnit 5 + Testcontainers (backend); tests unitarios en Dart para el snap a la polyline y la ETA.
- Código e identificadores en inglés; textos de la UI en español.
