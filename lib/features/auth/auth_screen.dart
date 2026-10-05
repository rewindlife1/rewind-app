import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../ui/widgets/common.dart';

enum AuthMode { login, signup, reset }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, required this.mode});
  final AuthMode mode;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  String? _error;
  String? _info;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
      _info = null;
    });
    final auth = ref.read(supabaseProvider).auth;
    final email = _email.text.trim();
    try {
      switch (widget.mode) {
        case AuthMode.login:
          await auth.signInWithPassword(email: email, password: _password.text);
          break;
        case AuthMode.signup:
          final res = await auth.signUp(
            email: email,
            password: _password.text,
            data: {'full_name': _name.text.trim()},
            emailRedirectTo: Uri.base.origin + Uri.base.path,
          );
          if (res.session == null) {
            setState(() => _info =
                'Check your inbox — we sent a link to confirm $email. Then sign in.');
          }
          break;
        case AuthMode.reset:
          await auth.resetPasswordForEmail(email,
              redirectTo: Uri.base.origin + Uri.base.path);
          setState(() => _info = 'If an account exists for $email, a reset link is on its way.');
          break;
      }
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 900;
    final form = _buildForm(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(wide ? 20 : 0),
          child: wide
              ? Row(children: [
                  Expanded(child: Center(child: form)),
                  const SizedBox(width: 20),
                  const Expanded(child: _BrandPanel()),
                ])
              : Center(child: form),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final title = switch (widget.mode) {
      AuthMode.login => 'Welcome back',
      AuthMode.signup => 'Become a member',
      AuthMode.reset => 'Reset your password',
    };
    final subtitle = switch (widget.mode) {
      AuthMode.login => 'Sign in to see your Longevity Score and today’s plan.',
      AuthMode.signup => 'Measure 8 dimensions of health and longevity — and get a clear path to improve.',
      AuthMode.reset => 'Enter your email and we’ll send you a reset link.',
    };
    final cta = switch (widget.mode) {
      AuthMode.login => 'Sign in',
      AuthMode.signup => 'Create account',
      AuthMode.reset => 'Send reset link',
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Align(alignment: Alignment.centerLeft, child: RewindLogo()),
              const SizedBox(height: 40),
              Text(title, style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text(subtitle, style: t.bodyLarge?.copyWith(color: RC.muted)),
              const SizedBox(height: 28),
              if (widget.mode == AuthMode.signup) ...[
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 14),
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty || !s.contains('@') || !s.contains('.')) return 'Enter a valid email';
                  return null;
                },
              ),
              if (widget.mode != AuthMode.reset) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  obscureText: _obscure,
                  autofillHints: [
                    widget.mode == AuthMode.signup ? AutofillHints.newPassword : AutofillHints.password
                  ],
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if ((v ?? '').length < 8) return 'At least 8 characters';
                    return null;
                  },
                ),
              ],
              if (widget.mode == AuthMode.login)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.go('/reset'),
                    child: const Text('Forgot password?', style: TextStyle(color: RC.muted)),
                  ),
                )
              else
                const SizedBox(height: 16),
              if (_error != null) _Banner(text: _error!, error: true),
              if (_info != null) _Banner(text: _info!, error: false),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(cta),
              ),
              const SizedBox(height: 20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(
                  widget.mode == AuthMode.login ? 'New to REWIND?' : 'Already a member?',
                  style: const TextStyle(color: RC.muted),
                ),
                TextButton(
                  onPressed: () => context.go(widget.mode == AuthMode.login ? '/signup' : '/login'),
                  child: Text(widget.mode == AuthMode.login ? 'Become a member' : 'Sign in',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: RC.ink)),
                ),
              ]),
              if (widget.mode == AuthMode.signup)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'By creating an account you agree to the REWIND Terms of Service and Privacy Policy. '
                    'REWIND is not a substitute for medical advice.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: RC.muted),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text, required this.error});
  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: error ? const Color(0xFFFDECEC) : RC.limeSoft,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(text, style: TextStyle(color: error ? RC.danger : RC.ink)),
      );
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1D16), Color(0xFF2E3A1C), Color(0xFF8DB300)],
        ),
      ),
      padding: const EdgeInsets.all(40),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Spacer(),
        const ScoreRing(score: 82, size: 200, dark: true),
        const SizedBox(height: 32),
        Text('The Complete Measure\nof Longevity.',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: Colors.white, fontWeight: FontWeight.w800, height: 1.05, letterSpacing: -1)),
        const SizedBox(height: 16),
        const Text('Love the life you live. And live longer.',
            style: TextStyle(color: Colors.white70, fontSize: 16)),
        const SizedBox(height: 24),
      ]),
    );
  }
}
