# Python: pyenv, uv und ruff

Drei Werkzeuge, drei klar getrennte Aufgaben. Wenn du das Zusammenspiel einmal verstanden hast, brauchst du für
ein neues Projekt keine zwei Minuten mehr.

| Werkzeug | Aufgabe | Wo installiert | Aktualisieren |
|---|---|---|---|
| **pyenv** | Python-Versionen (3.10, 3.12, ...) nebeneinander installieren und pro Ordner oder global auswählen | `~/.pyenv` (install.sh, Schritt 5) | `git -C "$(pyenv root)" pull` |
| **uv** | Pakete, Projekte (`pyproject.toml`, `.venv`, `uv.lock`) und globale CLI-Tools | `~/.local/bin/uv` (install.sh, Schritt 6) | `uv self update` (Teil von `update-all`) |
| **ruff** | Linter und Formatter in einem – ersetzt flake8, isort, black, pyupgrade | `~/.local/bin/ruff` über `uv tool install` (`packages/uv-tools.txt`) | `uv tool upgrade --all` (Teil von `update-all`) |

> 💡 **Für Einsteiger:** Eine *virtuelle Umgebung* (englisch *virtual environment*, kurz *venv*) ist ein Ordner
> pro Projekt, in dem genau die Pakete liegen, die dieses Projekt braucht. So kann Projekt A pandas 2.2 verwenden
> und Projekt B pandas 1.5, ohne dass sie sich in die Quere kommen. uv legt diesen Ordner als `.venv` im Projekt an
> und kümmert sich darum, dass er immer zum Inhalt der `pyproject.toml` passt. Du musst ihn nie „aktivieren", wenn
> du alles mit `uv run ...` startest.

## Spickzettel: Aufgabe -> Befehl

| Aufgabe | Befehl |
|---|---|
| Welche Python-Version ist gerade aktiv? | `pyenv version` |
| Alle installierten Versionen und Umgebungen | `pyenv versions` |
| Neue Python-Version installieren (kompiliert, dauert einige Minuten) | `pyenv install 3.13` |
| Globale Standardversion setzen | `pyenv global 3.12` |
| Neues Projekt anlegen | `uv init` |
| Paket hinzufügen | `uv add pandas` |
| Entwicklungs-Paket hinzufügen (Tests, Debugger) | `uv add --dev pytest ipdb` |
| Paket entfernen | `uv remove pandas` |
| Umgebung aus `pyproject.toml`/`uv.lock` herstellen (nach `git clone`) | `uv sync` |
| Skript in der Projektumgebung ausführen | `uv run python main.py` (kurz: `ur python main.py`) |
| Tests ausführen | `uv run pytest` (kurz: `pt`) |
| Abhängigkeitsbaum anzeigen | `uv tree` |
| Ein Paket auf die neueste Version heben | `uv lock --upgrade-package pandas` |
| Code formatieren und automatisch behebbare Fehler korrigieren | `rf` (= `ruff format . && ruff check --fix .`) |
| Nur prüfen, nichts ändern | `ruff check .` |
| Eine Regel erklären lassen | `ruff rule B006` |
| Globales CLI-Tool installieren | `uv tool install <name>` |
| Alle globalen Tools aktualisieren | `uv tool upgrade --all` |
| Alles auf einmal aktualisieren (apt, uv, Tools, Claude, Codex, oh-my-zsh) | `update-all` |

Die Kurzformen `py`, `venv`, `ur`, `rf` und `pt` stehen in `zsh/aliases`; `update-all` ist eine Funktion in `zsh/zshrc`.

## Wie die drei zusammenspielen

1. **pyenv** stellt die Interpreter bereit. install.sh installiert die neueste 3.12.x und setzt sie mit `pyenv global`
   als Standard. Der Prompt zeigt rechts, welche Version gerade aktiv ist: `[🐍 3.12.3]`.
2. Liegt in einem Ordner (oder einem Elternordner) eine Datei `.python-version`, gilt sie vor der globalen Version.
   pyenv löst dabei Präfixe auf: steht `3.12` in der Datei, nimmt pyenv die neueste installierte 3.12.x. Steht der
   Name einer pyenv-virtualenv darin (z. B. `DSPRO01`), wird diese Umgebung beim Betreten des Ordners automatisch
   aktiviert (`pyenv virtualenv-init` in `zsh/zshrc`).
