package com.asistencia.config;

import com.asistencia.attendance.application.AttendanceQueryService;
import com.asistencia.attendance.application.RegisterMarkService;
import com.asistencia.attendance.application.port.MarkRepository;
import com.asistencia.attendance.domain.PunctualityPolicy;
import com.asistencia.attendance.domain.rule.AccuracyRule;
import com.asistencia.attendance.domain.rule.CaptureTimeRule;
import com.asistencia.attendance.domain.rule.GeofenceRule;
import com.asistencia.attendance.domain.rule.MockLocationRule;
import com.asistencia.attendance.domain.rule.SequenceRule;
import com.asistencia.attendance.domain.rule.WorksiteAssignedRule;
import com.asistencia.auth.application.AuthService;
import com.asistencia.auth.application.LoginThrottle;
import com.asistencia.auth.application.port.TokenIssuer;
import com.asistencia.employee.application.EmployeeService;
import com.asistencia.employee.application.port.EmployeeRepository;
import com.asistencia.employee.application.port.PasswordHasher;
import com.asistencia.schedule.application.ScheduleService;
import com.asistencia.schedule.application.port.ShiftRepository;
import com.asistencia.shared.application.UnitOfWork;
import com.asistencia.worksite.application.WorksiteService;
import com.asistencia.worksite.application.port.WorksiteRepository;
import java.time.Clock;
import java.util.List;
import org.springframework.boot.ApplicationRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** Wires the Spring-free use cases to their adapters. */
@Configuration
public class ModulesConfig {

    @Bean
    EmployeeService employeeService(EmployeeRepository employees, PasswordHasher hasher) {
        return new EmployeeService(employees, hasher);
    }

    @Bean
    WorksiteService worksiteService(WorksiteRepository worksites) {
        return new WorksiteService(worksites);
    }

    @Bean
    ScheduleService scheduleService(ShiftRepository shifts, EmployeeService employees, WorksiteService worksites) {
        return new ScheduleService(shifts, employees, worksites);
    }

    @Bean
    SequenceRule sequenceRule(AppProperties props) {
        return new SequenceRule(props.attendance().forgottenCheckoutAfter());
    }

    /** Rule order is the order of the message the worker sees: setup problems first, location last. */
    @Bean
    RegisterMarkService registerMarkService(MarkRepository marks, ShiftRepository shifts, WorksiteRepository worksites,
                                            SequenceRule sequence, UnitOfWork uow, Clock clock, AppProperties props) {
        AppProperties.Attendance a = props.attendance();
        return new RegisterMarkService(marks, shifts, worksites, List.of(
                new WorksiteAssignedRule(),
                new CaptureTimeRule(a.maxClockAhead(), a.maxDeferral()),
                sequence,
                new MockLocationRule(),
                new AccuracyRule(a.maxAccuracyMeters()),
                new GeofenceRule()),
                new PunctualityPolicy(props.zone()), uow, clock, a.deferredAfter());
    }

    @Bean
    AttendanceQueryService attendanceQueryService(MarkRepository marks, EmployeeRepository employees,
                                                  ShiftRepository shifts, WorksiteRepository worksites,
                                                  SequenceRule sequence, Clock clock, AppProperties props) {
        return new AttendanceQueryService(marks, employees, shifts, worksites, sequence, clock, props.zone());
    }

    @Bean
    AuthService authService(EmployeeRepository employees, PasswordHasher hasher, TokenIssuer tokens, Clock clock) {
        return new AuthService(employees, hasher, tokens, new LoginThrottle(clock));
    }

    @Bean
    ApplicationRunner bootstrapSupervisor(EmployeeService employees, AppProperties props) {
        AppProperties.BootstrapAdmin admin = props.auth().bootstrapAdmin();
        return args -> employees.bootstrapSupervisor(admin.document(), admin.password());
    }
}
