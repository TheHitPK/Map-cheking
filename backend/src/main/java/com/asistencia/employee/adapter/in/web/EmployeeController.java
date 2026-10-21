package com.asistencia.employee.adapter.in.web;

import com.asistencia.employee.application.EmployeeService;
import com.asistencia.employee.domain.Employee;
import com.asistencia.employee.domain.Role;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
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
@RequestMapping("/employees")
public class EmployeeController {

    /** Never exposes the password hash. */
    public record EmployeeDto(long id, String document, String fullName, Role role, boolean active) {

        public static EmployeeDto of(Employee e) {
            return new EmployeeDto(e.id(), e.document(), e.fullName(), e.role(), e.active());
        }
    }

    public record CreateRequest(@NotBlank String document, @NotBlank String fullName, @NotNull Role role,
                                @NotBlank String password) {
    }

    public record UpdateRequest(@NotBlank String fullName, @NotNull Role role, @NotNull Boolean active) {
    }

    public record PasswordRequest(@NotBlank String password) {
    }

    private final EmployeeService employees;

    public EmployeeController(EmployeeService employees) {
        this.employees = employees;
    }

    @GetMapping
    public List<EmployeeDto> list() {
        return employees.list().stream().map(EmployeeDto::of).toList();
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public EmployeeDto create(@Valid @RequestBody CreateRequest req) {
        return EmployeeDto.of(employees.create(req.document(), req.fullName(), req.role(), req.password()));
    }

    @PutMapping("/{id}")
    public EmployeeDto update(@PathVariable long id, @Valid @RequestBody UpdateRequest req) {
        return EmployeeDto.of(employees.update(id, req.fullName(), req.role(), req.active()));
    }

    @PutMapping("/{id}/password")
    @ResponseStatus(HttpStatus.NO_CONTENT)
    public void resetPassword(@PathVariable long id, @Valid @RequestBody PasswordRequest req) {
        employees.resetPassword(id, req.password());
    }
}