3. **uv** liest dieselbe `.python-version` und baut daraus die `.venv` des Projekts – mit dem Python, das pyenv
   liefert. Findet uv keine passende Version auf dem System, lädt es selbst eine herunter (`uv python list` zeigt,
   was uv kennt). Das ist erlaubt, aber im Normalfall reicht pyenv.
4. **ruff** ist global installiert und funktioniert in jedem Ordner. Die Regeln liest es aus der `pyproject.toml`
   des Projekts (Abschnitt `[tool.ruff]`). In VS Code formatiert die Extension `charliermarsh.ruff` jede
   Python-Datei beim Speichern (eingestellt in `vscode/settings.json`).

## Neues Projekt Schritt für Schritt

Projekte gehören ins Linux-Home, nicht auf `/mnt/c` (siehe [docs/07-alltag.md](07-alltag.md)).

**1. Ordner anlegen und hineinwechseln**

```bash
mkdir -p ~/code/mein-projekt && cd ~/code/mein-projekt
```

**2. Projekt initialisieren**

```bash
uv init
```

uv legt an: `pyproject.toml` (Projektbeschreibung und Abhängigkeiten), `README.md`, `.python-version` (Inhalt `3.12`)
und `src/mein_projekt/__init__.py` mit einer kleinen `main()`-Funktion. Ausserdem wird ein Git-Repo mit passender
`.gitignore` angelegt – ausser du bist schon in einem Repo. Willst du nur eine minimale `pyproject.toml` ohne
Ordnerstruktur, nimm `uv init --bare`.

**3. Unsere Vorlage übernehmen (empfohlen)**

`templates/pyproject.toml` enthält die Ruff-Regeln, die pytest-Einstellungen und die dev-Gruppe. Kopiere die
`[tool.*]`-Abschnitte in deine `pyproject.toml` oder nimm die Vorlage ganz und passe nur `name` und `description` an:

```bash
cp ~/code/Elias-Martinelli/dotfiles/templates/pyproject.toml pyproject.toml
```

(Einsteiger: Pfad `~/code/dotfiles/templates/pyproject.toml`.) Danach einmal die Umgebung herstellen:

```bash
uv sync
```

**4. Pakete hinzufügen**

```bash
uv add pandas
```

```bash
uv add --dev pytest ipdb
```

Beim ersten `uv add` entstehen `.venv/` (die Umgebung, gehört nicht ins Git) und `uv.lock` (exakte Versionen aller
Pakete, gehört ins Git – damit auf jedem Rechner dieselben Versionen landen). `--dev` trägt Pakete in die Gruppe
`dev` unter `[dependency-groups]` ein: Werkzeuge fürs Entwickeln, die das fertige Programm nicht braucht.

**5. Code schreiben und ausführen**

Lege eine Datei `main.py` im Projektordner an:

```python
import pandas as pd


def main() -> None:
    df = pd.DataFrame({"stadt": ["Luzern", "Zug"], "einwohner": [82_000, 31_000]})
    print(df)


if __name__ == "__main__":
    main()
```

```bash
uv run python main.py
```

`uv run` sorgt vor jedem Start dafür, dass `.venv` zur `pyproject.toml` passt, und führt den Befehl darin aus.
Kein `source .venv/bin/activate` nötig – es funktioniert aber trotzdem, wenn du es gewohnt bist.

**6. Tests**

Lege `tests/test_main.py` an:

```python
from main import main


def test_main_laeuft_durch(capsys) -> None:
    main()
    ausgabe = capsys.readouterr().out
    assert "Luzern" in ausgabe
```

```bash
uv run pytest
```

Das klappt, weil unsere Vorlage `pythonpath = ["."]` unter `[tool.pytest.ini_options]` setzt – ohne diese Zeile
findet pytest `main.py` nicht (Fehler `No module named 'main'`). Hast du die Vorlage übersprungen, trage die Zeile
nach oder starte die Tests mit `uv run python -m pytest`.

