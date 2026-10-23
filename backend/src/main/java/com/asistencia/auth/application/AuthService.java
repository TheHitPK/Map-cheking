package com.asistencia.auth.application;

import com.asistencia.auth.application.port.TokenIssuer;
import com.asistencia.auth.application.port.TokenIssuer.IssuedToken;
import com.asistencia.employee.application.port.EmployeeRepository;
import com.asistencia.employee.application.port.PasswordHasher;
import com.asistencia.employee.domain.Employee;
import java.util.Optional;

public class AuthService {

    /** Wrong document or password; deliberately does not say which. */
    public static class BadCredentialsException extends RuntimeException {

        public BadCredentialsException() {
            super("Wrong ID or password.");
        }
    }

    public static class TooManyAttemptsException extends RuntimeException {

        public TooManyAttemptsException() {
            super("Too many attempts. Wait 15 minutes and try again.");
        }
    }

    public record Session(IssuedToken token, Employee employee) {
    }

    /** Compared against when the document does not exist, so both paths cost the same (no user enumeration by timing). */
    private final String dummyHash;
    private final EmployeeRepository employees;
    private final PasswordHasher hasher;
    private final TokenIssuer tokens;
    private final LoginThrottle throttle;

    public AuthService(EmployeeRepository employees, PasswordHasher hasher, TokenIssuer tokens, LoginThrottle throttle) {
        this.employees = employees;
        this.hasher = hasher;
        this.tokens = tokens;
        this.throttle = throttle;
        this.dummyHash = hasher.hash("timing-equalizer");
    }

    public Session login(String document, String password, String clientIp) {
        String doc = document == null ? "" : document.trim();
        if (throttle.blocked(doc, clientIp)) {
            throw new TooManyAttemptsException();
        }
        Optional<Employee> found = employees.findByDocument(doc).filter(Employee::active);
        String pwd = password == null ? "" : password;
        boolean ok = hasher.matches(pwd, found.map(Employee::passwordHash).orElse(dummyHash)) && found.isPresent();
        if (!ok) {
            throttle.failed(doc, clientIp);
            throw new BadCredentialsException();
        }
        throttle.succeeded(doc);
        return new Session(tokens.issue(found.get()), found.get());
    }
}
