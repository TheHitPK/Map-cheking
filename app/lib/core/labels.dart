import 'package:flutter/material.dart';

import 'strings.dart';
import 'widgets/common.dart';

typedef StatusLabel = ({String label, IconData icon, Tone tone});

/// Punch status → label, icon and tone.
StatusLabel markStatusLabel(String status) => switch (status) {
      'ON_TIME' => (label: S.onTime, icon: Icons.check_circle_outline, tone: Tone.success),
      'LATE' => (label: S.late, icon: Icons.schedule, tone: Tone.warning),
      'EARLY_LEAVE' => (label: S.leftEarly, icon: Icons.directions_walk, tone: Tone.warning),
      'UNSCHEDULED' => (label: S.offShift, icon: Icons.event_busy_outlined, tone: Tone.neutral),
      'REJECTED' => (label: S.rejectedLabel, icon: Icons.block, tone: Tone.danger),
      _ => (label: status, icon: Icons.help_outline, tone: Tone.neutral),
    };

/// Daily state (supervisor) → label.
StatusLabel dayStateLabel(String state) => switch (state) {
      'ON_TIME' => (label: S.onTime, icon: Icons.check_circle_outline, tone: Tone.success),
      'LATE' => (label: S.late, icon: Icons.schedule, tone: Tone.warning),
      'ABSENT' => (label: S.absent, icon: Icons.person_off_outlined, tone: Tone.danger),
      'PENDING' => (label: S.expected, icon: Icons.hourglass_empty, tone: Tone.info),
      'OFF' => (label: S.dayOff, icon: Icons.weekend_outlined, tone: Tone.neutral),
      _ => (label: state, icon: Icons.help_outline, tone: Tone.neutral),
    };

String markTypeLabel(String type) => type == 'IN' ? S.punchInLabel : S.punchOutLabel;
