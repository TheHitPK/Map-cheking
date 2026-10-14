package com.transmcbo.auth;

import java.nio.charset.StandardCharsets;
import java.security.GeneralSecurityException;
import java.security.MessageDigest;
import java.util.Base64;
import java.util.List;
import java.util.stream.Collectors;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;

/** Minimal HS256 JWT with the claims EMQX needs: sub, exp and an {@code acl} rule list. */
public final class JwtSigner {

    private static final Base64.Encoder B64 = Base64.getUrlEncoder().withoutPadding();
    private static final String HEADER = B64.encodeToString("{\"alg\":\"HS256\",\"typ\":\"JWT\"}".getBytes(StandardCharsets.UTF_8));

    private final SecretKeySpec key;

    public JwtSigner(String secret) {
        if (secret == null || secret.getBytes(StandardCharsets.UTF_8).length < 32) {
            throw new IllegalArgumentException("transmcbo.auth.jwt-secret must be at least 32 bytes");
        }
        this.key = new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256");
    }

    public String sign(String sub, long exp, List<AclRule> acl) {
        String rules = acl.stream().map(AclRule::toJson).collect(Collectors.joining(",", "[", "]"));
        String payload = "{\"sub\":" + AclRule.quote(sub) + ",\"exp\":" + exp + ",\"acl\":" + rules + "}";
        String unsigned = HEADER + "." + B64.encodeToString(payload.getBytes(StandardCharsets.UTF_8));
        return unsigned + "." + B64.encodeToString(hmac(unsigned));
    }

    /** True if the signature matches; does not check claims. */
    public boolean verifySignature(String jwt) {
        int dot = jwt.lastIndexOf('.');
        if (dot < 0) {
            return false;
        }
        byte[] expected = hmac(jwt.substring(0, dot));
        byte[] actual;
        try {
            actual = Base64.getUrlDecoder().decode(jwt.substring(dot + 1));
        } catch (IllegalArgumentException e) {
            return false;
        }
        return MessageDigest.isEqual(expected, actual);
    }

    private byte[] hmac(String data) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(key);
            return mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
        } catch (GeneralSecurityException e) {
            throw new IllegalStateException(e);
        }
    }

    /** One EMQX JWT ACL rule (EMQX >= 5.5 list format). */
    public record AclRule(String action, String topic) {

        public static AclRule publish(String topic) {
            return new AclRule("publish", topic);
        }

        public static AclRule subscribe(String topic) {
            return new AclRule("subscribe", topic);
        }

        String toJson() {
            return "{\"permission\":\"allow\",\"action\":" + quote(action) + ",\"topic\":" + quote(topic) + "}";
        }

        static String quote(String s) {
            StringBuilder sb = new StringBuilder(s.length() + 2).append('"');
            for (char ch : s.toCharArray()) {
                switch (ch) {
                    case '"' -> sb.append("\\\"");
                    case '\\' -> sb.append("\\\\");
                    default -> {
                        if (ch < 0x20) {
                            sb.append(String.format("\\u%04x", (int) ch));
                        } else {
                            sb.append(ch);
                        }
                    }
                }
            }
            return sb.append('"').toString();
        }
    }
}
