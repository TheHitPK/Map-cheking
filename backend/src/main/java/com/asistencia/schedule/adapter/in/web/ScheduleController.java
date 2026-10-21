package com.asistencia.schedule.adapter.in.web;

import com.asistencia.schedule.application.ScheduleService;
import com.asistencia.schedule.domain.Shift;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;
import java.util.Set;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

/** Shifts are keyed by employee (one each). */
@RestController
@RequestMapping("/schedules")
public class ScheduleController {

    public record ShiftDto(long id, long employeeId, long worksiteId, LocalTime start, LocalTime end,
                           List<DayOfWeek> days, int graceMinutes) {

        public static ShiftDto of(Shift s) {
            return new ShiftDto(s.id(), s.employeeId(), s.worksiteId(), s.start(), s.end(),
                    s.days().stream().sorted().toList(), s.graceMinutes());
        }
    }

    public record ShiftRequest(@NotNull Long worksiteId, @NotNull LocalTime start, @NotNull LocalTime end,
                               @NotEmpty Set<DayOfWeek> days, @NotNull Integer graceMinutes) {
    }

    private final ScheduleService schedules;

    public ScheduleController(ScheduleService schedules) {
        this.schedules = schedules;
    }

    @GetMapping
    public List<ShiftDto> list() {
        return schedules.list().stream().map(ShiftDto::of).toList();
    }

    @PutMapping("/{employeeId}")
    public ShiftDto assign(@PathVariable long employeeId, @Valid @RequestBody ShiftRequest req) {
        return ShiftDto.of(schedules.assign(new Shift(null, employeeId, req.worksiteId(), req.start(), req.end(),
                req.days(), req.graceMinutes())));
    }

    @DeleteMapping("/{employeeId}")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void remove(@PathVariable long employeeId) {
        schedules.remove(employeeId);
    }
}
