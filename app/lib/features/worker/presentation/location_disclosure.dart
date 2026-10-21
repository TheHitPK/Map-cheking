import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/brand/brand.dart';
import '../../../core/strings.dart';
import '../../../core/widgets/common.dart';
import '../data/worker_repository.dart';

/// Prominent disclosure (Google Play) and employee notice (US state laws), shown before the OS permission prompt.
final locationDisclosureProvider = AsyncNotifierProvider<LocationDisclosure, bool>(LocationDisclosure.new);

class LocationDisclosure extends AsyncNotifier<bool> {
  static const _key = 'location_disclosure_v1';
  final _store = PrefsStore();

  @override
  Future<bool> build() async => await _store.get(_key) == 'accepted';

  Future<void> accept() async {
    await _store.set(_key, 'accepted');
    state = const AsyncData(true);
  }
}

/// Shows [child] only after the worker has read and accepted the location notice.
class LocationDisclosureGate extends ConsumerWidget {
  const LocationDisclosureGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (ref.watch(locationDisclosureProvider)) {
        AsyncData(value: true) => child,
        AsyncData() || AsyncError() => const _DisclosureScreen(),
        _ => const Scaffold(body: Center(child: CircularProgressIndicator())),
      };
}

class _DisclosureScreen extends ConsumerStatefulWidget {
  const _DisclosureScreen();

  @override
  ConsumerState<_DisclosureScreen> createState() => _DisclosureScreenState();
}

class _DisclosureScreenState extends ConsumerState<_DisclosureScreen> {
  bool _declined = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget point(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: Space.md),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: t.colorScheme.primary),
            const SizedBox(width: Space.md),
            Expanded(child: Text(text, style: t.textTheme.bodyLarge)),
          ]),
        );
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Center(child: RouteToPinHero(size: 110)),
                const SizedBox(height: Space.xl),
                Text(S.disclosureTitle, style: t.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: Space.md),
                Text(S.disclosureBody, style: t.textTheme.bodyLarge),
                const SizedBox(height: Space.xl),
                point(Icons.phonelink_lock_outlined, S.disclosurePoint1),
                point(Icons.place_outlined, S.disclosurePoint2),
                point(Icons.gpp_good_outlined, S.disclosurePoint3),
                if (_declined) ...[
                  const SizedBox(height: Space.sm),
                  const StatusBadge(label: S.disclosureDeclined, icon: Icons.info_outline, tone: Tone.info),
                ],
                const SizedBox(height: Space.xl),
                FilledButton(
                  onPressed: () => ref.read(locationDisclosureProvider.notifier).accept(),
                  style: FilledButton.styleFrom(
                    backgroundColor: BrandColors.orange,
                    foregroundColor: BrandColors.navy,
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text(S.disclosureAccept, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ),
                const SizedBox(height: Space.sm),
                TextButton(onPressed: () => setState(() => _declined = true), child: const Text(S.disclosureLater)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
