import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/contest_controller.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class ScoringScreen extends StatefulWidget {
  const ScoringScreen({super.key});

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

class _ScoringScreenState extends State<ScoringScreen> {
  Candidate? _selected;

  int _round(ContestController contest) => contest.phase.activeRound;

  @override
  Widget build(BuildContext context) {
    final contest = ContestScope.of(context);
    final round = _round(contest);
    final list = contest.candidatesForRound(round)
      ..sort((a, b) => a.number.compareTo(b.number));

    Candidate? selected;
    if (_selected != null) {
      for (final candidate in list) {
        if (candidate.id == _selected!.id) {
          selected = candidate;
          break;
        }
      }
    }

    final candidateList = list.isEmpty
        ? EmptyState(
            icon: Icons.stars_outlined,
            title: round == 2 ? 'Pas encore de finalistes' : 'Aucun candidat',
            message: round == 2
                ? 'Clôturez le Tour 1 pour qualifier les candidats du Tour 2.'
                : 'Enregistrez d’abord les candidats.',
          )
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final candidate = list[index];
              final scored = contest.isScored(candidate.id, round);
              return CandidateTile(
                candidate: candidate,
                selected: _selected?.id == candidate.id,
                subtitle: scored
                    ? 'Noté · ${formatScore(contest.totalOf(candidate.id, round))}'
                    : 'En attente de note',
                trailing: Icon(
                  scored ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: scored ? AppColors.success : AppColors.muted,
                ),
                onTap: () {
                  if (Breakpoints.isWide(context)) {
                    setState(() => _selected = candidate);
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScoreDetailScreen(
                          candidateId: candidate.id,
                          round: round,
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );

    final panel = selected == null
        ? const EmptyState(
            icon: Icons.edit_note,
            title: 'Noter un candidat',
            message: 'Choisissez un candidat à gauche pour saisir sa note.',
          )
        : ScorePanel(
            key: ValueKey('${selected.id}-$round'),
            candidate: selected,
            round: round,
            criteria: contest.criteria,
            initial: contest.scoreOf(selected.id, round)?.values ?? {},
            readOnly: !contest.phase.canScore,
            onSave: (values) async {
              await contest.saveScore(
                candidateId: selected!.id,
                round: round,
                values: values,
              );
              if (context.mounted) showInfo(context, 'Note enregistrée');
            },
          );

    return Scaffold(
      appBar: AppBar(
        title: Text('Notation · Tour $round'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${contest.scoredCount(round)} / ${list.length}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: Breakpoints.isWide(context)
          ? Row(
              children: [
                SizedBox(width: 380, child: candidateList),
                const VerticalDivider(width: 1),
                Expanded(child: panel),
              ],
            )
          : candidateList,
    );
  }
}

class ScoreDetailScreen extends StatelessWidget {
  const ScoreDetailScreen({
    super.key,
    required this.candidateId,
    required this.round,
  });

  final String candidateId;
  final int round;

  @override
  Widget build(BuildContext context) {
    final contest = ContestScope.of(context);
    final candidate = contest.candidates.firstWhere((c) => c.id == candidateId);

    return Scaffold(
      appBar: AppBar(title: const Text('Saisie de note')),
      body: ScorePanel(
        candidate: candidate,
        round: round,
        criteria: contest.criteria,
        initial: contest.scoreOf(candidate.id, round)?.values ?? {},
        readOnly: !contest.phase.canScore,
        onSave: (values) async {
          await contest.saveScore(
            candidateId: candidate.id,
            round: round,
            values: values,
          );
          if (context.mounted) {
            showInfo(context, 'Note enregistrée');
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
