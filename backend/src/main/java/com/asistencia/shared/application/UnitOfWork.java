package com.asistencia.shared.application;

import java.util.function.Supplier;

/** Runs a block in one database transaction (keeps use cases free of Spring annotations). */
public interface UnitOfWork {

    <T> T inTransaction(Supplier<T> work);
}
