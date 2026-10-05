import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models.dart';
import '../../domain/coach_engine.dart';
import '../../state/providers.dart';
import '../../ui/widgets/common.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;

  static const _suggestions = [
    'What should I focus on first?',
    'How do I improve my sleep?',
    'Explain my score',
    'What supplements should I start with?',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || _sending) return;
    setState(() => _sending = true);
    _input.clear();
    try {
      final repo = ref.read(repoProvider);
      await repo.addCoachMessage('user', msg);
      final score = await ref.read(scoreProvider.future);
      final profile = await ref.read(profileProvider.future);
      final history = await ref.read(coachMessagesProvider.future);
      final reply = CoachEngine.reply(
        message: msg,
        turn: history.length,
        firstName: profile?.firstName,
        pillarScores: score?.pillars,
        overall: score?.overall,
      );
      await Future.delayed(const Duration(milliseconds: 400));
      await repo.addCoachMessage('coach', reply);
      ref.invalidate(coachMessagesProvider);
    } catch (e) {
      if (mounted) showSnack(context, 'Could not send: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent + 200,
              duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(coachMessagesProvider);
    final t = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Column(children: [
          Expanded(
            child: AsyncView<List<CoachMessage>>(
              value: messages,
              data: (list) => ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                children: [
                  Text('REWIND Coach', style: t.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Coaching built from your own Longevity Score.',
                      style: t.titleMedium?.copyWith(color: RC.muted)),
                  const SizedBox(height: 20),
                  if (list.isEmpty)
                    const _Bubble(
                      isUser: false,
                      text: 'Hi, I’m your REWIND Coach. Ask me anything about your score, your plan, '
                          'sleep, nutrition, training or supplements.',
                    ),
                  for (final m in list) _Bubble(isUser: m.isUser, text: m.body),
                  if (_sending) const _Bubble(isUser: false, text: '…'),
                  const SizedBox(height: 8),
                  const Text(
                    'REWIND Coach offers general wellness guidance, not medical advice. '
                    'Talk to your doctor before making changes to medication or treatment.',
                    style: TextStyle(fontSize: 11, color: RC.muted),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final s in _suggestions)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(s),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: RC.line),
                      shape: const StadiumBorder(),
                      onPressed: () => _send(s),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _send,
                  decoration: const InputDecoration(hintText: 'Ask REWIND Coach…'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: RC.ink, minimumSize: const Size(52, 52)),
                onPressed: _sending ? null : () => _send(_input.text),
                icon: const Icon(Icons.arrow_upward, color: RC.lime),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.isUser, required this.text});
  final bool isUser;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? RC.ink : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 20),
          ),
          border: isUser ? null : Border.all(color: RC.line),
        ),
        child: Text(text, style: TextStyle(color: isUser ? Colors.white : RC.ink, height: 1.45)),
      ),
    );
  }
}
