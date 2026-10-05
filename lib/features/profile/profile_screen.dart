import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../ui/widgets/common.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _name = TextEditingController();
  final _password = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    setState(() => _saving = true);
    try {
      await ref.read(repoProvider).updateName(_name.text.trim());
      ref.invalidate(profileProvider);
      if (mounted) showSnack(context, 'Saved');
    } catch (e) {
      if (mounted) showSnack(context, 'Could not save: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_password.text.length < 8) {
      showSnack(context, 'Use at least 8 characters');
      return;
    }
    try {
      await ref.read(supabaseProvider).auth.updateUser(UserAttributes(password: _password.text));
      _password.clear();
      if (mounted) showSnack(context, 'Password updated');
    } on AuthException catch (e) {
      if (mounted) showSnack(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final profile = ref.watch(profileProvider).valueOrNull;
    final user = ref.watch(currentUserProvider);
    if (!_loaded && profile != null) {
      _name.text = profile.fullName ?? '';
      _loaded = true;
    }

    return PageBody(maxWidth: 640, children: [
      const SizedBox(height: 8),
      Text('Profile & membership', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 20),
      RCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('Your details'),
          TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 12),
          TextFormField(
            enabled: false,
            key: ValueKey(user?.email),
            initialValue: user?.email ?? '',
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(onPressed: _saving ? null : _saveName, child: const Text('Save')),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      RCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('Membership'),
          Row(children: [
            Chip2((profile?.membership ?? 'trial').toUpperCase()),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Monthly \$29 · Annual \$249 · 7-day free trial',
                  style: TextStyle(color: RC.muted)),
            ),
          ]),
          const SizedBox(height: 12),
          const Text('Billing is coming soon. Your access is active during early access.',
              style: TextStyle(color: RC.muted, fontSize: 13)),
        ]),
      ),
      const SizedBox(height: 16),
      RCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SectionTitle('Change password'),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton(onPressed: _changePassword, child: const Text('Update password')),
          ),
        ]),
      ),
      const SizedBox(height: 16),
      OutlinedButton(
        onPressed: () => ref.read(supabaseProvider).auth.signOut(),
        child: const Text('Sign out'),
      ),
    ]);
  }
}
