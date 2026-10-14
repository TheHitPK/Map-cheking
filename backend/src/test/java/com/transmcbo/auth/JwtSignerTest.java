package com.transmcbo.auth;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.List;
import org.junit.jupiter.api.Test;

class JwtSignerTest {

    static final String SECRET = "test-secret-0123456789abcdef-0123456789";

    static String payload(String jwt) {
        return new String(Base64.getUrlDecoder().decode(jwt.split("\\.")[1]), StandardCharsets.UTF_8);
    }

    @Test
    void signsVerifiableTokenWithAclClaim() {
        JwtSigner signer = new JwtSigner(SECRET);
        String jwt = signer.sign("veh:7", 1_800_000_000L, List.of(JwtSigner.AclRule.publish("v/12/7")));

        assertThat(jwt.split("\\.")).hasSize(3);
        assertThat(signer.verifySignature(jwt)).isTrue();
        assertThat(payload(jwt)).isEqualTo(
                "{\"sub\":\"veh:7\",\"exp\":1800000000,\"acl\":[{\"permission\":\"allow\",\"action\":\"publish\",\"topic\":\"v/12/7\"}]}");
    }

    @Test
    void rejectsTamperedOrForeignTokens() {
        JwtSigner signer = new JwtSigner(SECRET);
        String jwt = signer.sign("veh:7", 1L, List.of());
        String[] p = jwt.split("\\.");
        String forged = p[0] + "." + Base64.getUrlEncoder().withoutPadding()
                .encodeToString("{\"sub\":\"veh:8\",\"exp\":1,\"acl\":[]}".getBytes(StandardCharsets.UTF_8)) + "." + p[2];

        assertThat(signer.verifySignature(forged)).isFalse();
        assertThat(new JwtSigner(SECRET + "x").verifySignature(jwt)).isFalse();
    }

    @Test
    void escapesJsonStrings() {
        String jwt = new JwtSigner(SECRET).sign("a\"b\\c", 1L, List.of());
        assertThat(payload(jwt)).startsWith("{\"sub\":\"a\\\"b\\\\c\"");
    }

    @Test
    void requiresLongSecret() {
        assertThatThrownBy(() -> new JwtSigner("short")).isInstanceOf(IllegalArgumentException.class);
    }
}
