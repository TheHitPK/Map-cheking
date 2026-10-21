package com.asistencia.schedule.application.port;

import com.asistencia.schedule.domain.Shift;
import java.util.List;
import java.util.Optional;

/** One shift per employee. */
public interface ShiftRepository {

    Optional<Shift> findByEmployee(long employeeId);

    List<Shift> findAll();

    /** Replaces the employee's shift. */
    Shift save(Shift shift);

    boolean deleteByEmployee(long employeeId);
}
