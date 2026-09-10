import 'package:concours_jury/models/models.dart';
import 'package:concours_jury/state/contest_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:concours_jury/data/storage.dart';

class MemoryStorage extends ContestStorage {
  Map<String, dynamic>? data;

  @override
  Future<Map<String, dynamic>?> load() async => data;

  @override
  Future<void> save(Map<String, dynamic> next) async {
    data = next;
  }

  @override
  Future<void> clear() async {
    data = null;
  }
}

void main() {
  test('le Tour 1 qualifie les meilleurs et le final suit le Tour 2', () async {
    final contest = ContestController(storage: MemoryStorage());
    contest.qualifyCount = 2;

    await contest.upsertCandidate(
      Candidate(id: 'a', number: '1', firstName: 'Awa', lastName: 'Ndiaye'),
    );
    await contest.upsertCandidate(
      Candidate(id: 'b', number: '2', firstName: 'Binta', lastName: 'Fall'),
    );
    await contest.upsertCandidate(
      Candidate(id: 'c', number: '3', firstName: 'Cisse', lastName: 'Ba'),
    );

    expect(await contest.startRound1(), isNull);

    await contest.saveScore(
      candidateId: 'a',
      round: 1,
      values: {for (final c in contest.criteria) c.id: 8},
    );
    await contest.saveScore(
      candidateId: 'b',
      round: 1,
      values: {for (final c in contest.criteria) c.id: 6},
    );
    await contest.saveScore(
      candidateId: 'c',
      round: 1,
      values: {for (final c in contest.criteria) c.id: 9},
    );

    expect(await contest.closeRound1(), isNull);
    expect(contest.candidates.firstWhere((c) => c.id == 'a').qualified, isTrue);
    expect(contest.candidates.firstWhere((c) => c.id == 'c').qualified, isTrue);
    expect(contest.candidates.firstWhere((c) => c.id == 'b').qualified, isFalse);

    expect(await contest.startRound2(), isNull);
    await contest.saveScore(
      candidateId: 'c',
      round: 2,
      values: {for (final cr in contest.criteria) cr.id: 7},
    );
    await contest.saveScore(
      candidateId: 'a',
      round: 2,
      values: {for (final cr in contest.criteria) cr.id: 10},
    );

    expect(await contest.finishContest(), isNull);
    expect(contest.finalRanking().first.candidate.id, 'a');
  });
}
