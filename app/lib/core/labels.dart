import 'package:flutter/material.dart';

import 'widgets/common.dart';

typedef StatusLabel = ({String label, IconData icon, Tone tone});

/// Mark status → Spanish label, icon and tone.
StatusLabel markStatusLabel(String status) => switch (status) {
      'ON_TIME' => (label: 'A tiempo', icon: Icons.check_circle_outline, tone: Tone.success),
      'LATE' => (label: 'Tarde', icon: Icons.schedule, tone: Tone.warning),
      'EARLY_LEAVE' => (label: 'Salida anticipada', icon: Icons.directions_walk, tone: Tone.warning),
      'UNSCHEDULED' => (label: 'Fuera de turno', icon: Icons.event_busy_outlined, tone: Tone.neutral),
      'REJECTED' => (label: 'Rechazada', icon: Icons.block, tone: Tone.danger),
      _ => (label: status, icon: Icons.help_outline, tone: Tone.neutral),
    };

/// Daily state (supervisor) → label.
StatusLabel dayStateLabel(String state) => switch (state) {
      'ON_TIME' => (label: 'A tiempo', icon: Icons.check_circle_outline, tone: Tone.success),
      'LATE' => (label: 'Tarde', icon: Icons.schedule, tone: Tone.warning),
      'ABSENT' => (label: 'Ausente', icon: Icons.person_off_outlined, tone: Tone.danger),
      'PENDING' => (label: 'Por llegar', icon: Icons.hourglass_empty, tone: Tone.info),
      'OFF' => (label: 'Libre', icon: Icons.weekend_outlined, tone: Tone.neutral),
      _ => (label: state, icon: Icons.help_outline, tone: Tone.neutral),
    };

String markTypeLabel(String type) => type == 'IN' ? 'Llegada' : 'Salida';
