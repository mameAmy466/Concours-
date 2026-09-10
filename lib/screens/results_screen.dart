import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/contest_controller.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key});

  String _export(ContestController contest, String title, List<RankedRow> rows) {
    final buffer = StringBuffer()
      ..writeln(contest.name)
      ..writeln(title)
      ..writeln('');
    for (final row in rows) {
      buffer.writeln(
        '${row.rank}. ${row.candidate.fullName} (N° ${row.candidate.number}) — ${formatScore(row.total)} / ${formatScore(row.maxTotal)}',
      );
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final contest = ContestScope.of(context);
    final showFinal = contest.phase == ContestPhase.round2 ||
        contest.phase == ContestPhase.finished;

    return DefaultTabController(
      length: showFinal ? 3 : 1,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Résultats'),
          bottom: TabBar(
            indicatorColor: AppColors.gold,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              const Tab(text: 'Tour 1'),
              if (showFinal) const Tab(text: 'Tour 2'),
              if (showFinal) const Tab(text: 'Final'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RoundResults(
              title: 'Classement Tour 1',
              rows: contest.rankingFor(1),
              showQualify: contest.phase.index >= ContestPhase.round1Done.index,
              onExport: (rows) => copyRanking(
                context,
                _export(contest, 'Classement Tour 1', rows),
              ),
            ),
            if (showFinal)
              _RoundResults(
                title: 'Classement Tour 2',
                rows: contest.rankingFor(2),
                onExport: (rows) => copyRanking(
                  context,
                  _export(contest, 'Classement Tour 2', rows),
                ),
              ),
            if (showFinal)
              _RoundResults(
                title: contest.combineRounds
                    ? 'Classement final (Tour 1 + Tour 2)'
                    : 'Classement final (Tour 2)',
                rows: contest.finalRanking(),
                highlightPodium: contest.phase == ContestPhase.finished,
                onExport: (rows) => copyRanking(
                  context,
                  _export(contest, 'Classement final', rows),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoundResults extends StatelessWidget {
  const _RoundResults({
    required this.title,
    required this.rows,
    required this.onExport,
    this.showQualify = false,
    this.highlightPodium = false,
  });

  final String title;
  final List<RankedRow> rows;
  final bool showQualify;
  final bool highlightPodium;
  final ValueChanged<List<RankedRow>> onExport;

  @override
  Widget build(BuildContext context) {
    final podium = highlightPodium ? rows.take(3).toList() : const <RankedRow>[];
    final rest = highlightPodium ? rows.skip(3).toList() : rows;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              TextButton.icon(
                onPressed: rows.isEmpty ? null : () => onExport(rows),
                icon: const Icon(Icons.copy),
                label: const Text('Copier'),
              ),
            ],
          ),
        ),
        if (podium.isNotEmpty) _Podium(rows: podium),
        Expanded(
          child: RankingList(
            rows: highlightPodium ? rest : rows,
            showQualify: showQualify,
          ),
        ),
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.rows});

  final List<RankedRow> rows;

  @override
  Widget build(BuildContext context) {
    RankedRow? at(int rank) {
      try {
        return rows.firstWhere((r) => r.rank == rank);
      } catch (_) {
        return null;
      }
    }

    Widget slot(
      RankedRow? row, {
      required double top,
      required Color color,
      required Color foreground,
    }) {
      if (row == null) return const Expanded(child: SizedBox.shrink());
      final first = row.rank == 1;
      return Expanded(
        child: Padding(
          padding: EdgeInsets.only(top: top),
          child: Column(
            children: [
              if (first)
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(
                    Icons.workspace_premium,
                    color: AppColors.gold,
                    size: 22,
                  ),
                ),
              Text(
                row.candidate.fullName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: outfit(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(18),
                      bottom: Radius.circular(10),
                    ),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${row.rank}',
                        style: displaySerif(
                          fontSize: first ? 32 : 26,
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                      Text(
                        formatScore(row.total),
                        style: outfit(
                          fontWeight: FontWeight.w600,
                          color: foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: SizedBox(
        height: 210,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            slot(at(2), top: 48, color: AppColors.gold, foreground: AppColors.cream),
            slot(at(1), top: 0, color: AppColors.goldSoft, foreground: AppColors.navyDark),
            slot(at(3), top: 72, color: AppColors.sand, foreground: AppColors.navyDark),
          ],
        ),
      ),
    );
  }
}
