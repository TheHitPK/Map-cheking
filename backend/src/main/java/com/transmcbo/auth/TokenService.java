package com.transmcbo.auth;

import static com.transmcbo.auth.JwtSigner.AclRule.publish;
import static com.transmcbo.auth.JwtSigner.AclRule.subscribe;

import com.transmcbo.auth.AuthProperties.ClientBroker;
import com.transmcbo.auth.AuthProperties.Credentials;
import com.transmcbo.auth.AuthProperties.Mode;
import com.transmcbo.proto.Token;
import java.time.Clock;
import java.time.Duration;
import java.util.List;
import java.util.UUID;
import org.springframework.stereotype.Service;

/** Issues the MQTT passwords for each role. */
@Service
public class TokenService {

    private final JwtSigner signer;
    private final AuthProperties props;
    private final Clock clock;

    public TokenService(AuthProperties props, Clock clock) {
        this.signer = new JwtSigner(props.jwtSecret());
        this.props = props;
        this.clock = clock;
    }

    /** Driver may only publish its own live and batch topics (password mode: the broker's role ACL). */
    public Token driver(String line, int veh) {
        if (props.mode() == Mode.PASSWORD) {
            return fixed(props.driver());
        }
        String v = Integer.toUnsignedString(veh);
        String base = "v/" + line + "/" + v;
        return issue("veh:" + v, props.tokenTtl(), List.of(publish(base), publish(base + "/b")));
    }

    /** Passenger may only subscribe to single live topics (not batches, not v/#). */
    public Token passenger() {
        if (props.mode() == Mode.PASSWORD) {
            return fixed(props.passenger());
        }
        return issue("pas:" + UUID.randomUUID(), props.tokenTtl(), List.of(subscribe("v/+/+")));
    }

    public Token backend() {
        if (props.mode() == Mode.PASSWORD) {
            return fixed(props.backend());
        }
        return issue("backend", props.backendTokenTtl(), List.of(subscribe("v/#"), subscribe("$share/backend/v/#")));
    }

    private Token issue(String sub, Duration ttl, List<JwtSigner.AclRule> acl) {
        long exp = clock.millis() / 1000 + ttl.toSeconds();
        return withBroker(Token.newBuilder().setJwt(signer.sign(sub, exp, acl)).setExp((int) exp));
    }

    /** Fixed credentials; exp only makes the apps re-check the backend once a day. */
    private Token fixed(Credentials c) {
        long exp = clock.millis() / 1000 + props.passwordTokenTtl().toSeconds();
        return withBroker(Token.newBuilder().setJwt(c.password()).setUsername(c.username()).setExp((int) exp));
    }

    private Token withBroker(Token.Builder t) {
        ClientBroker b = props.clientBroker();
        if (b != null && !b.host().isBlank()) {
            t.setMqttHost(b.host()).setMqttPort(b.port()).setMqttTls(b.tls());
        }
        return t.build();
    }
}
