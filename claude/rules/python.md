---
paths: ["**/*.py"]
---

# Regeln für Python-Dateien

Diese Regeln gelten zusätzlich zu `~/.claude/CLAUDE.md`, sobald du eine `.py`-Datei liest oder bearbeitest.

## Stil und Werkzeuge

- Der Code muss `ruff format --check .` und `ruff check .` ohne Befunde bestehen. Führe beides nach jeder Änderung aus.
- Zeilenlänge 100 Zeichen (Ruff `line-length = 100`). Keine `# noqa`, ausser mit Regelcode und Begründung, z. B. `# noqa: E501 -- long URL`.
- Imports oben in der Datei, sortiert (Ruff-Regel `I`): Standardbibliothek, Drittanbieter, eigenes Paket. Keine Imports in Funktionen, ausser um zirkuläre Imports oder teure optionale Abhängigkeiten zu vermeiden (dann mit Kommentar).
- Doppelte Anführungszeichen für Strings (Ruff-Standard). f-Strings statt `%` oder `.format()`.
- Moderne Syntax ab Python 3.12: `list[str]`, `dict[str, int]`, `X | None`, `match` wo es lesbarer ist. Kein `typing.List`, `typing.Optional`, `typing.Union`.

## Typannotationen

- Jede Funktion und Methode hat vollständige Typannotationen für Parameter und Rückgabewert, auch `-> None`.
- Keine `Any`, ausser an Schnittstellen zu untypisierten Bibliotheken; dann mit Kommentar, warum.
- Für Daten mit fester Struktur `dataclasses.dataclass` oder `pydantic.BaseModel` statt loser `dict`s.

## Docstrings und Kommentare

- Docstrings auf Englisch im Google-Stil für alle öffentlichen Module, Klassen und Funktionen: eine Zusammenfassungszeile, dann Abschnitte `Args:`, `Returns:`, `Raises:` (nur wenn zutreffend).
- Private Hilfsfunktionen (`_name`) brauchen keinen Docstring, wenn Name und Signatur den Zweck erklären.
- Kommentare erklären das Warum, nicht das Was. Kein auskommentierter Code im Commit.

## Struktur

- Kein Code auf Modulebene ausser Imports, Konstanten und Definitionen. Ausführbarer Code steht in `main()` und wird mit `if __name__ == "__main__":` gestartet.
- Kein `print()` in Bibliotheks- oder Anwendungscode; benutze `logging` (`logger = logging.getLogger(__name__)`). `print()` ist nur in Skripten erlaubt, deren einziger Zweck die Konsolenausgabe ist, und in Notebooks.
- Eine Datei hat höchstens 500 Zeilen. Wird sie länger, teile sie nach Verantwortung auf (z. B. `io.py`, `features.py`, `model.py`).
- Funktionen haben höchstens etwa 50 Zeilen und einen klaren Zweck. Kein tiefes Verschachteln: früh mit `return` oder `raise` aussteigen.
- Dateipfade mit `pathlib.Path`, nie `os.path` oder String-Konkatenation. Konfiguration und Geheimnisse aus Umgebungsvariablen (`os.environ`) oder `.env` über `python-dotenv`, nie hartkodiert.
- Keine globalen veränderlichen Zustände. Keine `from modul import *`.
- Fehler gezielt behandeln: konkrete Exception-Klassen fangen, nie nacktes `except:` oder `except Exception: pass`.

## Tests

- Tests mit pytest in `tests/`, Datei `test_<modul>.py`, Funktion `test_<verhalten>()`. Kein `unittest`, keine Testklassen ohne Grund.
- Jede neue öffentliche Funktion bekommt mindestens einen Test für den Normalfall und einen für einen Randfall oder Fehlerfall.
- Tests sind deterministisch: kein Netz, keine echte Datenbank, keine Zufallszahlen ohne festen Seed. Externe Systeme mit Fixtures oder `monkeypatch` ersetzen.
- Bevor du einen bestehenden Test änderst oder löschst, frag mich. Ein roter Test wird durch eine Korrektur des Codes grün, nicht durch Anpassen der Erwartung, ausser die Erwartung war falsch.

## Data Science

- Notebooks (`.ipynb`) sind für Exploration. Wiederverwendbare Logik (Laden, Bereinigen, Features, Modell) gehört in Module im Paketordner des Projekts (z. B. `src/<paket>/` oder `<paket>/`), die das Notebook importiert.
- Pandas: keine Iteration über Zeilen mit `iterrows()`, wenn eine vektorisierte Operation möglich ist. `df.copy()` statt Änderungen an Slices (SettingWithCopyWarning vermeiden).
- Zufall mit festem Seed (`random_state=42` oder `numpy.random.default_rng(42)`), damit Ergebnisse reproduzierbar sind.
- Grosse Datendateien (`.csv`, `.parquet`, Modelle) nie ins Git-Repo; Pfade in eine `.gitignore` eintragen und in der README erklären, woher die Daten kommen.
