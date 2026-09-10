from __future__ import annotations

from collections import defaultdict
from uuid import uuid4

from fastapi import HTTPException

from .db import DEFAULT_CONTEST_ID, DEFAULT_CRITERIA, connect, utc_now
from .schemas import (
    CandidateIn,
    CandidateOut,
    ContestSettingsIn,
    ContestSnapshot,
    CriterionIn,
    CriterionOut,
    RankedRowOut,
    ScoreOut,
)

class ContestError(HTTPException):
    def __init__(self, message: str) -> None:
        super().__init__(status_code=400, detail=message)


def _candidate_out(row) -> CandidateOut:
    return CandidateOut(
        id=row["id"],
        number=row["number"],
        first_name=row["first_name"],
        last_name=row["last_name"],
        city=row["city"],
        notes=row["notes"],
        qualified=bool(row["qualified"]),
    )


def get_snapshot(contest_id: str = DEFAULT_CONTEST_ID) -> ContestSnapshot:
    with connect() as conn:
        contest = conn.execute(
            "SELECT * FROM contest WHERE id = ?",
            (contest_id,),
        ).fetchone()
        if contest is None:
            raise HTTPException(status_code=404, detail="Concours introuvable")

        criteria = conn.execute(
            """
            SELECT * FROM criteria
            WHERE contest_id = ?
            ORDER BY sort_order, name
            """,
            (contest_id,),
        ).fetchall()
        candidates = conn.execute(
            """
            SELECT * FROM candidates
            WHERE contest_id = ?
            ORDER BY number, last_name
            """,
            (contest_id,),
        ).fetchall()
        scores = conn.execute(
            "SELECT * FROM scores WHERE contest_id = ?",
            (contest_id,),
        ).fetchall()

    grouped: dict[tuple[str, int], dict[str, float]] = defaultdict(dict)
    for row in scores:
        grouped[(row["candidate_id"], row["round"])][row["criterion_id"]] = float(
            row["value"]
        )

    return ContestSnapshot(
        id=contest["id"],
        name=contest["name"],
        phase=contest["phase"],
        qualify_count=contest["qualify_count"],
        combine_rounds=bool(contest["combine_rounds"]),
        criteria=[
            CriterionOut(
                id=row["id"],
                name=row["name"],
                max_score=float(row["max_score"]),
            )
            for row in criteria
        ],
        candidates=[_candidate_out(row) for row in candidates],
        scores=[
            ScoreOut(candidate_id=cid, round=rnd, values=values)
            for (cid, rnd), values in grouped.items()
        ],
    )


def _touch(conn, contest_id: str) -> None:
    conn.execute(
        "UPDATE contest SET updated_at = ? WHERE id = ?",
        (utc_now(), contest_id),
    )


def update_settings(
    payload: ContestSettingsIn,
    contest_id: str = DEFAULT_CONTEST_ID,
) -> ContestSnapshot:
    with connect() as conn:
        contest = conn.execute(
            "SELECT * FROM contest WHERE id = ?",
            (contest_id,),
        ).fetchone()
        if contest is None:
            raise HTTPException(status_code=404, detail="Concours introuvable")

        name = contest["name"]
        if payload.name is not None:
            name = payload.name.strip() or "Concours"

        qualify = contest["qualify_count"]
        if payload.qualify_count is not None:
            qualify = max(1, min(99, payload.qualify_count))

        combine = contest["combine_rounds"]
        if payload.combine_rounds is not None:
            combine = 1 if payload.combine_rounds else 0

        conn.execute(
            """
            UPDATE contest
            SET name = ?, qualify_count = ?, combine_rounds = ?, updated_at = ?
            WHERE id = ?
            """,
            (name, qualify, combine, utc_now(), contest_id),
        )

        if payload.criteria:
            _replace_criteria(conn, contest_id, payload.criteria)
    return get_snapshot(contest_id)


