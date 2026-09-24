# mein-projekt

<!--
Vorlage für ein Projekt-CLAUDE.md. Verwendung: nach <projekt>/CLAUDE.md kopieren und die
Beispielinhalte durch die echten ersetzen (Projektname, Zweck, Ordner). Kurz halten: unter 60 Zeilen.
Diese HTML-Kommentare werden von Claude Code entfernt, bevor der Inhalt in den Kontext geladen wird.
Alternative: `/init` in Claude Code erzeugt einen Vorschlag aus dem vorhandenen Code.
-->

## Zweck

Analysiert Verkaufsdaten aus CSV-Dateien und erzeugt daraus Kennzahlen und Diagramme für einen Wochenbericht.
Zielgruppe: ich selbst und mein Studienteam. Kein Produktivbetrieb, aber der Code soll reproduzierbar sein.

## Befehle

- Umgebung einrichten: `uv sync`
- Programm starten: `uv run python main.py`
- Tests: `uv run pytest`
- Formatieren und Linten: `ruff format . && ruff check --fix .`
- Notebook-Kernel bereitstellen: `uv add --dev ipykernel`, dann in VS Code den Kernel `.venv` wählen

## Struktur

- `main.py` – Einstiegspunkt, ruft `main()` auf
- `mein_projekt/` – Anwendungscode (Import als `mein_projekt`, liegt im Projektordner)
  - `io.py` – Laden und Speichern von Daten
  - `features.py` – Bereinigung und Feature-Berechnung
  - `report.py` – Kennzahlen und Diagramme
- `tests/` – pytest-Tests, eine Datei pro Modul (`test_features.py`); `pythonpath = ["."]` in `pyproject.toml` macht `mein_projekt` importierbar
- `notebooks/` – Exploration; importiert Funktionen aus `mein_projekt/`, enthält keine eigene Logik
- `data/raw/` – Rohdaten (gitignored), `data/processed/` – erzeugte Daten (gitignored)
- `pyproject.toml` – Abhängigkeiten, Ruff- und pytest-Konfiguration

## Konventionen

- Python 3.12, Verwaltung nur mit uv (`uv add`, `uv run`). Kein `pip install`.
- Ruff-Regeln aus `pyproject.toml` sind verbindlich; vor jedem Commit `ruff check .` und `uv run pytest` ausführen.
- Type Hints überall, Docstrings im Google-Stil, `logging` statt `print`.
- Commit-Messages auf Englisch mit Präfix `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`.
- Neue Abhängigkeiten nur nach Rückfrage hinzufügen.

## Nicht anfassen

- `data/raw/` – Rohdaten sind die einzige Quelle der Wahrheit; nie verändern oder löschen.
- `uv.lock` – nur über `uv add` / `uv lock` ändern, nie von Hand.
- `.env` – enthält Zugangsdaten; nicht lesen, nicht committen, nicht in Logs ausgeben.
- `notebooks/archiv/` – alte Analysen, nur zum Nachlesen.
