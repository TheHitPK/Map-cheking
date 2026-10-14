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
