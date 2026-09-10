# API Jury Concours

API REST + base SQLite pour l’application jury (candidats, notes, 2 tours, classements).

## Démarrage

```bash
cd server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python run.py
```

- API : http://127.0.0.1:8000
- Documentation interactive : http://127.0.0.1:8000/docs
- Fichier SQLite : `server/data/concours.db`

Sur tablette / téléphone du même réseau, utilisez l’IP de l’ordinateur (`http://192.168.x.x:8000`) dans les réglages de l’app.

Émulateur Android : `http://10.0.2.2:8000`

Jeton optionnel : `API_TOKEN=secret python run.py` puis en-tête `X-API-Token: secret`.

## Endpoints

| Méthode | Chemin | Rôle |
|---|---|---|
| GET | `/health` | Santé du serveur |
| GET | `/api/contest` | Snapshot complet (réglages, candidats, notes) |
| PATCH | `/api/contest` | Nom, finalistes, barème, critères |
| POST | `/api/contest/reset` | Nouveau concours |
| POST | `/api/contest/actions/start-round-1` | Lancer le Tour 1 |
| POST | `/api/contest/actions/close-round-1` | Qualifier les meilleurs |
| POST | `/api/contest/actions/start-round-2` | Lancer le Tour 2 |
| POST | `/api/contest/actions/finish` | Publier les résultats |
| POST / PUT | `/api/candidates` | Créer / modifier un candidat |
| DELETE | `/api/candidates/{id}` | Supprimer un candidat |
| PUT | `/api/scores/{id}/{round}` | Enregistrer une note |
| GET | `/api/rankings/1` `/2` `/final` | Classements |

Le JSON utilise le camelCase de l’app Flutter (`firstName`, `qualifyCount`, `combineRounds`).