def _replace_criteria(
    conn,
    contest_id: str,
    criteria: list[CriterionIn],
) -> None:
    score_count = conn.execute(
        "SELECT COUNT(*) AS n FROM scores WHERE contest_id = ?",
        (contest_id,),
    ).fetchone()["n"]
    existing = {
        row["id"]: row
        for row in conn.execute(
            "SELECT * FROM criteria WHERE contest_id = ?",
            (contest_id,),
        ).fetchall()
    }

    if score_count > 0:
        for item in criteria:
            if item.id in existing:
                conn.execute(
                    "UPDATE criteria SET name = ? WHERE id = ? AND contest_id = ?",
                    (item.name.strip() or existing[item.id]["name"], item.id, contest_id),
                )
        return

    conn.execute("DELETE FROM criteria WHERE contest_id = ?", (contest_id,))
    for index, item in enumerate(criteria):
        conn.execute(
            """
            INSERT INTO criteria (id, contest_id, name, max_score, sort_order)
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                item.id,
                contest_id,
                item.name.strip() or f"Critère {index + 1}",
                item.max_score if item.max_score > 0 else 10,
                index,
            ),
        )


def upsert_candidate(
    payload: CandidateIn,
    contest_id: str = DEFAULT_CONTEST_ID,
) -> ContestSnapshot:
    candidate_id = payload.id or str(uuid4())
    with connect() as conn:
        exists = conn.execute(
            "SELECT id FROM candidates WHERE id = ? AND contest_id = ?",
            (candidate_id, contest_id),
        ).fetchone()
        if exists:
            conn.execute(
                """
                UPDATE candidates
                SET number = ?, first_name = ?, last_name = ?, city = ?, notes = ?, qualified = ?
                WHERE id = ? AND contest_id = ?
                """,
                (
                    payload.number.strip(),
                    payload.first_name.strip(),
                    payload.last_name.strip(),
                    payload.city.strip(),
                    payload.notes.strip(),
                    1 if payload.qualified else 0,
                    candidate_id,
                    contest_id,
                ),
            )
        else:
            conn.execute(
                """
                INSERT INTO candidates
                (id, contest_id, number, first_name, last_name, city, notes, qualified)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """,
                (
                    candidate_id,
                    contest_id,
                    payload.number.strip(),
                    payload.first_name.strip(),
                    payload.last_name.strip(),
                    payload.city.strip(),
                    payload.notes.strip(),
                    1 if payload.qualified else 0,
                ),
            )
        _touch(conn, contest_id)
    return get_snapshot(contest_id)


def delete_candidate(candidate_id: str, contest_id: str = DEFAULT_CONTEST_ID) -> ContestSnapshot:
    with connect() as conn:
        conn.execute(
            "DELETE FROM candidates WHERE id = ? AND contest_id = ?",
            (candidate_id, contest_id),
        )
        _touch(conn, contest_id)
    return get_snapshot(contest_id)


def save_score(
    candidate_id: str,
    round_number: int,
    values: dict[str, float],
    contest_id: str = DEFAULT_CONTEST_ID,
) -> ContestSnapshot:
    if round_number not in (1, 2):
        raise ContestError("Le tour doit être 1 ou 2.")
    with connect() as conn:
        candidate = conn.execute(
            "SELECT id FROM candidates WHERE id = ? AND contest_id = ?",
            (candidate_id, contest_id),
        ).fetchone()
        if candidate is None:
            raise HTTPException(status_code=404, detail="Candidat introuvable")

        criteria = conn.execute(
            "SELECT id FROM criteria WHERE contest_id = ?",
            (contest_id,),
        ).fetchall()
        known = {row["id"] for row in criteria}

        conn.execute(
            "DELETE FROM scores WHERE candidate_id = ? AND round = ? AND contest_id = ?",
            (candidate_id, round_number, contest_id),
        )
        for criterion_id, value in values.items():
            if criterion_id not in known:
                continue
            conn.execute(
                """
                INSERT INTO scores (candidate_id, contest_id, round, criterion_id, value)
                VALUES (?, ?, ?, ?, ?)
                """,
                (candidate_id, contest_id, round_number, criterion_id, float(value)),
            )
        _touch(conn, contest_id)
    return get_snapshot(contest_id)


def _set_phase(conn, contest_id: str, phase: str) -> None:
    conn.execute(
        "UPDATE contest SET phase = ?, updated_at = ? WHERE id = ?",
        (phase, utc_now(), contest_id),
    )


def start_round_1(contest_id: str = DEFAULT_CONTEST_ID) -> ContestSnapshot:
    snapshot = get_snapshot(contest_id)
    if snapshot.phase != "setup":
        raise ContestError("Le Tour 1 ne peut être lancé que depuis les inscriptions.")
    if len(snapshot.candidates) < 2:
        raise ContestError("Enregistrez au moins 2 candidats avant de lancer le Tour 1.")
    with connect() as conn:
        _set_phase(conn, contest_id, "round1")
    return get_snapshot(contest_id)


def close_round_1(contest_id: str = DEFAULT_CONTEST_ID) -> ContestSnapshot:
    snapshot = get_snapshot(contest_id)
    if snapshot.phase != "round1":
        raise ContestError("Le Tour 1 n’est pas en cours.")
    ranking = ranking_for(1, snapshot)
    if sum(1 for row in ranking if row.complete) < len(snapshot.candidates):
        raise ContestError(
            "Tous les candidats doivent être notés avant de clôturer le Tour 1."
        )
    qualify = max(1, min(snapshot.qualify_count, len(ranking)))
    with connect() as conn:
        conn.execute(
            "UPDATE candidates SET qualified = 0 WHERE contest_id = ?",
            (contest_id,),
        )
        for row in ranking[:qualify]:
            conn.execute(
                "UPDATE candidates SET qualified = 1 WHERE id = ? AND contest_id = ?",
                (row.candidate.id, contest_id),
            )
        _set_phase(conn, contest_id, "round1Done")
    return get_snapshot(contest_id)


def start_round_2(contest_id: str = DEFAULT_CONTEST_ID) -> ContestSnapshot:
    snapshot = get_snapshot(contest_id)
    if snapshot.phase != "round1Done":
        raise ContestError("Le Tour 2 ne peut être lancé qu’après la clôture du Tour 1.")
    if not any(c.qualified for c in snapshot.candidates):
        raise ContestError("Aucun candidat n’est qualifié pour le Tour 2.")
    with connect() as conn:
        _set_phase(conn, contest_id, "round2")
    return get_snapshot(contest_id)


def finish_contest(contest_id: str = DEFAULT_CONTEST_ID) -> ContestSnapshot:
    snapshot = get_snapshot(contest_id)
    if snapshot.phase != "round2":
        raise ContestError("Les résultats ne peuvent être publiés que pendant le Tour 2.")
    ranking = ranking_for(2, snapshot)
    if sum(1 for row in ranking if row.complete) < len(ranking):
        raise ContestError(
            "Tous les finalistes doivent être notés avant de publier les résultats."
        )
    with connect() as conn:
        _set_phase(conn, contest_id, "finished")
    return get_snapshot(contest_id)


def reset_contest(contest_id: str = DEFAULT_CONTEST_ID) -> ContestSnapshot:
    now = utc_now()
    with connect() as conn:
        conn.execute("DELETE FROM scores WHERE contest_id = ?", (contest_id,))
        conn.execute("DELETE FROM candidates WHERE contest_id = ?", (contest_id,))
        conn.execute("DELETE FROM criteria WHERE contest_id = ?", (contest_id,))
        conn.execute(
            """
            UPDATE contest
            SET name = 'Concours', phase = 'setup', qualify_count = 5,
                combine_rounds = 0, updated_at = ?
            WHERE id = ?
            """,
            (now, contest_id),
        )
        conn.executemany(
            """
            INSERT INTO criteria (id, contest_id, name, max_score, sort_order)
            VALUES (?, ?, ?, ?, ?)
            """,
            [
                (cid, contest_id, name, max_score, order)
                for cid, name, max_score, order in DEFAULT_CRITERIA
            ],
        )
    return get_snapshot(contest_id)


def _score_map(snapshot: ContestSnapshot) -> dict[tuple[str, int], dict[str, float]]:
    return {(s.candidate_id, s.round): s.values for s in snapshot.scores}


def _is_complete(values: dict[str, float] | None, snapshot: ContestSnapshot) -> bool:
    if not values:
        return False
    return all(c.id in values for c in snapshot.criteria)


def _total(values: dict[str, float] | None, snapshot: ContestSnapshot) -> float:
    if not values:
        return 0.0
    return sum(values.get(c.id, 0.0) for c in snapshot.criteria)


def _max_round_total(snapshot: ContestSnapshot) -> float:
    return sum(c.max_score for c in snapshot.criteria)


def ranking_for(round_number: int, snapshot: ContestSnapshot | None = None) -> list[RankedRowOut]:
    snapshot = snapshot or get_snapshot()
    scores = _score_map(snapshot)
    if round_number == 2:
        candidates = [c for c in snapshot.candidates if c.qualified]
    else:
        candidates = list(snapshot.candidates)

    def sort_key(candidate: CandidateOut):
        values = scores.get((candidate.id, round_number))
        complete = _is_complete(values, snapshot)
        total = _total(values, snapshot)
        return (0 if complete else 1, -total, candidate.number)

    candidates.sort(key=sort_key)
    max_total = _max_round_total(snapshot)
    return [
        RankedRowOut(
            rank=index + 1,
            candidate=candidate,
            total=_total(scores.get((candidate.id, round_number)), snapshot),
            max_total=max_total,
            qualified=candidate.qualified,
            complete=_is_complete(scores.get((candidate.id, round_number)), snapshot),
        )
        for index, candidate in enumerate(candidates)
    ]


def final_ranking(snapshot: ContestSnapshot | None = None) -> list[RankedRowOut]:
    snapshot = snapshot or get_snapshot()
    scores = _score_map(snapshot)
    candidates = [c for c in snapshot.candidates if c.qualified]
    max_round = _max_round_total(snapshot)
    max_final = max_round * 2 if snapshot.combine_rounds else max_round

    def final_total(candidate: CandidateOut) -> float:
        if snapshot.combine_rounds:
            return _total(scores.get((candidate.id, 1)), snapshot) + _total(
                scores.get((candidate.id, 2)), snapshot
            )
        return _total(scores.get((candidate.id, 2)), snapshot)

    candidates.sort(
        key=lambda c: (
            -final_total(c),
            -_total(scores.get((c.id, 2)), snapshot),
            c.number,
        )
    )
    return [
        RankedRowOut(
            rank=index + 1,
            candidate=candidate,
            total=final_total(candidate),
            max_total=max_final,
            qualified=True,
            complete=_is_complete(scores.get((candidate.id, 2)), snapshot),
        )
        for index, candidate in enumerate(candidates)
    ]
