package com.asistencia.schedule.application;

import com.asistencia.employee.application.EmployeeService;
import com.asistencia.employee.domain.Role;
import com.asistencia.schedule.application.port.ShiftRepository;
import com.asistencia.schedule.domain.Shift;
import com.asistencia.shared.domain.InvalidInputException;
import com.asistencia.shared.domain.NotFoundException;
import com.asistencia.worksite.application.WorksiteService;
import java.util.List;

public class ScheduleService {

    private final ShiftRepository shifts;
    private final EmployeeService employees;
    private final WorksiteService worksites;

    public ScheduleService(ShiftRepository shifts, EmployeeService employees, WorksiteService worksites) {
        this.shifts = shifts;
        this.employees = employees;
        this.worksites = worksites;
    }

    public List<Shift> list() {
        return shifts.findAll();
    }

    public Shift assign(Shift shift) {
        if (employees.get(shift.employeeId()).role() != Role.WORKER) {
            throw new InvalidInputException("Schedules can only be assigned to workers.");
        }
        if (!worksites.get(shift.worksiteId()).active()) {
            throw new InvalidInputException("The job site is inactive.");
        }
        return shifts.save(shift);
    }

    public void remove(long employeeId) {
        if (!shifts.deleteByEmployee(employeeId)) {
            throw new NotFoundException("The employee has no schedule.");
        }
    }
}
