package com.transmcbo.auth;

import static com.transmcbo.api.LinesController.PROTOBUF;

import com.google.protobuf.InvalidProtocolBufferException;
import com.transmcbo.api.LinesService;
import com.transmcbo.proto.DriverLogin;
import jakarta.servlet.http.HttpServletRequest;
import java.util.List;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AuthController {

    private final TokenService tokens;
    private final LinesService lines;
    private final JdbcTemplate jdbc;
    private final LoginLimiter limiter;

    public AuthController(TokenService tokens, LinesService lines, JdbcTemplate jdbc, LoginLimiter limiter) {
        this.tokens = tokens;
        this.lines = lines;
        this.jdbc = jdbc;
        this.limiter = limiter;
    }

    @PostMapping("/auth/chofer")
    public ResponseEntity<byte[]> driver(@RequestBody byte[] body, HttpServletRequest request) {
        DriverLogin login;
        try {
            login = DriverLogin.parseFrom(body);
        } catch (InvalidProtocolBufferException e) {
            return ResponseEntity.badRequest().build();
        }
        long veh = Integer.toUnsignedLong(login.getVeh());
        String ip = request.getRemoteAddr();
        if (limiter.blocked(veh, ip)) {
            return ResponseEntity.status(HttpStatus.TOO_MANY_REQUESTS)
                    .header(HttpHeaders.RETRY_AFTER, Long.toString(LoginLimiter.WINDOW.toSeconds())).build();
        }
        if (!lines.get().ids().contains(login.getLine())) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).build();
        }
        List<String> hash = jdbc.queryForList("SELECT pin_hash FROM vehicle WHERE id = ? AND active", String.class, veh);
        if (hash.isEmpty() || !PinHasher.matches(login.getPin(), hash.getFirst())) {
            limiter.failed(veh, ip);
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        limiter.succeeded(veh);
        return ResponseEntity.ok().contentType(PROTOBUF).body(tokens.driver(login.getLine(), login.getVeh()).toByteArray());
    }

    @PostMapping("/auth/pasajero")
    public ResponseEntity<byte[]> passenger() {
        return ResponseEntity.ok().contentType(PROTOBUF).body(tokens.passenger().toByteArray());
    }
}
