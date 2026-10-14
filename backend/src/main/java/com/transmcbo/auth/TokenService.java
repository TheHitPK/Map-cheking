package com.transmcbo.auth;

import static com.transmcbo.auth.JwtSigner.AclRule.publish;
import static com.transmcbo.auth.JwtSigner.AclRule.subscribe;

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

    /** Driver may only publish its own live and batch topics. */
    public Token driver(String line, int veh) {
        String v = Integer.toUnsignedString(veh);
        String base = "v/" + line + "/" + v;
        return issue("veh:" + v, props.tokenTtl(), List.of(publish(base), publish(base + "/b")));
    }

    /** Passenger may only subscribe to single live topics (not batches, not v/#). */
    public Token passenger() {
        return issue("pas:" + UUID.randomUUID(), props.tokenTtl(), List.of(subscribe("v/+/+")));
    }

    public Token backend() {
        return issue("backend", props.backendTokenTtl(), List.of(subscribe("v/#"), subscribe("$share/backend/v/#")));
    }

    private Token issue(String sub, Duration ttl, List<JwtSigner.AclRule> acl) {
        long exp = clock.millis() / 1000 + ttl.toSeconds();
        return Token.newBuilder().setJwt(signer.sign(sub, exp, acl)).setExp((int) exp).build();
    }
}
