package com.asistencia.shared.domain;

/** Input breaks a domain invariant. Message is user-facing (English). */
public class InvalidInputException extends RuntimeException {

    public InvalidInputException(String message) {
        super(message);
    }
}
