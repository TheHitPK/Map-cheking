package com.asistencia.shared.domain;

/** State conflict, e.g. a duplicate document number. */
public class ConflictException extends RuntimeException {

    public ConflictException(String message) {
        super(message);
    }
}
