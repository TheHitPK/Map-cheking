package com.asistencia.employee.adapter.out.persistence;

import com.asistencia.employee.application.port.EmployeeRepository;
import com.asistencia.employee.domain.Employee;
import com.asistencia.employee.domain.Role;
import com.asistencia.shared.domain.ConflictException;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;
import java.util.Optional;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.jdbc.core.simple.JdbcClient;
import org.springframework.stereotype.Repository;

@Repository
public class JdbcEmployeeRepository implements EmployeeRepository {

    private static final String COLUMNS = "id, document, full_name, role, password_hash, active, hourly_rate_cents";

    private final JdbcClient jdbc;

    public JdbcEmployeeRepository(JdbcClient jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public Optional<Employee> findById(long id) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM employee WHERE id = ?").param(id).query(this::map).optional();
    }

    @Override
    public Optional<Employee> findByDocument(String document) {
        return jdbc.sql("SELECT " + COLUMNS + " FROM employee WHERE lower(document) = lower(?)")
                .param(document).query(this::map).optional();
    }

    @Override
    public List<Employee> findAll() {
        return jdbc.sql("SELECT " + COLUMNS + " FROM employee ORDER BY full_name").query(this::map).list();
    }

    @Override
    public boolean existsActiveWithRole(Role role) {
        return jdbc.sql("SELECT EXISTS (SELECT 1 FROM employee WHERE role = ? AND active)")
                .param(role.name()).query(Boolean.class).single();
    }

    @Override
    public Employee save(Employee e) {
        try {
            if (e.id() == null) {
                long id = jdbc.sql("""
                                INSERT INTO employee (document, full_name, role, password_hash, active, hourly_rate_cents)
                                VALUES (?, ?, ?, ?, ?, ?) RETURNING id""")
                        .params(e.document(), e.fullName(), e.role().name(), e.passwordHash(), e.active(), e.hourlyRateCents())
                        .query(Long.class).single();
                return e.withId(id);
            }
            jdbc.sql("""
                            UPDATE employee SET full_name = ?, role = ?, password_hash = ?, active = ?, hourly_rate_cents = ?
                             WHERE id = ?""")
                    .params(e.fullName(), e.role().name(), e.passwordHash(), e.active(), e.hourlyRateCents(), e.id())
                    .update();
            return e;
        } catch (DuplicateKeyException ex) {
            throw new ConflictException("An employee with ID " + e.document() + " already exists.");
        }
    }

    private Employee map(ResultSet rs, int row) throws SQLException {
        return new Employee(rs.getLong("id"), rs.getString("document"), rs.getString("full_name"),
                Role.valueOf(rs.getString("role")), rs.getString("password_hash"), rs.getBoolean("active"),
                rs.getObject("hourly_rate_cents", Integer.class));
    }
}
