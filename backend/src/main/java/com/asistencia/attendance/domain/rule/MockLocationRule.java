package com.asistencia.attendance.domain.rule;

import com.asistencia.attendance.domain.MarkContext;
import com.asistencia.attendance.domain.RejectionReason;
import java.util.Optional;

/** Android flags fixes from mock-location apps; the flag is set by the OS, not by our app. */
public final class MockLocationRule implements MarkRule {

    @Override
    public Optional<RejectionReason> evaluate(MarkContext ctx) {
        return ctx.attempt().location().mocked() ? Optional.of(RejectionReason.MOCK_LOCATION) : Optional.empty();
    }
}