**7. VS Code**

```bash
code .
```

Öffne die Befehlspalette mit `Ctrl+Shift+P`, tippe „Python: Select Interpreter" und wähle den Eintrag mit
`./.venv/bin/python` (VS Code findet `.venv`-Ordner im Arbeitsbereich automatisch und markiert ihn als empfohlen).
Ab jetzt zeigt Pylance die richtigen Typen, Tests erscheinen im Testing-Seitenpanel und Ruff formatiert beim
Speichern. Unsere `vscode/settings.json` setzt `python.terminal.activateEnvironment` auf `false`: Das VS-Code-Terminal
aktiviert die `.venv` nicht selbst, weil pyenv die Umgebung steuert – benutze im Terminal einfach `uv run`.

**8. Ins Git und auf GitHub**

`uv init` hat bereits `git init` ausgeführt. Der erste Commit und `gh repo create` stehen in
[docs/06-git-github.md](06-git-github.md).

## Bestehendes pyenv-Projekt weiterführen

Ältere Projekte (Kurse, HSLU-Module) benutzen pyenv-virtualenv statt uv. Das funktioniert weiterhin:

| Aufgabe | Befehl |
|---|---|
| Alle virtuellen Umgebungen anzeigen | `pyenv virtualenvs` |
| Neue Umgebung mit Python 3.12 anlegen (Präfix wird zur neuesten 3.12.x aufgelöst) | `pyenv virtualenv 3.12 mein-env` |
| Umgebung an den aktuellen Ordner binden (schreibt `.python-version`) | `pyenv local mein-env` |
| Umgebung von Hand aktivieren / deaktivieren | `pyenv activate mein-env` / `pyenv deactivate` |
| Pakete installieren (in der aktivierten Umgebung) | `python -m pip install -r requirements.txt` |
| Umgebung löschen | `pyenv virtualenv-delete mein-env` |

Nach `pyenv local mein-env` aktiviert sich die Umgebung beim Betreten des Ordners von selbst; rechts im Prompt steht
`[🐍 mein-env]`. In VS Code wählst du als Interpreter `~/.pyenv/versions/mein-env/bin/python`.

## Migration pyenv-virtualenv -> uv

Lohnt sich für jedes Projekt, an dem du noch aktiv arbeitest: `uv.lock` macht die Umgebung reproduzierbar, und
`uv sync` auf einem neuen Rechner dauert Sekunden.

1. In den Projektordner wechseln – die alte Umgebung ist damit aktiv. Installierte Pakete festhalten:

   ```bash
   python -m pip freeze > requirements.txt
   ```

   Kürze die Liste am besten auf die Pakete, die du wirklich selbst importierst (pandas, scikit-learn, ...). Die
   Unterabhängigkeiten löst uv selbst auf.

2. `.python-version` enthält noch den Namen der alten Umgebung, den uv nicht kennt. Auf die Versionsnummer setzen:

   ```bash
   echo 3.12 > .python-version
   ```

3. Falls noch keine `pyproject.toml` existiert: Vorlage kopieren (Schritt 3 oben) oder `uv init --bare`.

4. Abhängigkeiten übernehmen (legt `.venv` und `uv.lock` an):

   ```bash
   uv add -r requirements.txt
   ```

   ```bash
   uv add --dev pytest ipdb
   ```

5. Prüfen, ob alles läuft (`uv run python main.py`, `uv run pytest`), dann `requirements.txt` löschen und `.venv/` in
   die `.gitignore` aufnehmen, falls sie fehlt.

6. Alte Umgebung entfernen:

   ```bash
   pyenv virtualenv-delete altes-env
   ```

## Jupyter in VS Code

Notebooks laufen in VS Code über die Extension `ms-toolsai.jupyter` (in `packages/vscode-extensions.txt`). Damit ein
Notebook die Pakete deines Projekts sieht, braucht die `.venv` den Kernel:

```bash
uv add --dev ipykernel
```

