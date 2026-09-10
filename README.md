# Jury Concours

Application jury pour concours (tablette et mobile), avec API REST et base SQLite.

## Application Flutter

```bash
flutter pub get
flutter run
```

Sans serveur, l’app continue de fonctionner en local.

## API et base de données

```bash
cd server
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python run.py
```

- API : http://127.0.0.1:8000
- Documentation : http://127.0.0.1:8000/docs
- Base SQLite : `server/data/concours.db`

Dans l’app, onglet **Réglages** → URL de l’API :

- Mac / simulateur iOS : `http://127.0.0.1:8000`
- Émulateur Android : `http://10.0.2.2:8000`
- Tablette sur le réseau : `http://IP-DU-SERVEUR:8000`

Détail des endpoints : [server/README.md](server/README.md).
