from __future__ import annotations

from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel


class CamelModel(BaseModel):
    model_config = ConfigDict(
        alias_generator=to_camel,
        populate_by_name=True,
    )


class CriterionIn(CamelModel):
    id: str
    name: str
    max_score: float = 10


class CriterionOut(CamelModel):
    id: str
    name: str
    max_score: float


class CandidateIn(CamelModel):
    id: str | None = None
    number: str
    first_name: str
    last_name: str
    city: str = ""
    notes: str = ""
    qualified: bool = False


class CandidateOut(CamelModel):
    id: str
    number: str
    first_name: str
    last_name: str
    city: str = ""
    notes: str = ""
    qualified: bool = False


class ScoreIn(CamelModel):
    values: dict[str, float] = Field(default_factory=dict)


class ScoreOut(CamelModel):
    candidate_id: str
    round: int
    values: dict[str, float]


class ContestSettingsIn(CamelModel):
    name: str | None = None
    qualify_count: int | None = None
    combine_rounds: bool | None = None
    criteria: list[CriterionIn] | None = None


class ContestSnapshot(CamelModel):
    id: str
    name: str
    phase: str
    qualify_count: int
    combine_rounds: bool
    criteria: list[CriterionOut]
    candidates: list[CandidateOut]
    scores: list[ScoreOut]


class RankedRowOut(CamelModel):
    rank: int
    candidate: CandidateOut
    total: float
    max_total: float
    qualified: bool = False
    complete: bool = False