Dann in VS Code: Befehlspalette -> „Create: New Jupyter Notebook" (oder eine `.ipynb` öffnen) -> oben rechts
„Select Kernel" -> „Python Environments..." -> `.venv/bin/python` wählen. Wenn du Pakete aus dem Notebook heraus
zum Projekt hinzufügen willst, geht das mit `!uv add paket` in einer Zelle; dafür muss `uv` in der Umgebung
bekannt sein (`uv add --dev uv`).

Jupyter im Browser statt in VS Code:

```bash
uv run --with jupyter jupyter lab
```

Für alte pyenv-virtualenv-Projekte installierst du `ipykernel` mit `python -m pip install ipykernel` und wählst
den Interpreter der Umgebung als Kernel.

> 💡 **Für Einsteiger:** Notebooks sind ideal zum Ausprobieren und für Analysen mit Grafiken. Sobald etwas
> mehrfach gebraucht wird, verschiebe den Code in eine `.py`-Datei und importiere ihn im Notebook – so lässt er
> sich testen und mit Ruff prüfen. Genau das steht auch als Regel in `claude/CLAUDE.md`.

## Debugging

**Im Terminal mit ipdb.** `zsh/zshrc` setzt `PYTHONBREAKPOINT=ipdb.set_trace`. Schreib an die verdächtige Stelle

```python
breakpoint()
```

und starte das Skript normal mit `uv run python main.py`. Python hält dort an und öffnet ipdb (farbig, mit
Tab-Vervollständigung). Voraussetzung: `ipdb` ist im Projekt installiert (`uv add --dev ipdb`; in der Vorlage schon
enthalten). Fehlt es, meldet Python eine `RuntimeWarning` und überspringt den Haltepunkt – dann entweder ipdb
installieren oder für einen Lauf den Standard-Debugger nehmen: `PYTHONBREAKPOINT=pdb.set_trace uv run python main.py`.

Die wichtigsten Befehle in ipdb/pdb:

| Taste | Bedeutung |
|---|---|
| `n` | nächste Zeile (*next*) |
| `s` | in den Funktionsaufruf hineingehen (*step*) |
| `c` | weiterlaufen bis zum nächsten Haltepunkt (*continue*) |
| `l` / `ll` | Code um die aktuelle Zeile / die ganze Funktion anzeigen |
| `p ausdruck` / `pp ausdruck` | Wert ausgeben (hübsch formatiert mit `pp`) |
| `w` | Aufrufstapel anzeigen (*where*) |
| `q` | Debugger und Programm beenden |

**In VS Code.** Haltepunkt setzen mit `F9` (oder Klick links neben die Zeilennummer), dann `F5` oder über den Pfeil
neben dem Start-Knopf „Python Debugger: Debug Python File". Die Ansicht „Run and Debug" öffnest du mit
`Ctrl+Shift+D`. In der Werkzeugleiste: Weiter `F5`, Schritt über `F10`, Schritt hinein `F11`. Unten in der
„Debug Console" kannst du Ausdrücke im angehaltenen Zustand auswerten. Die Extension `ms-python.debugpy` ist in
unserer Extension-Liste enthalten. Tests debuggst du im Testing-Seitenpanel (Becherglas-Symbol) mit Rechtsklick auf
einen Test -> „Debug Test".

## Ruff verstehen

Ruff macht zwei Dinge: `ruff format` bringt den Code in eine einheitliche Form (Einrückung, Anführungszeichen,
Zeilenlänge), `ruff check` findet Fehler und Unsauberkeiten. Unsere Vorlage `templates/pyproject.toml` aktiviert
diese Regelgruppen:

| Gruppe | Herkunft | Findet zum Beispiel |
|---|---|---|
| `E` | pycodestyle | Stilfehler wie zu lange Zeilen (`E501`) |
| `F` | Pyflakes | unbenutzte Imports (`F401`), undefinierte Namen |
| `I` | isort | unsortierte Imports (`I001`) – wird beim Speichern automatisch behoben |
| `UP` | pyupgrade | veraltete Syntax, z. B. `List[str]` statt `list[str]` |
| `B` | flake8-bugbear | klassische Fallen wie veränderliche Default-Argumente (`B006`) |
| `SIM` | flake8-simplify | umständliche Konstrukte, die sich vereinfachen lassen |

Weitere Einstellungen: `line-length = 100` und `target-version = "py312"`. Was eine Regel genau bedeutet:

