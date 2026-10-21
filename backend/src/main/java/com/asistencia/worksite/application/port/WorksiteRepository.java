package com.asistencia.worksite.application.port;

import com.asistencia.worksite.domain.Worksite;
import java.util.List;
import java.util.Optional;

public interface WorksiteRepository {

    Optional<Worksite> findById(long id);

    /** Ordered by name. */
    List<Worksite> findAll();

    /** Inserts when {@code id} is null, updates otherwise. */
    Worksite save(Worksite worksite);
}
