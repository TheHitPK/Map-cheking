package com.asistencia.auth.application.port;

import com.asistencia.employee.domain.Employee;
import java.time.Instant;

public interface TokenIssuer {

    IssuedToken issue(Employee employee);

    record IssuedToken(String value, Instant expiresAt) {
    }
}
