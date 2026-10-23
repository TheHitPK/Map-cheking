package com.asistencia.employee.application;

import com.asistencia.employee.application.port.EmployeeRepository;
import com.asistencia.employee.application.port.PasswordHasher;
import com.asistencia.employee.domain.Employee;
import com.asistencia.employee.domain.Role;
import com.asistencia.shared.domain.InvalidInputException;
import com.asistencia.shared.domain.NotFoundException;
import java.util.List;

public class EmployeeService {

    static final int MIN_PASSWORD = 6;

    private final EmployeeRepository employees;
    private final PasswordHasher hasher;

    public EmployeeService(EmployeeRepository employees, PasswordHasher hasher) {
        this.employees = employees;
        this.hasher = hasher;
    }

    public List<Employee> list() {
        return employees.findAll();
    }

    public Employee get(long id) {
        return employees.findById(id).orElseThrow(() -> new NotFoundException("Employee not found."));
    }

    public Employee create(String document, String fullName, Role role, String password, Integer hourlyRateCents) {
        Employee e = new Employee(null, document, fullName, role, null, true, hourlyRateCents);
        return employees.save(e.withPasswordHash(hasher.hash(validPassword(password))));
    }

    public Employee update(long id, String fullName, Role role, boolean active, Integer hourlyRateCents) {
        Employee current = get(id);
        return employees.save(new Employee(id, current.document(), fullName, role, current.passwordHash(), active,
                hourlyRateCents));
    }

    public void resetPassword(long id, String password) {
        employees.save(get(id).withPasswordHash(hasher.hash(validPassword(password))));
    }

    /** Creates the first supervisor when there is none, so a fresh install can be administered. */
    public void bootstrapSupervisor(String document, String password) {
        if (password == null || password.isBlank() || employees.existsActiveWithRole(Role.SUPERVISOR)) {
            return;
        }
        if (employees.findByDocument(document).isEmpty()) {
            create(document, "Administrator", Role.SUPERVISOR, password, null);
        }
    }

    private static String validPassword(String password) {
        if (password == null || password.length() < MIN_PASSWORD || password.length() > 72) {
            throw new InvalidInputException("Password must be " + MIN_PASSWORD + " to 72 characters.");
        }
        return password;
    }
}
