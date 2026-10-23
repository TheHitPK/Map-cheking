import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings.dart';
import '../data/supervisor_api.dart';

/// "All job sites" or one job site.
class WorksiteFilter extends ConsumerWidget {
  const WorksiteFilter({super.key, required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sites = ref.watch(worksitesProvider).value ?? const [];
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      child: DropdownButtonFormField<int?>(
        initialValue: value,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: S.jobSite,
          prefixIcon: Icon(Icons.location_city_outlined),
          isDense: true,
        ),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text(S.allSites)),
          for (final w in sites) DropdownMenuItem<int?>(value: w.id, child: Text(w.name, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
