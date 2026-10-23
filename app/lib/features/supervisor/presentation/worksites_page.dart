import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/format.dart';
import '../../../core/models.dart';
import '../../../core/widgets/common.dart';
import '../../../core/strings.dart';
import '../data/supervisor_api.dart';
import 'supervisor_shell.dart';
import 'worksite_editor_page.dart';

class WorksitesPage extends ConsumerWidget {
  const WorksitesPage({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref, [Worksite? w]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => WorksiteEditorPage(worksite: w), fullscreenDialog: w == null),
    );
    if (saved ?? false) ref.invalidate(worksitesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sites = ref.watch(worksitesProvider);
    return Scaffold(
      appBar: const SupervisorAppBar(title: S.navSites),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(context, ref),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text(S.newSite),
      ),
      body: switch (sites) {
        AsyncData(value: final list) when list.isEmpty => EmptyState(
            icon: Icons.location_city_outlined,
            title: S.noSites,
            message: S.noSitesHelp,
            action: FilledButton.icon(
                onPressed: () => _open(context, ref), icon: const Icon(Icons.add), label: const Text(S.createFirstSite)),
          ),
        AsyncData(value: final list) => RefreshIndicator(
            onRefresh: () => ref.refresh(worksitesProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(Space.lg, Space.lg, Space.lg, 96),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: Space.sm),
              itemBuilder: (_, i) => MaxWidth(
                width: 900,
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: const Icon(Icons.location_city_outlined),
                    title: Text(list[i].name),
                    subtitle: Text([
                      if (list[i].address.isNotEmpty) list[i].address,
                      S.radius(Fmt.distance(list[i].radiusMeters.toDouble())),
                    ].join(' · ')),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (!list[i].active)
                        const StatusBadge(label: S.inactive, icon: Icons.pause_circle_outline, tone: Tone.neutral, dense: true),
                      const Icon(Icons.chevron_right),
                    ]),
                    onTap: () => _open(context, ref, list[i]),
                  ),
                ),
              ),
            ),
          ),
        AsyncError(:final error) => ErrorState(message: '$error', onRetry: () => ref.invalidate(worksitesProvider)),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
