package com.asistencia.attendance.adapter.out.persistence;

import com.asistencia.attendance.application.port.MarkRepository;
import com.asistencia.attendance.domain.AttendanceMark;
import com.asistencia.attendance.domain.LocationReading;
import com.asistencia.attendance.domain.MarkStatus;
import com.asistencia.attendance.domain.MarkType;
import com.asistencia.attendance.domain.RejectionReason;
import com.asistencia.shared.domain.GeoPoint;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.Instant;
import java.time.OffsetDateTime;
import java.time.ZoneOffset;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class JdbcMarkRepository implements MarkRepository {

    private static final String COLUMNS = """
            id, client_id, employee_id, worksite_id, type, recorded_at, captured_at, received_at, lat, lon,
            accuracy_m, mocked, distance_m, status, rejection, deferred""";

    private final JdbcClient jdbc;

    public JdbcMarkRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<AttendanceMark> findByClientId(UUID clientId) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM attendance_mark WHERE client_id = ?")
                .param(clientId).query(this::map).optional();
    }

    @Override
    public Optional<AttendanceMark> lastAccepted(long employeeId) {
        return jdbc.sql("SELECT " + COLUMNS + """
                         FROM attendance_mark WHERE employee_id = ? AND status <> 'REJECTED'
                        ORDER BY recorded_at DESC, id DESC LIMIT 1""")
                .param(employeeId).query(this::map).optional();
    }

    @Override
    public void lockEmployee(long employeeId) {
        jdbc.sql("SELECT id FROM employee WHERE id = ? FOR UPDATE").param(employeeId).query(Long.class).optional();
    }

    @Override
    public Optional<AttendanceMark> insertIfAbsent(AttendanceMark m) {
        LocationReading loc = m.location();
        return jdbc.sql("""
                        INSERT INTO attendance_mark (client_id, employee_id, worksite_id, type, recorded_at, captured_at,
                            received_at, lat, lon, accuracy_m, mocked, distance_m, status, rejection, deferred)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                        ON CONFLICT (client_id) DO NOTHING RETURNING id""")
                .params(m.clientId(), m.employeeId(), m.worksiteId(), m.type().name(), ts(m.recordedAt()),
                        ts(m.capturedAt()), ts(m.receivedAt()), loc.point().lat(), loc.point().lon(),
                        (float) loc.accuracyMeters(), loc.mocked(),
                        m.distanceMeters() == null ? null : m.distanceMeters().floatValue(), m.status().name(),
                        m.rejection() == null ? null : m.rejection().name(), m.deferred())
                .query(Long.class).optional()
                .map(m::withId);
    }

    @Override
    public List<AttendanceMark> findBetween(Instant from, Instant to, Long employeeId, Long worksiteId) {
        return jdbc.sql("SELECT " + COLUMNS + """
                         FROM attendance_mark
                        WHERE recorded_at >= :from AND recorded_at < :to
                          AND (CAST(:employee AS BIGINT) IS NULL OR employee_id = :employee)
                          AND (CAST(:worksite AS BIGINT) IS NULL OR worksite_id = :worksite)
                        ORDER BY recorded_at, id""")
                .param("from", ts(from))
                .param("to", ts(to))
                .param("employee", employeeId, java.sql.Types.BIGINT)
                .param("worksite", worksiteId, java.sql.Types.BIGINT)
                .query(this::map).list();
    }

    private static OffsetDateTime ts(Instant i) {
        return i.atOffset(ZoneOffset.UTC);
    }

    private static Instant instant(ResultSet rs, String column) throws SQLException {
        Timestamp t = rs.getTimestamp(column);
        return t.toInstant();
    }

    private AttendanceMark map(ResultSet rs, int row) throws SQLException {
        long worksite = rs.getLong("worksite_id");
        Long worksiteId = rs.wasNull() ? null : worksite;
        float distance = rs.getFloat("distance_m");
        Double distanceM = rs.wasNull() ? null : (double) distance;
        String rejection = rs.getString("rejection");
        return new AttendanceMark(
                rs.getLong("id"),
                rs.getObject("client_id", UUID.class),
                rs.getLong("employee_id"),
                worksiteId,
                MarkType.valueOf(rs.getString("type")),
                instant(rs, "recorded_at"),
                instant(rs, "captured_at"),
                instant(rs, "received_at"),
                new LocationReading(new GeoPoint(rs.getDouble("lat"), rs.getDouble("lon")), rs.getFloat("accuracy_m"),
                        rs.getBoolean("mocked")),
                distanceM,
                MarkStatus.valueOf(rs.getString("status")),
                rejection == null ? null : RejectionReason.valueOf(rejection),
                rs.getBoolean("deferred"));
    }
}
