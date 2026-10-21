package com.asistencia.worksite.adapter.in.web;

import com.asistencia.shared.domain.GeoPoint;
import com.asistencia.worksite.application.WorksiteService;
import com.asistencia.worksite.domain.Worksite;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/worksites")
public class WorksiteController {

    public record WorksiteDto(Long id, String name, String address, double lat, double lon, int radiusMeters,
                              boolean active) {

        public static WorksiteDto of(Worksite w) {
            return new WorksiteDto(w.id(), w.name(), w.address(), w.center().lat(), w.center().lon(), w.radiusMeters(),
                    w.active());
        }
    }

    public record WorksiteRequest(@NotBlank @Size(max = 120) String name, @Size(max = 250) String address,
                                  @NotNull Double lat, @NotNull Double lon, @NotNull Integer radiusMeters,
                                  Boolean active) {

        Worksite toDomain() {
            return new Worksite(null, name, address, new GeoPoint(lat, lon), radiusMeters, active == null || active);
        }
    }

    private final WorksiteService worksites;

    public WorksiteController(WorksiteService worksites) {
        this.worksites = worksites;
    }

    @GetMapping
    public List<WorksiteDto> list() {
        return worksites.list().stream().map(WorksiteDto::of).toList();
    }

    @GetMapping("/{id}")
    public WorksiteDto get(@PathVariable long id) {
        return WorksiteDto.of(worksites.get(id));
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public WorksiteDto create(@Valid @RequestBody WorksiteRequest req) {
        return WorksiteDto.of(worksites.create(req.toDomain()));
    }

    @PutMapping("/{id}")
    public WorksiteDto update(@PathVariable long id, @Valid @RequestBody WorksiteRequest req) {
        return WorksiteDto.of(worksites.update(id, req.toDomain()));
    }
}
