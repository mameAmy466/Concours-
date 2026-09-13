enum ContestPhase { setup, round1, round1Done, round2, finished }

extension ContestPhaseX on ContestPhase {
  String get label => switch (this) {
        ContestPhase.setup => 'Inscriptions',
        ContestPhase.round1 => 'Tour 1 en cours',
        ContestPhase.round1Done => 'Tour 1 clôturé',
        ContestPhase.round2 => 'Tour 2 en cours',
        ContestPhase.finished => 'Concours terminé',
      };

  int get activeRound => switch (this) {
        ContestPhase.round2 || ContestPhase.finished => 2,
        _ => 1,
      };

  bool get canScore =>
      this == ContestPhase.round1 || this == ContestPhase.round2;

  bool get canEditCandidates =>
      this == ContestPhase.setup || this == ContestPhase.round1;
}

class Criterion {
  Criterion({
    required this.id,
    required this.name,
    this.maxScore = 10,
  });

  final String id;
  String name;
  double maxScore;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'maxScore': maxScore,
      };

  factory Criterion.fromJson(Map<String, dynamic> json) => Criterion(
        id: json['id'] as String,
        name: json['name'] as String,
        maxScore: (json['maxScore'] as num?)?.toDouble() ?? 10,
      );

  static List<Criterion> defaults() => [
        Criterion(id: 'tech', name: 'Technique'),
        Criterion(id: 'pres', name: 'Présentation'),
        Criterion(id: 'orig', name: 'Originalité'),
        Criterion(id: 'impr', name: 'Impression générale'),
      ];
}

class Candidate {
  Candidate({
    required this.id,
    required this.number,
    required this.firstName,
    required this.lastName,
    this.age,
    this.birthPlace = '',
    this.residence = '',
    this.region = '',
    this.residenceYears,
    this.profession = '',
    this.experienceYears,
    this.hafizSince = '',
    this.riwaayat = '',
    this.daara = '',
    this.contact = '',
    this.notes = '',
    this.qualified = false,
  });

  final String id;
  String number;
  String firstName;
  String lastName;
  int? age;
  String birthPlace;
  String residence;
  String region;
  int? residenceYears;
  String profession;
  int? experienceYears;
  String hafizSince;
  String riwaayat;
  String daara;
  String contact;
  String notes;
  bool qualified;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final a = firstName.isNotEmpty ? firstName[0] : '';
    final b = lastName.isNotEmpty ? lastName[0] : '';
    return (a + b).toUpperCase();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'firstName': firstName,
        'lastName': lastName,
        'age': age,
        'birthPlace': birthPlace,
        'residence': residence,
        'region': region,
        'residenceYears': residenceYears,
        'profession': profession,
        'experienceYears': experienceYears,
        'hafizSince': hafizSince,
        'riwaayat': riwaayat,
        'daara': daara,
        'contact': contact,
        'notes': notes,
        'qualified': qualified,
      };

  factory Candidate.fromJson(Map<String, dynamic> json) => Candidate(
        id: json['id'] as String,
        number: json['number'] as String? ?? '',
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        age: (json['age'] as num?)?.toInt(),
        birthPlace: json['birthPlace'] as String? ?? '',
        residence: json['residence'] as String? ?? '',
        region: json['region'] as String? ?? '',
        residenceYears: (json['residenceYears'] as num?)?.toInt(),
        profession: json['profession'] as String? ?? '',
        experienceYears: (json['experienceYears'] as num?)?.toInt(),
        hafizSince: json['hafizSince'] as String? ?? '',
        riwaayat: json['riwaayat'] as String? ?? '',
        daara: json['daara'] as String? ?? '',
        contact: json['contact'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        qualified: json['qualified'] as bool? ?? false,
      );
}

/// Compares two candidates for tie-breaking when their scores are equal:
/// youngest, then least experience, then least time resident in the region
/// wins — per the contest's départage rules. Missing data always loses the
/// tie-break to a candidate with data.
int compareForTieBreak(Candidate a, Candidate b) {
  final ageCmp = _compareNullableAsc(a.age, b.age);
  if (ageCmp != 0) return ageCmp;
  final expCmp = _compareNullableAsc(a.experienceYears, b.experienceYears);
  if (expCmp != 0) return expCmp;
  return _compareNullableAsc(a.residenceYears, b.residenceYears);
}

int _compareNullableAsc(int? a, int? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

class ScoreEntry {
  ScoreEntry({
    required this.candidateId,
    required this.round,
    Map<String, double>? values,
  }) : values = values ?? {};

  final String candidateId;
  final int round;
  final Map<String, double> values;

  bool isComplete(List<Criterion> criteria) =>
      criteria.every((c) => values.containsKey(c.id));

  double total(List<Criterion> criteria) =>
      criteria.fold(0, (sum, c) => sum + (values[c.id] ?? 0));

  Map<String, dynamic> toJson() => {
        'candidateId': candidateId,
        'round': round,
        'values': values,
      };

  factory ScoreEntry.fromJson(Map<String, dynamic> json) {
    final raw = json['values'] as Map<String, dynamic>? ?? {};
    return ScoreEntry(
      candidateId: json['candidateId'] as String,
      round: json['round'] as int,
      values: raw.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }
}

class RankedRow {
  RankedRow({
    required this.rank,
    required this.candidate,
    required this.total,
    required this.maxTotal,
    this.qualified = false,
    this.complete = false,
  });

  final int rank;
  final Candidate candidate;
  final double total;
  final double maxTotal;
  final bool qualified;
  final bool complete;
}

String newId() => DateTime.now().microsecondsSinceEpoch.toString();
