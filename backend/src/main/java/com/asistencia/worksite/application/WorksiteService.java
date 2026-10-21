package com.asistencia.worksite.application;

import com.asistencia.shared.domain.NotFoundException;
import com.asistencia.worksite.application.port.WorksiteRepository;
import com.asistencia.worksite.domain.Worksite;
import java.util.List;

public class WorksiteService {

    private final WorksiteRepository worksites;

    public WorksiteService(WorksiteRepository worksites) {
        this.worksites = worksites;
    }

    public List<Worksite> list() {
        return worksites.findAll();
    }

    public Worksite get(long id) {
        return worksites.findById(id).orElseThrow(() -> new NotFoundException("Job site not found."));
    }

    public Worksite create(Worksite worksite) {
        return worksites.save(new Worksite(null, worksite.name(), worksite.address(), worksite.center(),
                worksite.radiusMeters(), true));
    }

    public Worksite update(long id, Worksite changes) {
        get(id);
        return worksites.save(changes.withId(id));
    }
}
