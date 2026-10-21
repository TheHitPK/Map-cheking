package com.asistencia.employee.application.port;

import com.asistencia.employee.domain.Employee;
import com.asistencia.employee.domain.Role;
import java.util.List;
import java.util.Optional;

public interface EmployeeRepository {

    Optional<Employee> findById(long id);

    Optional<Employee> findByDocument(String document);

    /** Ordered by name. */
    List<Employee> findAll();

    boolean existsActiveWithRole(Role role);

    /** Inserts when {@code id} is null, updates otherwise. Throws ConflictException on a duplicate document. */
    Employee save(Employee employee);
}
