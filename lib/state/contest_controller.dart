import 'package:flutter/widgets.dart';

import '../data/api_client.dart';
import '../data/storage.dart';
import '../models/models.dart';

class ContestController extends ChangeNotifier {
  ContestController({ContestStorage? storage, ApiClient? api})
      : _storage = storage ?? ContestStorage(),
        _api = api;

  final ContestStorage _storage;
  final ApiClient? _api;

  String name = 'Concours';
  ContestPhase phase = ContestPhase.setup;
  int qualifyCount = 5;
  bool combineRounds = false;
  List<Criterion> criteria = Criterion.defaults();
  List<Candidate> candidates = [];
  List<ScoreEntry> scores = [];
  bool ready = false;
  String apiBaseUrl = '';
  bool apiConnected = false;

  bool get usesApi => _api != null && _api.enabled;

  Future<void> load() async {
    try {
      final savedUrl = await _storage.loadApiUrl();
      apiBaseUrl = (savedUrl ?? '').trim();
      if (_api != null) {
        _api.baseUrl = apiBaseUrl;
        await _syncFromApi();
      }
      if (!apiConnected) {
        _applySnapshot(await _storage.load());
      }
    } catch (_) {
      apiConnected = false;
    }
    ready = true;
    notifyListeners();
  }

  Future<void> _syncFromApi() async {
    if (!usesApi) {
      apiConnected = false;
      return;
    }
    try {
      final data = await _api!.getContest();
      _applySnapshot(data);
      await _persist();
      apiConnected = true;
    } catch (_) {
      apiConnected = false;
    }
  }