```bash
ruff rule B006
```

Im Alltag brauchst du meist nur den Alias `rf` (formatieren + automatisch fixen) oder gar nichts, weil VS Code beim
Speichern formatiert und Imports sortiert (`editor.codeActionsOnSave` in `vscode/settings.json`). Vor einem Commit
lohnt sich ein reiner Prüflauf:

```bash
ruff check .
```

Eine einzelne Zeile von einer Regel ausnehmen: `# noqa: E501` ans Zeilenende. Eine Regel projektweit abschalten:
in `[tool.ruff.lint]` unter `ignore` eintragen. Claude Code kennt diese Regeln ebenfalls – `claude/rules/python.md`
verlangt ruff-konformen Code.

## pre-commit

`pre-commit` (aus `packages/uv-tools.txt`) führt Prüfungen automatisch vor jedem `git commit` aus, damit kein
unformatierter Code ins Repo kommt. Lege im Projekt eine `.pre-commit-config.yaml` an:

```yaml
repos:
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.16.8
    hooks:
      - id: ruff-check
        args: [--fix]
      - id: ruff-format
  - repo: https://github.com/astral-sh/uv-pre-commit
    rev: 0.12.18
    hooks:
      - id: uv-lock
```

`ruff-check` muss vor `ruff-format` stehen, wenn `--fix` gesetzt ist. Der Hook `uv-lock` hält `uv.lock` aktuell,
falls du `pyproject.toml` von Hand geändert hast. Dann einmalig im Repo aktivieren:

```bash
pre-commit install
```

Alle Dateien einmal durchprüfen (sinnvoll direkt nach dem Einrichten):

```bash
pre-commit run --all-files
```

Hook-Versionen später anheben:

```bash
pre-commit autoupdate
```

## Aufräumen alter Versionen

```bash
pyenv versions
```

zeigt alles, was in `~/.pyenv/versions` liegt – auch die Umgebungen aus alten Kursen. Nicht mehr gebrauchte
Umgebungen und Versionen löschen (pyenv fragt nach; `-f` unterdrückt die Rückfrage):

```bash
pyenv virtualenv-delete altes-env
```

```bash
pyenv uninstall 3.10.6
```

Eine Version darf erst weg, wenn keine Umgebung mehr darauf aufbaut (`pyenv virtualenvs` zeigt die Zuordnung).
uv hält einen globalen Paket-Cache, den du gefahrlos verkleinern kannst:

```bash
uv cache prune
```

`uv cache clean` löscht ihn komplett, `uv cache dir` zeigt, wo er liegt. Eine `.venv` kannst du jederzeit löschen –
`uv sync` baut sie aus `uv.lock` neu. Globale Tools verwaltest du mit `uv tool list` und `uv tool uninstall <name>`.

## GPU (NVIDIA) in WSL

Der Windows-Treiber stellt die GPU auch in WSL bereit; ein Treiber in Ubuntu ist nicht nötig. Prüfen:

```bash
nvidia-smi
```

Für PyTorch mit CUDA brauchst du kein separates CUDA-Toolkit – die PyTorch-Pakete bringen die nötigen Bibliotheken
mit. Welchen Paket-Index du brauchst, sagt dir der Konfigurator auf <https://pytorch.org/get-started/locally/>
(Linux, pip, deine CUDA-Version). Mit uv bindest du diesen Index gezielt für torch ein, zum Beispiel für die
CPU-Variante:

```bash
uv add torch --index pytorch=https://download.pytorch.org/whl/cpu
```

Für CUDA ersetzt du `cpu` durch die Variante von pytorch.org (etwa `cu128`). uv trägt den Index dann unter
`[[tool.uv.index]]` und `[tool.uv.sources]` in die `pyproject.toml` ein; Details und weitere Varianten stehen in der
uv-Anleitung <https://docs.astral.sh/uv/guides/integration/pytorch/>. Ausserhalb eines Projekts kann uv den Index
auch selbst anhand des Treibers wählen: `uv pip install torch --torch-backend=auto`. Test:

```bash
uv run python -c "import torch; print(torch.cuda.is_available())"
```
