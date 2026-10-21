package com.asistencia.attendance.adapter.in.web;

import com.asistencia.attendance.application.AttendanceQueryService;
import com.asistencia.attendance.application.AttendanceQueryService.DailyRow;
import com.asistencia.attendance.application.AttendanceQueryService.DayState;
import com.asistencia.attendance.application.AttendanceQueryService.MarkRow;
import com.asistencia.attendance.domain.AttendanceMark;
import com.asistencia.config.AppProperties;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/attendance")
public class AttendanceController {

    static final MediaType TEXT_CSV = MediaType.parseMediaType("text/csv");

    public record DailyRowDto(long employeeId, String fullName, String document, long worksiteId, String worksiteName,
                              LocalTime shiftStart, LocalTime shiftEnd, DayState state, MarkDto in, MarkDto out,
                              boolean earlyLeave, boolean onSite, int rejectedAttempts) {

        static DailyRowDto of(DailyRow r) {
            return new DailyRowDto(r.employee().id(), r.employee().fullName(), r.employee().document(),
                    r.shift().worksiteId(), r.worksite() == null ? "" : r.worksite().name(), r.shift().start(),
                    r.shift().end(), r.state(), r.firstIn().map(MarkDto::of).orElse(null),
                    r.lastOut().map(MarkDto::of).orElse(null), r.earlyLeave(), r.onSite(), r.rejectedAttempts());
        }
    }

    public record MarkRowDto(long employeeId, String employeeName, String employeeDocument, Long worksiteId,
                             String worksiteName, MarkDto mark) {

        static MarkRowDto of(MarkRow r) {
            return new MarkRowDto(r.mark().employeeId(), r.employeeName(), r.employeeDocument(), r.mark().worksiteId(),
                    r.worksiteName(), MarkDto.of(r.mark()));
        }
    }

    private final AttendanceQueryService queries;
    private final ZoneId zone;

    public AttendanceController(AttendanceQueryService queries, AppProperties props) {
        this.queries = queries;
        this.zone = props.zone();
    }

    @GetMapping("/daily")
    public List<DailyRowDto> daily(@RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
                                   @RequestParam(required = false) Long worksiteId) {
        return queries.daily(date, worksiteId).stream().map(DailyRowDto::of).toList();
    }

    @GetMapping(value = "/marks", produces = MediaType.APPLICATION_JSON_VALUE)
    public List<MarkRowDto> marks(@RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
                                  @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
                                  @RequestParam(required = false) Long worksiteId) {
        return queries.marks(from, to, worksiteId).stream().map(MarkRowDto::of).toList();
    }

    /** Same data as CSV (UTF-8 with BOM so Excel opens accents correctly; times in the official zone). */
    @GetMapping(value = "/marks", produces = "text/csv")
    public ResponseEntity<byte[]> marksCsv(@RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
                                           @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
                                           @RequestParam(required = false) Long worksiteId) {
        DateTimeFormatter fmt = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss").withZone(zone);
        StringBuilder csv = new StringBuilder("﻿");
        csv.append("fecha_hora;documento;empleado;obra;tipo;estado;motivo;distancia_m;precision_m;diferida\r\n");
        for (MarkRow r : queries.marks(from, to, worksiteId)) {
            AttendanceMark m = r.mark();
            csv.append(String.join(";",
                    fmt.format(m.recordedAt()),
                    cell(r.employeeDocument()),
                    cell(r.employeeName()),
                    cell(r.worksiteName()),
                    m.type().name(),
                    m.status().name(),
                    m.rejection() == null ? "" : m.rejection().name(),
                    m.distanceMeters() == null ? "" : Long.toString(Math.round(m.distanceMeters())),
                    Long.toString(Math.round(m.location().accuracyMeters())),
                    m.deferred() ? "si" : "no")).append("\r\n");
        }
        String filename = "asistencia_" + from + "_" + to + ".csv";
        return ResponseEntity.ok()
                .contentType(new MediaType(TEXT_CSV, StandardCharsets.UTF_8))
                .header(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + filename + "\"")
                .body(csv.toString().getBytes(StandardCharsets.UTF_8));
    }

    /** Quotes a field; neutralizes leading =,+,-,@ so spreadsheets do not run it as a formula. */
    static String cell(String value) {
        String v = value == null ? "" : value;
        if (!v.isEmpty() && "=+-@\t\r".indexOf(v.charAt(0)) >= 0) {
            v = "'" + v;
        }
        return "\"" + v.replace("\"", "\"\"") + "\"";
    }
}
