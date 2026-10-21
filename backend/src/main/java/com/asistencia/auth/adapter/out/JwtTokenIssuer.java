package com.asistencia.auth.adapter.out;

import com.asistencia.auth.application.port.TokenIssuer;
import com.asistencia.config.AppProperties;
import com.asistencia.config.SecurityConfig;
import com.asistencia.employee.domain.Employee;
import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Component;

@Component
public class JwtTokenIssuer implements TokenIssuer {

    private final JwtEncoder encoder;
    private final AppProperties props;
    private final Clock clock;

    public JwtTokenIssuer(JwtEncoder encoder, AppProperties props, Clock clock) {
        this.encoder = encoder;
        this.props = props;
        this.clock = clock;
    }

    @Override
    public IssuedToken issue(Employee employee) {
        Instant now = clock.instant().truncatedTo(ChronoUnit.SECONDS);
        Instant exp = now.plus(props.auth().tokenTtl());
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .subject(Long.toString(employee.id()))
                .issuedAt(now)
                .expiresAt(exp)
                .claim(SecurityConfig.ROLE_CLAIM, employee.role().name())
                .build();
        String token = encoder.encode(JwtEncoderParameters.from(JwsHeader.with(MacAlgorithm.HS256).build(), claims))
                .getTokenValue();
        return new IssuedToken(token, exp);
    }
}
