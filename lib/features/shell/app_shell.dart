import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../../ui/widgets/common.dart';

class _NavItem {
  const _NavItem(this.path, this.label, this.icon);
  final String path;
  final String label;
  final IconData icon;
}

const _items = [
  _NavItem('/dashboard', 'Dashboard', Icons.space_dashboard_outlined),
  _NavItem('/track', 'Track', Icons.show_chart),
  _NavItem('/assess', 'Assess', Icons.radar),
  _NavItem('/coach', 'REWIND Coach', Icons.chat_bubble_outline),
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  int get _current {
    for (var i = 0; i < _items.length; i++) {
      if (location.startsWith(_items[i].path)) return i;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.sizeOf(context).width > 820;
    final profile = ref.watch(profileProvider).valueOrNull;

    final avatar = PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 48),
      onSelected: (v) async {
        if (v == 'profile') context.go('/profile');
        if (v == 'signout') await ref.read(supabaseProvider).auth.signOut();
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'profile', child: Text('Profile & membership')),
        PopupMenuItem(value: 'signout', child: Text('Sign out')),
      ],
      child: CircleAvatar(
        radius: 20,
        backgroundColor: RC.ink,
        child: Text(profile?.initials ?? 'R',
            style: const TextStyle(color: RC.lime, fontWeight: FontWeight.w700)),
      ),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(wide ? 24 : 12, 12, wide ? 24 : 12, 4),
            child: Row(children: [
              InkWell(
                borderRadius: BorderRadius.circular(99),
                onTap: () => context.go('/dashboard'),
                child: const RewindLogo(compact: true),
              ),
              if (wide) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: RC.line),
                  ),
                  child: Row(children: [
                    for (var i = 0; i < _items.length; i++)
                      _TopNavButton(
                        label: _items[i].label,
                        selected: i == _current,
                        onTap: () => context.go(_items[i].path),
                      ),
                  ]),
                ),
                const Spacer(),
              ] else
                const Spacer(),
              IconButton(
                tooltip: 'Notifications',
                onPressed: () => showSnack(context, 'You’re all caught up.'),
                icon: const Icon(Icons.notifications_none),
              ),
              const SizedBox(width: 4),
              avatar,
            ]),
          ),
          Expanded(child: child),
        ]),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              backgroundColor: Colors.white,
              indicatorColor: RC.lime,
              selectedIndex: _current < 0 ? 0 : _current,
              onDestinationSelected: (i) => context.go(_items[i].path),
              destinations: [
                for (final it in _items)
                  NavigationDestination(
                      icon: Icon(it.icon), label: it.label == 'REWIND Coach' ? 'Coach' : it.label),
              ],
            ),
    );
  }
}

class _TopNavButton extends StatelessWidget {
  const _TopNavButton({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? RC.ink : Colors.transparent,
      borderRadius: BorderRadius.circular(99),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(label,
              style: TextStyle(
                  color: selected ? Colors.white : RC.ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
        ),
      ),
    );
  }
}
