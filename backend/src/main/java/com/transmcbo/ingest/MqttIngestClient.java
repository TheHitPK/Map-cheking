package com.transmcbo.ingest;

import com.hivemq.client.mqtt.MqttClientSslConfig;
import com.hivemq.client.mqtt.MqttGlobalPublishFilter;
import com.hivemq.client.mqtt.datatypes.MqttQos;
import com.hivemq.client.mqtt.mqtt5.Mqtt5AsyncClient;
import com.hivemq.client.mqtt.mqtt5.Mqtt5Client;
import com.hivemq.client.mqtt.mqtt5.Mqtt5ClientBuilder;
import com.hivemq.client.mqtt.mqtt5.lifecycle.Mqtt5ClientDisconnectedContext;
import com.hivemq.client.mqtt.mqtt5.message.connect.Mqtt5Connect;
import com.transmcbo.auth.AuthProperties;
import com.transmcbo.auth.TokenService;
import com.transmcbo.proto.Token;
import io.micrometer.core.instrument.Counter;
import io.micrometer.core.instrument.MeterRegistry;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.boot.ssl.SslBundles;
import org.springframework.context.SmartLifecycle;
import org.springframework.stereotype.Component;

/**
 * Subscribes to all vehicle topics and hands every publish to {@link IngestHandler}.
 * EMQX disconnects a client when its JWT expires, so before that a second connection with a fresh token
 * joins the same shared-subscription group and only then the old one leaves: no gap, no duplicates.
 */
@Component
@ConditionalOnProperty(prefix = "transmcbo.mqtt", name = "enabled", havingValue = "true", matchIfMissing = true)
public class MqttIngestClient implements SmartLifecycle {

    static final Duration MAX_ROTATION_LEAD = Duration.ofMinutes(10);

    private static final Logger log = LoggerFactory.getLogger(MqttIngestClient.class);

    private final MqttProperties props;
    private final IngestHandler handler;
    private final TokenService tokens;
    private final Duration rotationPeriod;
    private final Counter rotations;
    private final MqttClientSslConfig sslConfig;
    private ScheduledExecutorService rotator;
    private volatile Mqtt5AsyncClient client;
    private volatile boolean running;

    public MqttIngestClient(MqttProperties props, IngestHandler handler, TokenService tokens, AuthProperties auth,
            MeterRegistry registry, SslBundles sslBundles) {
        this.sslConfig = !props.tls() ? null
                : props.sslBundle().isBlank() ? MqttClientSslConfig.builder().build() // JVM default trust (public CA)
                : MqttClientSslConfig.builder()
                        .trustManagerFactory(sslBundles.getBundle(props.sslBundle()).getManagers().getTrustManagerFactory())
                        .build();
        this.props = props;
        this.handler = handler;
        this.tokens = tokens;
        Duration ttl = auth.backendTokenTtl();
        Duration lead = ttl.dividedBy(4).compareTo(MAX_ROTATION_LEAD) < 0 ? ttl.dividedBy(4) : MAX_ROTATION_LEAD;
        this.rotationPeriod = ttl.minus(lead);
        this.rotations = registry.counter("mqtt.token.rotations");
    }

    @Override
    public void start() {
        client = newClient(new CompletableFuture<>());
        client.connect(connectMessage());
        rotator = Executors.newSingleThreadScheduledExecutor(Thread.ofPlatform().name("mqtt-token-rotator").daemon().factory());
        rotator.scheduleAtFixedRate(this::rotate, rotationPeriod.toMillis(), rotationPeriod.toMillis(), TimeUnit.MILLISECONDS);
        running = true;
    }

    /** Make-before-break: the old client disconnects only after the new one is subscribed. */
    private void rotate() {
        CompletableFuture<Void> subscribed = new CompletableFuture<>();
        Mqtt5AsyncClient next = newClient(subscribed);
        next.connect(connectMessage());
        subscribed.orTimeout(30, TimeUnit.SECONDS).whenComplete((v, e) -> {
            if (e != null || !running) {
                log.error("MQTT token rotation failed; keeping current connection", e);
                next.disconnect();
                return;
            }
            Mqtt5AsyncClient old = client;
            client = next;
            old.disconnect();
            rotations.increment();
            log.info("MQTT token rotated");
        });
    }

    /** {@code firstSubscribe} completes once the first subscription after connecting succeeds. */
    private Mqtt5AsyncClient newClient(CompletableFuture<Void> firstSubscribe) {
        Mqtt5AsyncClient[] self = new Mqtt5AsyncClient[1]; // listeners run after connect, when self[0] is set
        Mqtt5ClientBuilder builder = Mqtt5Client.builder()
                .identifier(props.clientIdPrefix() + "-" + UUID.randomUUID().toString().substring(0, 8))
                .serverHost(props.host())
                .serverPort(props.port());
        if (sslConfig != null) {
            builder = builder.sslConfig(sslConfig);
        }
        Mqtt5AsyncClient c = builder
                .automaticReconnect().initialDelay(1, TimeUnit.SECONDS).maxDelay(30, TimeUnit.SECONDS).applyAutomaticReconnect()
                .addConnectedListener(ctx -> subscribe(self[0]).whenComplete((v, e) -> {
                    if (e == null) {
                        firstSubscribe.complete(null);
                    } else {
                        firstSubscribe.completeExceptionally(e);
                    }
                }))
                .addDisconnectedListener(ctx -> {
                    log.warn("MQTT disconnected: {}", ctx.getCause().getMessage());
                    // Unexpected drop: reconnect with a fresh token in case the old one is close to expiry.
                    if (ctx instanceof Mqtt5ClientDisconnectedContext c5) {
                        c5.getReconnector().connect(connectMessage());
                    }
                })
                .buildAsync();
        self[0] = c;
        c.publishes(MqttGlobalPublishFilter.SUBSCRIBED,
                publish -> handler.onMessage(publish.getTopic().toString(), publish.getPayloadAsBytes()));
        return c;
    }

    private Mqtt5Connect connectMessage() {
        Token token = tokens.backend();
        String username = token.getUsername().isEmpty() ? "backend" : token.getUsername();
        return Mqtt5Connect.builder()
                .keepAlive(120)
                .cleanStart(true)
                .simpleAuth().username(username).password(token.getJwt().getBytes(StandardCharsets.UTF_8)).applySimpleAuth()
                .build();
    }

    private CompletableFuture<Void> subscribe(Mqtt5AsyncClient c) {
        return c.subscribeWith().topicFilter(props.subscription()).qos(MqttQos.AT_MOST_ONCE).send()
                .whenComplete((ack, e) -> {
                    if (e != null) {
                        log.error("MQTT subscribe to {} failed", props.subscription(), e);
                    } else {
                        log.info("MQTT subscribed to {}", props.subscription());
                    }
                })
                .thenApply(ack -> null);
    }

    @Override
    public void stop() {
        running = false;
        if (rotator != null) {
            rotator.shutdownNow();
        }
        if (client != null) {
            client.disconnect();
        }
    }

    @Override
    public boolean isRunning() {
        return running;
    }
}
