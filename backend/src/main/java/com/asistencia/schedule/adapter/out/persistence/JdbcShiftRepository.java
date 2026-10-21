package com.asistencia.schedule.adapter.out.persistence;

import com.asistencia.schedule.application.port.ShiftRepository;
import com.asistencia.schedule.domain.Shift;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.DayOfWeek;
import java.util.EnumSet;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class JdbcShiftRepository implements ShiftRepository {

    private static final String COLUMNS = "id, employee_id, worksite_id, start_time, end_time, days, grace_minutes";

    private final JdbcClient jdbc;

    public JdbcShiftRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<Shift> findByEmployee(long employeeId) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM shift WHERE employee_id = ?").param(employeeId)
                .query(this::map).optional();
    }

    @Override
    public List<Shift> findAll() {
        return jdbc.sql("SELECT " + COLUMNS + " FROM shift ORDER BY id").query(this::map).list();
    }

    @Override
    public Shift save(Shift s) {
        long id = jdbc.sql("""
                        INSERT INTO shift (employee_id, worksite_id, start_time, end_time, days, grace_minutes)
                        VALUES (?, ?, ?, ?, ?, ?)
                        ON CONFLICT (employee_id) DO UPDATE SET worksite_id = excluded.worksite_id,
                            start_time = excluded.start_time, end_time = excluded.end_time,
                            days = excluded.days, grace_minutes = excluded.grace_minutes
                        RETURNING id""")
                .params(s.employeeId(), s.worksiteId(), s.start(), s.end(), toMask(s.days()), s.graceMinutes())
                .query(Long.class).single();
        return new Shift(id, s.employeeId(), s.worksiteId(), s.start(), s.end(), s.days(), s.graceMinutes());
    }

    @Override
    public boolean deleteByEmployee(long employeeId) {
        return jdbc.sql("DELETE FROM shift WHERE employee_id = ?").param(employeeId).update() > 0;
    }

    static int toMask(Set<DayOfWeek> days) {
        return days.stream().mapToInt(d -> 1 << (d.getValue() - 1)).reduce(0, (a, b) -> a | b);
    }

    static Set<DayOfWeek> fromMask(int mask) {
        Set<DayOfWeek> days = EnumSet.noneOf(DayOfWeek.class);
        for (DayOfWeek d : DayOfWeek.values()) {
            if ((mask & (1 << (d.getValue() - 1))) != 0) {
                days.add(d);
            }
        }
        return days;
    }

    private Shift map(ResultSet rs, int row) throws SQLException {
        return new Shift(rs.getLong("id"), rs.getLong("employee_id"), rs.getLong("worksite_id"),
                rs.getTime("start_time").toLocalTime(), rs.getTime("end_time").toLocalTime(),
                fromMask(rs.getInt("days")), rs.getInt("grace_minutes"));
    }
}
