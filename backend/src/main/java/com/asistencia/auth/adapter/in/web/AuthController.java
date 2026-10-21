package com.asistencia.auth.adapter.in.web;

import com.asistencia.auth.application.AuthService;
import com.asistencia.employee.domain.Role;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AuthController {

    public record LoginRequest(@NotBlank @Size(max = 32) String document, @NotBlank @Size(max = 72) String password) {
    }

    public record LoginResponse(String token, Instant expiresAt, long employeeId, String fullName, Role role) {
    }

    private final AuthService auth;

    public AuthController(AuthService auth) {
        this.auth = auth;
    }

    @PostMapping("/auth/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest req, HttpServletRequest http) {
        AuthService.Session s = auth.login(req.document(), req.password(), http.getRemoteAddr());
        return new LoginResponse(s.token().value(), s.token().expiresAt(), s.employee().id(), s.employee().fullName(),
                s.employee().role());
    }
}
