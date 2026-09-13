from __future__ import annotations

import os
import sqlite3
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterator

DEFAULT_CONTEST_ID = "default"
DATA_DIR = Path(__file__).resolve().parent.parent / "data"
DB_PATH = Path(os.getenv("CONCOURS_DB", DATA_DIR / "concours.db"))

DEFAULT_CRITERIA = [
    ("tech", "Technique", 10, 0),
    ("pres", "Présentation", 10, 1),
    ("orig", "Originalité", 10, 2),
    ("impr", "Impression générale", 10, 3),
]


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat()


@contextmanager
def connect() -> Iterator[sqlite3.Connection]:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


_CANDIDATE_COLUMNS = [
    ("age", "INTEGER"),
    ("birth_place", "TEXT NOT NULL DEFAULT ''"),
    ("residence", "TEXT NOT NULL DEFAULT ''"),
    ("region", "TEXT NOT NULL DEFAULT ''"),
    ("residence_years", "INTEGER"),
    ("profession", "TEXT NOT NULL DEFAULT ''"),
    ("experience_years", "INTEGER"),
    ("hafiz_since", "TEXT NOT NULL DEFAULT ''"),
    ("riwaayat", "TEXT NOT NULL DEFAULT ''"),
    ("daara", "TEXT NOT NULL DEFAULT ''"),
    ("contact", "TEXT NOT NULL DEFAULT ''"),
]


def _migrate_candidate_columns(conn: sqlite3.Connection) -> None:
    existing = {
        row["name"] for row in conn.execute("PRAGMA table_info(candidates)").fetchall()
    }
    for name, definition in _CANDIDATE_COLUMNS:
        if name not in existing:
            conn.execute(f"ALTER TABLE candidates ADD COLUMN {name} {definition}")


def init_db() -> None:
    with connect() as conn:
        conn.executescript(
            """
            CREATE TABLE IF NOT EXISTS contest (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                phase TEXT NOT NULL DEFAULT 'setup',
                qualify_count INTEGER NOT NULL DEFAULT 5,
                combine_rounds INTEGER NOT NULL DEFAULT 0,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS criteria (
                id TEXT PRIMARY KEY,
                contest_id TEXT NOT NULL,
                name TEXT NOT NULL,
                max_score REAL NOT NULL DEFAULT 10,
                sort_order INTEGER NOT NULL DEFAULT 0,
                FOREIGN KEY (contest_id) REFERENCES contest(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS candidates (
                id TEXT PRIMARY KEY,
                contest_id TEXT NOT NULL,
                number TEXT NOT NULL,
                first_name TEXT NOT NULL,
                last_name TEXT NOT NULL,
                age INTEGER,
                birth_place TEXT NOT NULL DEFAULT '',
                residence TEXT NOT NULL DEFAULT '',
                region TEXT NOT NULL DEFAULT '',
                residence_years INTEGER,
                profession TEXT NOT NULL DEFAULT '',
                experience_years INTEGER,
                hafiz_since TEXT NOT NULL DEFAULT '',
                riwaayat TEXT NOT NULL DEFAULT '',
                daara TEXT NOT NULL DEFAULT '',
                contact TEXT NOT NULL DEFAULT '',
                notes TEXT NOT NULL DEFAULT '',
                qualified INTEGER NOT NULL DEFAULT 0,
                FOREIGN KEY (contest_id) REFERENCES contest(id) ON DELETE CASCADE
            );

            CREATE TABLE IF NOT EXISTS scores (
                candidate_id TEXT NOT NULL,
                contest_id TEXT NOT NULL,
                round INTEGER NOT NULL,
                criterion_id TEXT NOT NULL,
                value REAL NOT NULL,
                PRIMARY KEY (candidate_id, round, criterion_id),
                FOREIGN KEY (candidate_id) REFERENCES candidates(id) ON DELETE CASCADE,
                FOREIGN KEY (contest_id) REFERENCES contest(id) ON DELETE CASCADE
            );
            """
        )
        _migrate_candidate_columns(conn)
        row = conn.execute(
            "SELECT id FROM contest WHERE id = ?",
            (DEFAULT_CONTEST_ID,),
        ).fetchone()
        if row is None:
            now = utc_now()
            conn.execute(
                """
                INSERT INTO contest (id, name, phase, qualify_count, combine_rounds, created_at, updated_at)
                VALUES (?, ?, 'setup', 5, 0, ?, ?)
                """,
                (DEFAULT_CONTEST_ID, "Concours", now, now),
            )
            conn.executemany(
                """
                INSERT INTO criteria (id, contest_id, name, max_score, sort_order)
                VALUES (?, ?, ?, ?, ?)
                """,
                [
                    (cid, DEFAULT_CONTEST_ID, name, max_score, order)
                    for cid, name, max_score, order in DEFAULT_CRITERIA
                ],
            )
