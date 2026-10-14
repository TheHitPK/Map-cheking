package com.transmcbo.ingest;

import com.hivemq.client.mqtt.MqttGlobalPublishFilter;
import com.hivemq.client.mqtt.datatypes.MqttQos;
import com.hivemq.client.mqtt.mqtt5.Mqtt5AsyncClient;
import com.hivemq.client.mqtt.mqtt5.Mqtt5Client;
import com.hivemq.client.mqtt.mqtt5.lifecycle.Mqtt5ClientDisconnectedContext;
import com.hivemq.client.mqtt.mqtt5.message.connect.Mqtt5Connect;
import com.transmcbo.auth.TokenService;
import java.nio.charset.StandardCharsets;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.SmartLifecycle;
import org.springframework.stereotype.Component;

/** Subscribes to all vehicle topics and hands every publish to {@link IngestHandler}. */
@Component
@ConditionalOnProperty(prefix = "transmcbo.mqtt", name = "enabled", havingValue = "true", matchIfMissing = true)
public class MqttIngestClient implements SmartLifecycle {

    private static final Logger log = LoggerFactory.getLogger(MqttIngestClient.class);

    private final MqttProperties props;
    private final IngestHandler handler;
    private final TokenService tokens;
    private Mqtt5AsyncClient client;
    private volatile boolean running;

    public MqttIngestClient(MqttProperties props, IngestHandler handler, TokenService tokens) {
        this.props = props;
        this.handler = handler;
        this.tokens = tokens;
    }

    @Override
    public void start() {
        client = Mqtt5Client.builder()
                .identifier(props.clientIdPrefix() + "-" + UUID.randomUUID().toString().substring(0, 8))
                .serverHost(props.host())
                .serverPort(props.port())
                .automaticReconnect().initialDelay(1, TimeUnit.SECONDS).maxDelay(30, TimeUnit.SECONDS).applyAutomaticReconnect()
                .addConnectedListener(ctx -> subscribe())
                .addDisconnectedListener(ctx -> {
                    log.warn("MQTT disconnected: {}", ctx.getCause().getMessage());
                    // The token may have expired (EMQX disconnects at exp): reconnect with a fresh one.
                    if (ctx instanceof Mqtt5ClientDisconnectedContext c5) {
                        c5.getReconnector().connect(connectMessage());
                    }
                })
                .buildAsync();
        client.publishes(MqttGlobalPublishFilter.SUBSCRIBED,
                publish -> handler.onMessage(publish.getTopic().toString(), publish.getPayloadAsBytes()));
        client.connect(connectMessage());
        running = true;
    }

    private Mqtt5Connect connectMessage() {
        return Mqtt5Connect.builder()
                .keepAlive(120)
                .cleanStart(true)
                .simpleAuth().username("backend").password(tokens.backend().getJwt().getBytes(StandardCharsets.UTF_8)).applySimpleAuth()
                .build();
    }

    private void subscribe() {
        client.subscribeWith().topicFilter(props.subscription()).qos(MqttQos.AT_MOST_ONCE).send()
                .whenComplete((ack, e) -> {
                    if (e != null) {
                        log.error("MQTT subscribe to {} failed", props.subscription(), e);
                    } else {
                        log.info("MQTT subscribed to {}", props.subscription());
                    }
                });
    }

    @Override
    public void stop() {
        running = false;
        if (client != null) {
            client.disconnect();
        }
    }

    @Override
    public boolean isRunning() {
        return running;
    }
}
