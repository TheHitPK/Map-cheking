# TransMcbo

Rastreo en vivo del transporte público de Maracaibo.

```
backend/   Spring Boot (Java 21, virtual threads)
app/       Flutter (flavors chofer / pasajero + paquete core)
proto/     Mensajes Protobuf (pos.proto)
docker-compose.yml   postgis, redis, emqx
```

## Infra local

```sh
cp .env.example .env
docker compose up -d
docker compose ps   # los 3 servicios deben quedar "healthy"
```

- PostGIS: `localhost:5434` (no 5432, para no chocar con un PostgreSQL local)
- Redis: `localhost:6379`
- EMQX: MQTT `1883`, TLS `8883`, dashboard http://localhost:18083 (admin / `EMQX_DASHBOARD_PASSWORD`)

## TLS

```sh
bash tools/gen-dev-certs.sh          # CA + certificado ECDSA de desarrollo en certs/ (y app/assets/certs/dev-ca.pem)
docker compose up -d emqx            # MQTT sobre TLS en 8883 (1883 en claro solo en desarrollo: MQTT_PLAIN=false lo apaga)
cd backend && ./mvnw spring-boot:run -Dspring-boot.run.profiles=tls   # HTTPS en 8443, MQTT TLS hacia EMQX
```

Apps: `--dart-define=API_URL=https://<IP>:8443 --dart-define=MQTT_PORT=8883 --dart-define=MQTT_TLS=true --dart-define=DEV_CA=true`.
En producción: certificado real y sin `DEV_CA`. `dart:io` no reanuda sesiones TLS: cada conexión cuesta un handshake completo (~1,6 KB con ECDSA).
