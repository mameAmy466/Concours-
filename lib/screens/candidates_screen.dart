import 'package:flutter/material.dart';

import '../models/models.dart';
import '../state/contest_controller.dart';
import '../theme.dart';
import '../widgets/widgets.dart';
import 'candidate_form_screen.dart';

class CandidatesScreen extends StatefulWidget {
  const CandidatesScreen({super.key});

  @override
  State<CandidatesScreen> createState() => _CandidatesScreenState();
}

class _CandidatesScreenState extends State<CandidatesScreen> {
  String _query = '';
  Candidate? _selected;

  void _openForm(Candidate? candidate) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CandidateFormScreen(candidate: candidate),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contest = ContestScope.of(context);
    final filtered = contest.candidates.where((c) {
      final q = _query.toLowerCase();
      return q.isEmpty ||
          c.fullName.toLowerCase().contains(q) ||
          c.number.toLowerCase().contains(q) ||
          c.residence.toLowerCase().contains(q) ||
          c.region.toLowerCase().contains(q) ||
          c.daara.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.number.compareTo(b.number));

    final list = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Rechercher un candidat',
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? EmptyState(
                  icon: Icons.people_outline,
                  title: contest.candidates.isEmpty
                      ? 'Aucun candidat'
                      : 'Aucun résultat',
                  message: contest.candidates.isEmpty
                      ? 'Enregistrez les candidats avant de lancer le Tour 1.'
                      : 'Essayez un autre nom ou numéro.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final candidate = filtered[index];
                    return CandidateTile(
                      candidate: candidate,
                      selected: _selected?.id == candidate.id,
                      subtitle: candidate.qualified ? 'Qualifié Tour 2' : null,
                      onTap: () {
                        if (Breakpoints.isWide(context)) {
                          setState(() => _selected = candidate);
                        } else {
                          _openForm(candidate);
                        }
                      },
                      trailing: contest.phase.canEditCandidates
                          ? IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                final ok = await confirmAction(
                                  context,
                                  title: 'Supprimer ${candidate.fullName} ?',
                                  message:
                                      'Les notes associées seront aussi effacées.',
                                  confirmLabel: 'Supprimer',
                                );
                                if (ok) {
                                  await contest.deleteCandidate(candidate.id);
                                  if (_selected?.id == candidate.id) {
                                    setState(() => _selected = null);
                                  }
                                }
                              },
                            )
                          : null,
                    );
                  },
                ),
        ),
      ],
    );

    final body = Breakpoints.isWide(context)
        ? Row(
            children: [
              Expanded(flex: 5, child: list),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 4,
                child: _selected == null
                    ? const EmptyState(
                        icon: Icons.person_search_outlined,
                        title: 'Détail candidat',
                        message: 'Sélectionnez un candidat pour le modifier.',
                      )
                    : CandidateFormScreen(
                        key: ValueKey(_selected!.id),
                        candidate: _selected,
                        embedded: true,
                      ),
              ),
            ],
          )
        : list;

    return Scaffold(
      appBar: AppBar(
        title: Text('Candidats (${contest.candidates.length})'),
      ),
      body: body,
      floatingActionButton: contest.phase.canEditCandidates
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(null),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Nouveau'),
            )
          : null,
    );
  }
}
