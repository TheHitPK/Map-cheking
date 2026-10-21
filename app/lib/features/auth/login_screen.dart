import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/brand/brand.dart';
import '../../core/strings.dart';
import '../../core/widgets/common.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _document = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _document.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authProvider.notifier).login(_document.text, _password.text);
      TextInput.finishAutofillContext();
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final worker = ref.watch(appRoleProvider) == AppRole.worker;
    final reason = ref.watch(logoutReasonProvider);
    final error = _error ?? reason;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Space.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: AutofillGroup(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    const Center(child: RouteToPinHero(size: 120)),
                    const SizedBox(height: Space.lg),
                    Center(child: PinPunchWordmark(fontSize: 34, subtitle: worker ? null : S.supervisor)),
                    const SizedBox(height: Space.sm),
                    Text(worker ? S.tagline : S.supervisorLoginHint,
                        style: t.textTheme.bodyLarge?.copyWith(color: t.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center),
                    const SizedBox(height: Space.xxl),
                    TextFormField(
                      controller: _document,
                      decoration: const InputDecoration(labelText: S.idLabel, prefixIcon: Icon(Icons.badge_outlined)),
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      validator: (v) => (v == null || v.trim().isEmpty) ? S.idRequired : null,
                    ),
                    const SizedBox(height: Space.lg),
                    TextFormField(
                      controller: _password,
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: S.passwordLabel,
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          tooltip: _obscure ? S.showPassword : S.hidePassword,
                          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) => (v == null || v.isEmpty) ? S.passwordRequired : null,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      child: error == null
                          ? const SizedBox(width: double.infinity)
                          : Padding(
                              padding: const EdgeInsets.only(top: Space.lg),
                              child: Semantics(
                                liveRegion: true,
                                child: StatusBadge(label: error, icon: Icons.error_outline, tone: Tone.danger),
                              ),
                            ),
                    ),
                    const SizedBox(height: Space.xl),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: BrandColors.orange,
                        foregroundColor: BrandColors.navy,
                        minimumSize: const Size.fromHeight(56),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: _busy
                            ? const SizedBox.square(
                                key: ValueKey('busy'),
                                dimension: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: BrandColors.navy))
                            : const Text(S.signIn, key: ValueKey('label'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
