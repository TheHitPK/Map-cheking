package com.asistencia.employee.domain;

import com.asistencia.shared.domain.InvalidInputException;

/**
 * A worker or supervisor. {@code document} (cédula) is the login name.
 *
 * @param id null until persisted
 */
public record Employee(Long id, String document, String fullName, Role role, String passwordHash, boolean active) {

    public Employee {
        document = document == null ? "" : document.trim();
        fullName = fullName == null ? "" : fullName.trim();
        if (!document.matches("[A-Za-z0-9.-]{3,32}")) {
            throw new InvalidInputException("Documento inválido: use de 3 a 32 letras, números, punto o guion.");
        }
        if (fullName.length() < 3 || fullName.length() > 120) {
            throw new InvalidInputException("El nombre debe tener entre 3 y 120 caracteres.");
        }
        if (role == null) {
            throw new InvalidInputException("Rol requerido.");
        }
    }

    public Employee withPasswordHash(String hash) {
        return new Employee(id, document, fullName, role, hash, active);
    }

    public Employee withId(long newId) {
        return new Employee(newId, document, fullName, role, passwordHash, active);
    }
}
