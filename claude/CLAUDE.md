# Persönliche Anweisungen für Claude Code (gelten in allen Projekten)

<!-- Wenn du nicht Elias bist: Passe den Abschnitt «Über mich» an dich an – im Repo unter claude/CLAUDE.md
     (danach committen), nicht in ~/.claude/CLAUDE.md, denn das ist nur ein Symlink auf diese Datei. -->

## Über mich

- Ich bin Elias Martinelli, Data-Science-Student an der HSLU. Schwerpunkt Python (Datenanalyse, ML, kleine Web-APIs).
- Ich arbeite unter Windows 11 mit WSL 2 (Ubuntu 24.04). Alle Projekte liegen im Linux-Home unter `~/code/`.
- Antworte mir auf Deutsch in Schweizer Rechtschreibung: kein Eszett, immer «ss» (muss, grösser, ausserdem).
- Code, Kommentare, Docstrings, Variablennamen und Commit-Messages schreibst du auf Englisch.
- Erkläre kurz und konkret. Keine langen Einleitungen, keine Wiederholung meiner Frage.

## Arbeitsweise

- Erst verstehen, dann handeln: Lies die relevanten Dateien, bevor du Code änderst. Rate nicht, was eine Funktion tut.
- Bei Aufgaben mit mehr als einer betroffenen Datei: zuerst einen Plan in 3 bis 7 Punkten, dann umsetzen.
- Arbeite in kleinen, überprüfbaren Schritten. Nach jedem Schritt kurz sagen, was geändert wurde.
- Frage nach, bevor du etwas Destruktives tust: Dateien löschen, `git reset --hard`, `git push --force`, `rm -rf`, Datenbanken leeren, Branches löschen.
- Führe nach Codeänderungen die Tests aus (`uv run pytest`) und `ruff check .`, bevor du die Aufgabe als erledigt meldest. Zeige das Ergebnis.
- Wenn etwas nicht funktioniert oder unklar ist: sag es direkt, statt eine Lösung zu erfinden. Nenne, was du geprüft hast.
- Erfinde keine Bibliotheken, Funktionen, Flags oder URLs. Wenn du unsicher bist, prüfe es (Doku lesen, `--help` ausführen).

## Python-Konventionen

- Paketverwaltung ausschliesslich mit uv: `uv add <paket>`, `uv add --dev <paket>`, `uv sync`, `uv run <befehl>`. Nie `pip install`, nie `python -m venv`.
- Skripte und Tests immer über `uv run` starten (`uv run python main.py`, `uv run pytest`), damit die richtige `.venv` benutzt wird.
- Formatieren und Linten mit Ruff: `ruff format .` und `ruff check --fix .`. Regeln stehen in `pyproject.toml` unter `[tool.ruff]` (Standard: E, F, I, UP, B, SIM; Zeilenlänge 100).
- Type Hints für alle Funktionssignaturen (Parameter und Rückgabewert). Moderne Syntax: `list[str]`, `dict[str, int]`, `X | None`.
- Pfade mit `pathlib.Path`, nie `os.path`. Strings mit f-Strings, nie `%` oder `.format()`.
- Tests mit pytest im Ordner `tests/`, Dateinamen `test_*.py`. Kein `unittest`.
- Keine Notebook-Logik in Produktionscode: Code aus Jupyter-Notebooks in Funktionen eines Moduls auslagern (Paketordner des Projekts, z. B. `src/<paket>/` oder `<paket>/`), das Notebook importiert sie.
- Vorhandene `pyproject.toml`, `.python-version` und `uv.lock` respektieren. Python-Version nicht eigenmächtig ändern.
- Detailregeln für `.py`-Dateien stehen in `~/.claude/rules/python.md` (wird automatisch geladen, wenn du Python-Dateien bearbeitest).

## Git

- Kleine, thematisch getrennte Commits. Ein Commit erledigt eine Sache.
- Commit-Messages auf Englisch mit Conventional-Commits-Präfix: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`. Betreffzeile im Imperativ, maximal 72 Zeichen.
- Vor einem Commit: `git status` und `git diff` ansehen und mir zusammenfassen, was committet wird.
- Nur committen, wenn ich es ausdrücklich verlange. Nie `git push --force` auf `main` oder `master`.
- Keine Dateien mit Geheimnissen committen (`.env`, Tokens, Schlüssel, `credentials*.json`). Wenn du eines siehst, warne mich.
- Standard-Branch für neue Repos heisst `main`. Pull Requests erstelle ich mit `gh pr create`.

## Meine Umgebung

- Shell: zsh mit oh-my-zsh. Eigene Aliasse in `~/.aliases`, Funktionen in `~/.zshrc`.
- Python: pyenv (globale Version 3.12), uv für Projekte und Tools, ruff global via `uv tool install ruff`.
- Debugger: `breakpoint()` startet ipdb (`PYTHONBREAKPOINT=ipdb.set_trace`).
- Node: nvm mit der aktuellen LTS-Version (nur wenn ein Projekt es braucht).
- Docker: Docker Desktop auf Windows mit WSL-Integration. `docker` funktioniert nur, wenn Docker Desktop läuft.
- Editor: VS Code mit WSL-Remote. Aus dem Terminal öffnen mit `code .`.
- GitHub: Für Repo-Aktionen `gh` bevorzugen (`gh auth status` zeigt das angemeldete Konto).
- Meine Dotfiles: Der Shell-Alias `dotfiles` wechselt ins Repo (bei mir `~/code/Elias-Martinelli/dotfiles`). `~/.claude/settings.json`, `~/.claude/CLAUDE.md` und `~/.claude/rules/` sind Symlinks in dieses Repo; Änderungen daran also dort committen.
- Zweitmeinung: ChatGPT/Codex ist ebenfalls installiert. Wenn ich dich bitte, eine Codex-Lösung zu bewerten, bewerte sachlich, nicht konkurrierend.
