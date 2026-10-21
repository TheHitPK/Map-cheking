package com.asistencia.attendance.adapter.in.web;

import com.asistencia.attendance.application.AttendanceQueryService;
import com.asistencia.attendance.application.RegisterMarkService;
import com.asistencia.attendance.domain.LocationReading;
import com.asistencia.attendance.domain.MarkAttempt;
import com.asistencia.attendance.domain.MarkType;
import com.asistencia.shared.domain.GeoPoint;
import com.asistencia.worksite.adapter.in.web.WorksiteController.WorksiteDto;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotNull;
import java.time.Clock;
import java.time.DayOfWeek;
import java.time.Instant;
import java.time.LocalTime;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** The signed-in worker's own endpoints; the employee id always comes from the token, never from the body. */
@RestController
@RequestMapping("/me")
public class MeController {

    public record MarkRequest(@NotNull UUID clientId, @NotNull MarkType type, @NotNull Double lat, @NotNull Double lon,
                              @NotNull Double accuracyMeters, boolean mocked, @NotNull Instant capturedAt) {
    }

    public record ShiftView(LocalTime start, LocalTime end, List<DayOfWeek> days, int graceMinutes) {
    }

    /** @param todayStart null when the worker has no shift today */
    public record TodayResponse(long employeeId, String fullName, WorksiteDto worksite, ShiftView shift,
                                Instant todayStart, Instant todayEnd, List<MarkDto> marks, MarkType next,
                                Instant serverTime) {
    }

    private final RegisterMarkService register;
    private final AttendanceQueryService queries;
    private final Clock clock;

    public MeController(RegisterMarkService register, AttendanceQueryService queries, Clock clock) {
        this.register = register;
        this.queries = queries;
        this.clock = clock;
    }

    @GetMapping("/today")
    public TodayResponse today(@AuthenticationPrincipal Jwt jwt) {
        AttendanceQueryService.Today t = queries.today(employeeId(jwt));
        return new TodayResponse(
                t.employee().id(),
                t.employee().fullName(),
                t.worksite().map(WorksiteDto::of).orElse(null),
                t.shift().map(s -> new ShiftView(s.start(), s.end(), s.days().stream().sorted().toList(),
                        s.graceMinutes())).orElse(null),
                t.occurrence().map(o -> o.start()).orElse(null),
                t.occurrence().map(o -> o.end()).orElse(null),
                t.marks().stream().map(MarkDto::of).toList(),
                t.next(),
                clock.instant());
    }

    /** 201 for a new mark (accepted or rejected: see {@code status}); 200 when replaying an already stored clientId. */
    @PostMapping("/marks")
    public ResponseEntity<MarkDto> mark(@AuthenticationPrincipal Jwt jwt, @Valid @RequestBody MarkRequest req) {
        MarkAttempt attempt = new MarkAttempt(req.clientId(), employeeId(jwt), req.type(),
                new LocationReading(new GeoPoint(req.lat(), req.lon()), req.accuracyMeters(), req.mocked()),
                req.capturedAt());
        RegisterMarkService.Result result = register.register(attempt);
        return ResponseEntity.status(result.replay() ? HttpStatus.OK : HttpStatus.CREATED)
                .body(MarkDto.of(result.mark()));
    }

    private static long employeeId(Jwt jwt) {
        return Long.parseLong(jwt.getSubject());
    }
}
