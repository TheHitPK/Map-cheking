package com.asistencia.employee.application.port;

public interface PasswordHasher {

    String hash(String raw);

    boolean matches(String raw, String hash);
}
