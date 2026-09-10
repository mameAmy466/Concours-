from __future__ import annotations

import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse, RedirectResponse

from . import repository as repo
from .db import init_db
from .schemas import CandidateIn, ContestSettingsIn, ContestSnapshot, ScoreIn

API_TOKEN = os.getenv("API_TOKEN")


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    yield


app = FastAPI(
    title="Jury Concours API",
    description="API et base de données pour l’application jury (2 tours).",
    version="1.0.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.middleware("http")
async def optional_token(request: Request, call_next):
    public = request.url.path in {"/health", "/docs", "/openapi.json", "/redoc"}
    if API_TOKEN and not public:
        if request.headers.get("X-API-Token") != API_TOKEN:
            return JSONResponse({"detail": "Non autorisé"}, status_code=401)
    return await call_next(request)


@app.get("/", include_in_schema=False)
def root() -> RedirectResponse:
    return RedirectResponse(url="/docs")


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/api/contest", response_model=ContestSnapshot)
def get_contest() -> ContestSnapshot:
    return repo.get_snapshot()


@app.patch("/api/contest", response_model=ContestSnapshot)
def patch_contest(payload: ContestSettingsIn) -> ContestSnapshot:
    return repo.update_settings(payload)


@app.post("/api/contest/reset", response_model=ContestSnapshot)
def reset_contest() -> ContestSnapshot:
    return repo.reset_contest()


@app.post("/api/contest/actions/start-round-1", response_model=ContestSnapshot)
def start_round_1() -> ContestSnapshot:
    return repo.start_round_1()


@app.post("/api/contest/actions/close-round-1", response_model=ContestSnapshot)
def close_round_1() -> ContestSnapshot:
    return repo.close_round_1()


@app.post("/api/contest/actions/start-round-2", response_model=ContestSnapshot)
def start_round_2() -> ContestSnapshot:
    return repo.start_round_2()


@app.post("/api/contest/actions/finish", response_model=ContestSnapshot)
def finish_contest() -> ContestSnapshot:
    return repo.finish_contest()


@app.get("/api/candidates")
def list_candidates():
    return repo.get_snapshot().candidates


@app.post("/api/candidates", response_model=ContestSnapshot)
def create_or_update_candidate(payload: CandidateIn) -> ContestSnapshot:
    return repo.upsert_candidate(payload)


@app.put("/api/candidates/{candidate_id}", response_model=ContestSnapshot)
def update_candidate(candidate_id: str, payload: CandidateIn) -> ContestSnapshot:
    payload.id = candidate_id
    return repo.upsert_candidate(payload)


@app.delete("/api/candidates/{candidate_id}", response_model=ContestSnapshot)
def delete_candidate(candidate_id: str) -> ContestSnapshot:
    return repo.delete_candidate(candidate_id)


@app.put("/api/scores/{candidate_id}/{round_number}", response_model=ContestSnapshot)
def put_score(candidate_id: str, round_number: int, payload: ScoreIn) -> ContestSnapshot:
    return repo.save_score(candidate_id, round_number, payload.values)


@app.get("/api/rankings/{round_key}")
def get_rankings(round_key: str):
    if round_key == "final":
        return repo.final_ranking()
    if round_key in {"1", "2"}:
        return repo.ranking_for(int(round_key))
    raise repo.ContestError("Classement inconnu. Utilisez 1, 2 ou final.")
