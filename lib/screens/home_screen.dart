import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/contest_controller.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onOpenTab});

  final ValueChanged<int>? onOpenTab;

  Future<void> _runPhase(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<String?> Function() action,
  }) async {
    final ok = await confirmAction(
      context,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
    );
    if (!ok || !context.mounted) return;
    final error = await action();
    if (!context.mounted) return;
    if (error != null) {
      showError(context, error);
    } else {
      showInfo(context, 'Étape enregistrée');
    }
  }

  @override
  Widget build(BuildContext context) {
    final contest = ContestScope.of(context);
    final round = contest.phase.activeRound;
    final total = contest.candidatesForRound(round).length;
    final scored = contest.scoredCount(round);
    final padding = Breakpoints.pagePadding(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(contest.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(child: PhaseChip(phase: contest.phase)),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(padding, 16, padding, 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navy, Color(0xFF4F6355)],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'JURY  ·  DEUX TOURS',
                  style: outfit(
                    color: AppColors.goldSoft,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  contest.name,
                  style: displaySerif(
                    color: AppColors.cream,
                    fontSize: 34,
                    fontWeight: FontWeight.w600,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Enregistrez les candidats, notez chaque tour, puis publiez le classement.',
                  style: outfit(
                    color: AppColors.cream.withValues(alpha: 0.82),
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 640;
              final cards = [
                StatCard(
                  label: 'Candidats',
                  value: '${contest.candidates.length}',
                  hint: 'Inscrits au concours',
                  icon: Icons.people_outline,
                ),
                StatCard(
                  label: 'Tour $round',
                  value: '$scored / $total',
                  hint: 'Notes saisies',
                  icon: Icons.edit_note_outlined,
                ),
                StatCard(
                  label: 'Finalistes',
                  value: '${contest.qualifyCount}',
                  hint: 'Qualifiés après le Tour 1',
                  icon: Icons.emoji_events_outlined,
                ),
              ];
              if (wide) {
                return Row(
                  children: [
                    for (var i = 0; i < cards.length; i++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: i == cards.length - 1 ? 0 : 10,
                          ),
                          child: cards[i],
                        ),
                      ),
                  ],
                );
              }
              return Column(
                children: [
                  for (final card in cards)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: SizedBox(width: double.infinity, child: card),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          _Timeline(phase: contest.phase),
          const SizedBox(height: 18),
          _PhaseAction(
            contest: contest,
            onOpenTab: onOpenTab,
            onRun: (title, message, label, action) => _runPhase(
              context,
              title: title,
              message: message,
              confirmLabel: label,
              action: action,
            ),
          ),
        ],
      ),
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline({required this.phase});

  final ContestPhase phase;

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('1', 'Inscrire', ContestPhase.setup),
      ('2', 'Noter 1', ContestPhase.round1),
      ('3', 'Qualifier', ContestPhase.round1Done),
      ('4', 'Noter 2', ContestPhase.round2),
      ('5', 'Résultats', ContestPhase.finished),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.sand),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 28,
                  right: 28,
                  child: Container(
                    height: 2,
                    color: AppColors.sand,
                  ),
                ),
                Row(
                  children: [
                    for (final step in steps)
                      Expanded(
                        child: Center(
                          child: _StepDot(
                            label: step.$1,
                            done: phase.index >= step.$3.index,
                            current: phase == step.$3,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final step in steps)
                Expanded(
                  child: Text(
                    step.$2,
                    textAlign: TextAlign.center,
                    style: outfit(
                      fontSize: 11,
                      fontWeight: phase == step.$3
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: phase == step.$3
                          ? AppColors.navy
                          : AppColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.done,
    required this.current,
  });

  final String label;
  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: current ? 36 : 30,
      height: current ? 36 : 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: done ? AppColors.gold : AppColors.sand,
        shape: BoxShape.circle,
        border: current
            ? Border.all(color: AppColors.cream, width: 3)
            : null,
        boxShadow: current
            ? [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: outfit(
          fontWeight: FontWeight.w700,
          fontSize: 12,
          color: done ? AppColors.cream : AppColors.navyDark,
        ),
      ),
    );
  }
}

class _PhaseAction extends StatelessWidget {
  const _PhaseAction({
    required this.contest,
    required this.onRun,
    this.onOpenTab,
  });

  final ContestController contest;
  final ValueChanged<int>? onOpenTab;
  final void Function(
    String title,
    String message,
    String confirmLabel,
    Future<String?> Function() action,
  ) onRun;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.sand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PROCHAINE ÉTAPE',
            style: outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.3,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 12),
          ..._actions(context),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context) {
    switch (contest.phase) {
      case ContestPhase.setup:
        return [
          OutlinedButton(
            onPressed: () => onOpenTab?.call(1),
            child: const Text('Enregistrer les candidats'),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => onRun(
              'Lancer le Tour 1 ?',
              'Le jury pourra alors noter tous les candidats.',
              'Lancer le Tour 1',
              contest.startRound1,
            ),
            child: const Text('Commencer le Tour 1'),
          ),
        ];
      case ContestPhase.round1:
        return [
          FilledButton(
            onPressed: () => onRun(
              'Clôturer le Tour 1 ?',
              'Les ${contest.qualifyCount} meilleurs seront qualifiés pour le Tour 2. Vérifiez que toutes les notes sont saisies.',
              'Clôturer',
              contest.closeRound1,
            ),
            child: const Text('Clôturer le Tour 1 et qualifier'),
          ),
        ];
      case ContestPhase.round1Done:
        final qualified = contest.candidates.where((c) => c.qualified).length;
        return [
          Text(
            '$qualified candidat(s) qualifié(s) pour le Tour 2.',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => onOpenTab?.call(3),
            child: const Text('Voir le classement du Tour 1'),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => onRun(
              'Lancer le Tour 2 ?',
              'Seuls les finalistes pourront être notés.',
              'Lancer le Tour 2',
              contest.startRound2,
            ),
            child: const Text('Commencer le Tour 2'),
          ),
        ];
      case ContestPhase.round2:
        return [
          FilledButton(
            onPressed: () => onRun(
              'Publier les résultats ?',
              'Le classement final sera figé. Toutes les notes du Tour 2 doivent être saisies.',
              'Publier',
              contest.finishContest,
            ),
            child: const Text('Publier les résultats finaux'),
          ),
        ];
      case ContestPhase.finished:
        return [
          const Text(
            'Le concours est terminé. Consultez le podium dans l’onglet Résultats.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: () => onOpenTab?.call(3),
            child: const Text('Afficher le classement final'),
          ),
        ];
    }
  }
}