  void _applySnapshot(Map<String, dynamic>? data) {
    if (data == null) return;
    name = data['name'] as String? ?? 'Concours';
    phase = ContestPhase.values.firstWhere(
      (p) => p.name == data['phase'],
      orElse: () => ContestPhase.setup,
    );
    qualifyCount = data['qualifyCount'] as int? ?? 5;
    combineRounds = data['combineRounds'] as bool? ?? false;
    criteria = (data['criteria'] as List<dynamic>? ?? [])
        .map((e) => Criterion.fromJson(e as Map<String, dynamic>))
        .toList();
    if (criteria.isEmpty) criteria = Criterion.defaults();
    candidates = (data['candidates'] as List<dynamic>? ?? [])
        .map((e) => Candidate.fromJson(e as Map<String, dynamic>))
        .toList();
    scores = (data['scores'] as List<dynamic>? ?? [])
        .map((e) => ScoreEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _persist() async {
    await _storage.save({
      'name': name,
      'phase': phase.name,
      'qualifyCount': qualifyCount,
      'combineRounds': combineRounds,
      'criteria': criteria.map((c) => c.toJson()).toList(),
      'candidates': candidates.map((c) => c.toJson()).toList(),
      'scores': scores.map((s) => s.toJson()).toList(),
    });
  }

  Future<void> _applyRemote(Map<String, dynamic> data) async {
    _applySnapshot(data);
    apiConnected = true;
    await _persist();
    notifyListeners();
  }

  Future<bool> _tryRemote(
    Future<Map<String, dynamic>> Function() call,
  ) async {
    if (!usesApi) return false;
    try {
      await _applyRemote(await call());
      return true;
    } on ApiException catch (e) {
      if (e.statusCode != null) rethrow;
      apiConnected = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> setApiBaseUrl(String url) async {
    apiBaseUrl = url.trim();
    await _storage.saveApiUrl(apiBaseUrl);
    if (_api != null) {
      _api.baseUrl = apiBaseUrl;
      await _syncFromApi();
    }
    notifyListeners();
  }

  Future<bool> testApiConnection() async {
    if (_api == null || !_api.enabled) {
      apiConnected = false;
      notifyListeners();
      return false;
    }
    apiConnected = await _api.ping();
    notifyListeners();
    return apiConnected;
  }

  double get maxRoundTotal =>
      criteria.fold(0, (sum, c) => sum + c.maxScore);

  double get maxFinalTotal =>
      combineRounds ? maxRoundTotal * 2 : maxRoundTotal;

  ScoreEntry? scoreOf(String candidateId, int round) {
    try {
      return scores.firstWhere(
        (s) => s.candidateId == candidateId && s.round == round,
      );
    } catch (_) {
      return null;
    }
  }

  double totalOf(String candidateId, int round) {
    return scoreOf(candidateId, round)?.total(criteria) ?? 0;
  }

  bool isScored(String candidateId, int round) {
    return scoreOf(candidateId, round)?.isComplete(criteria) ?? false;
  }

  List<Candidate> candidatesForRound(int round) {
    if (round == 2) {
      return candidates.where((c) => c.qualified).toList();
    }
    return List.of(candidates);
  }

  int scoredCount(int round) =>
      candidatesForRound(round).where((c) => isScored(c.id, round)).length;

  List<RankedRow> rankingFor(int round) {
    final list = candidatesForRound(round);
    list.sort((a, b) {
      final scoredA = isScored(a.id, round);
      final scoredB = isScored(b.id, round);
      if (scoredA != scoredB) return scoredA ? -1 : 1;
      final cmp = totalOf(b.id, round).compareTo(totalOf(a.id, round));
      if (cmp != 0) return cmp;
      final tie = compareForTieBreak(a, b);
      if (tie != 0) return tie;
      return a.number.compareTo(b.number);
    });
    return [
      for (var i = 0; i < list.length; i++)
        RankedRow(
          rank: i + 1,
          candidate: list[i],
          total: totalOf(list[i].id, round),
          maxTotal: maxRoundTotal,
          qualified: list[i].qualified,
          complete: isScored(list[i].id, round),
        ),
    ];
  }

  double finalTotalOf(Candidate candidate) {
    if (combineRounds) {
      return totalOf(candidate.id, 1) + totalOf(candidate.id, 2);
    }
    return totalOf(candidate.id, 2);
  }

  List<RankedRow> finalRanking() {
    final list = candidates.where((c) => c.qualified).toList();
    list.sort((a, b) {
      final cmp = finalTotalOf(b).compareTo(finalTotalOf(a));
      if (cmp != 0) return cmp;
      final roundCmp = totalOf(b.id, 2).compareTo(totalOf(a.id, 2));
      if (roundCmp != 0) return roundCmp;
      final tie = compareForTieBreak(a, b);
      if (tie != 0) return tie;
      return a.number.compareTo(b.number);
    });
    return [
      for (var i = 0; i < list.length; i++)
        RankedRow(
          rank: i + 1,
          candidate: list[i],
          total: finalTotalOf(list[i]),
          maxTotal: maxFinalTotal,
          qualified: true,
          complete: isScored(list[i].id, 2),
        ),
    ];
  }

  Future<void> updateSettings({
    String? contestName,
    int? qualify,
    bool? combine,
    List<Criterion>? nextCriteria,
  }) async {
    if (await _tryRemote(
      () => _api!.updateSettings({
        if (contestName != null) 'name': contestName,
        if (qualify != null) 'qualifyCount': qualify,
        if (combine != null) 'combineRounds': combine,
        if (nextCriteria != null)
          'criteria': nextCriteria.map((c) => c.toJson()).toList(),
      }),
    )) {
      return;
    }
    if (contestName != null) {
      name = contestName.trim().isEmpty ? 'Concours' : contestName.trim();
    }
    if (qualify != null) qualifyCount = qualify.clamp(1, 99);
    if (combine != null) combineRounds = combine;
    if (nextCriteria != null && nextCriteria.isNotEmpty) {
      criteria = nextCriteria;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> upsertCandidate(Candidate candidate) async {
    if (await _tryRemote(() => _api!.upsertCandidate(candidate.toJson()))) {
      return;
    }
    final index = candidates.indexWhere((c) => c.id == candidate.id);
    if (index >= 0) {
      candidates[index] = candidate;
    } else {
      candidates.add(candidate);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> deleteCandidate(String id) async {
    if (await _tryRemote(() => _api!.deleteCandidate(id))) {
      return;
    }
    candidates.removeWhere((c) => c.id == id);
    scores.removeWhere((s) => s.candidateId == id);
    await _persist();
    notifyListeners();
  }

  Future<void> saveScore({
    required String candidateId,
    required int round,
    required Map<String, double> values,
  }) async {
    if (await _tryRemote(
      () => _api!.saveScore(
        candidateId: candidateId,
        round: round,
        values: values,
      ),
    )) {
      return;
    }
    scores.removeWhere(
      (s) => s.candidateId == candidateId && s.round == round,
    );
    scores.add(ScoreEntry(
      candidateId: candidateId,
      round: round,
      values: Map.of(values),
    ));
    await _persist();
    notifyListeners();
  }

  Future<String?> startRound1() async {
    if (usesApi) {
      try {
        await _applyRemote(await _api!.startRound1());
        return null;
      } on ApiException catch (e) {
        if (e.statusCode != null) return e.message;
        apiConnected = false;
      }
    }
    if (candidates.length < 2) {
      return 'Enregistrez au moins 2 candidats avant de lancer le Tour 1.';
    }
    phase = ContestPhase.round1;
    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> closeRound1() async {
    if (usesApi) {
      try {
        await _applyRemote(await _api!.closeRound1());
        return null;
      } on ApiException catch (e) {
        if (e.statusCode != null) return e.message;
        apiConnected = false;
      }
    }
    if (scoredCount(1) < candidates.length) {
      return 'Tous les candidats doivent être notés avant de clôturer le Tour 1.';
    }
    // Qualification se fait région par région : dans chaque région, les
    // `qualifyCount` premiers (à égalité de note, priorité au départage)
    // représentent leur région au Tour 2.
    final byRegion = <String, List<Candidate>>{};
    for (final c in candidates) {
      byRegion.putIfAbsent(c.region, () => []).add(c);
    }
    for (final group in byRegion.values) {
      group.sort((a, b) {
        final cmp = totalOf(b.id, 1).compareTo(totalOf(a.id, 1));
        if (cmp != 0) return cmp;
        final tie = compareForTieBreak(a, b);
        if (tie != 0) return tie;
        return a.number.compareTo(b.number);
      });
      final n = qualifyCount.clamp(1, group.length);
      for (var i = 0; i < group.length; i++) {
        group[i].qualified = i < n;
      }
    }
    phase = ContestPhase.round1Done;
    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> startRound2() async {
    if (usesApi) {
      try {
        await _applyRemote(await _api!.startRound2());
        return null;
      } on ApiException catch (e) {
        if (e.statusCode != null) return e.message;
        apiConnected = false;
      }
    }
    if (candidates.where((c) => c.qualified).isEmpty) {
      return 'Aucun candidat n’est qualifié pour le Tour 2.';
    }
    phase = ContestPhase.round2;
    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> finishContest() async {
    if (usesApi) {
      try {
        await _applyRemote(await _api!.finishContest());
        return null;
      } on ApiException catch (e) {
        if (e.statusCode != null) return e.message;
        apiConnected = false;
      }
    }
    final qualified = candidatesForRound(2);
    if (scoredCount(2) < qualified.length) {
      return 'Tous les finalistes doivent être notés avant de publier les résultats.';
    }
    phase = ContestPhase.finished;
    await _persist();
    notifyListeners();
    return null;
  }

  Future<void> resetContest() async {
    if (await _tryRemote(() => _api!.resetContest())) {
      return;
    }
    name = 'Concours';
    phase = ContestPhase.setup;
    qualifyCount = 5;
    combineRounds = false;
    criteria = Criterion.defaults();
    candidates = [];
    scores = [];
    await _persist();
    notifyListeners();
  }
}

class ContestScope extends InheritedNotifier<ContestController> {
  const ContestScope({
    super.key,
    required ContestController controller,
    required super.child,
  }) : super(notifier: controller);

  static ContestController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ContestScope>();
    assert(scope != null, 'ContestScope introuvable');
    return scope!.notifier!;
  }
}
