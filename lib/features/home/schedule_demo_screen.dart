import 'package:flutter/material.dart';
import '../../app/theme/app_tokens.dart';
import '../../app/widgets/glass_card.dart';

class ScheduleDemoScreen extends StatelessWidget {
  const ScheduleDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background + gradient overlay
          Container(color: AppTokens.bgDark),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(gradient: AppTokens.heroGradient),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    _pill(context, 'Schedule', selected: true),
                    const SizedBox(width: 10),
                    _pill(context, 'Tasks'),
                    const SizedBox(width: 10),
                    _pill(context, 'Notes'),
                  ],
                ),
                const SizedBox(height: 18),

                Text(
                  'Wednesday',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTokens.textOnDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Jan 24',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTokens.textMutedOnDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 18),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _timeRow('09:00', 'Daily standup', '15 min'),
                      const SizedBox(height: 12),
                      _divider(),
                      const SizedBox(height: 12),
                      _timeRow('10:30', 'Pick Ekibastuz transfer', '90 min'),
                      const SizedBox(height: 12),
                      _divider(),
                      const SizedBox(height: 12),
                      _timeRow('13:00', 'Check shipment zone', '45 min'),
                    ],
                  ),
                ),

                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: _stat(context, 'Progress', '72%'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassCard(
                        padding: const EdgeInsets.all(14),
                        child: _stat(context, 'Today', '5 tasks'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _fab(),
    );
  }

  Widget _divider() =>
      Divider(height: 1, color: Colors.white.withValues(alpha: 0.06));

  Widget _pill(BuildContext context, String text, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? AppTokens.accentGreen.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? AppTokens.accentGreen.withValues(alpha: 0.35)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: selected ? AppTokens.accentGreen : AppTokens.textOnDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _timeRow(String time, String title, String meta) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          time,
          style: const TextStyle(
            color: AppTokens.textOnDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTokens.textOnDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                meta,
                style: const TextStyle(
                  color: AppTokens.textMutedOnDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: AppTokens.accentGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTokens.accentGreen.withValues(alpha: 0.25),
                blurRadius: 14,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTokens.textMutedOnDark,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppTokens.textOnDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _fab() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTokens.accentGreen.withValues(alpha: 0.28),
            blurRadius: 22,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTokens.accentGreen,
        foregroundColor: AppTokens.bgDark,
        child: const Icon(Icons.add),
      ),
    );
  }
}
