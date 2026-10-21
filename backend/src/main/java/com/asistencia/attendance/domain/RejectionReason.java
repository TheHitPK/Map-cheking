package com.asistencia.attendance.domain;

/** Why a mark was rejected, with the message shown to the worker. */
public enum RejectionReason {
    NO_WORKSITE("No tiene una obra asignada. Contacte a su supervisor."),
    MOCK_LOCATION("Se detectó una ubicación simulada. Desactive apps de GPS falso."),
    LOW_ACCURACY("La señal GPS es imprecisa. Salga a cielo abierto e intente de nuevo."),
    CLOCK_AHEAD("La hora del teléfono no es correcta. Active la hora automática."),
    TOO_OLD("La marca se guardó hace demasiado tiempo sin conexión."),
    OUT_OF_ZONE("Está fuera del área de la obra."),
    ALREADY_IN("Ya marcó su llegada. Marque la salida primero."),
    NOT_IN("No tiene una llegada registrada. Marque la llegada primero.");

    private final String message;

    RejectionReason(String message) {
        this.message = message;
    }

    public String message() {
        return message;
    }
}
