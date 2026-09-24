# dotfiles – Meine Entwicklungsumgebung (WSL 2 + Ubuntu + Python + Claude Code)

Dieses Repository enthält alles, was ich brauche, um auf einem frischen Windows-Rechner in rund 20 Minuten meine komplette Entwicklungsumgebung wieder aufzubauen: WSL 2 mit Ubuntu 24.04, zsh, Python (pyenv + uv + ruff), Git/GitHub, VS Code, Docker Desktop, Claude Code als primären KI-Assistenten und ChatGPT/Codex als Ergänzung. Die Anleitungen sind so geschrieben, dass auch Einsteiger ohne Terminal-Erfahrung (zum Beispiel mein Vater) dieselbe Umgebung Schritt für Schritt einrichten können.

> 💡 **Für Einsteiger:** Ein „Dotfiles-Repo" ist eine Sammlung von Konfigurationsdateien (sie beginnen unter Linux meist mit einem Punkt, z. B. `.zshrc`) plus Skripten, die diese Dateien an die richtige Stelle legen und die nötigen Programme installieren. Du musst nichts davon auswendig kennen – fang einfach bei [docs/01-windows-vorbereiten.md](docs/01-windows-vorbereiten.md) an.

## Was du bekommst

| Komponente | Werkzeug | Warum |
|---|---|---|
| Linux unter Windows | WSL 2 mit Ubuntu 24.04 LTS, Windows Terminal, PowerShell 7 | Echtes Linux ohne Dual-Boot; alle Werkzeuge laufen wie auf einem Server, Windows bleibt für Office und Co. |
| Shell | zsh + oh-my-zsh (Theme `robbyrussell`), zsh-autosuggestions, zsh-syntax-highlighting, history-substring-search | Schnelleres Arbeiten im Terminal: Vorschläge aus der History, farbige Befehle, Git-Kürzel |
| Python-Versionen | pyenv (mit pyenv-virtualenv), Standard Python 3.12 | Mehrere Python-Versionen parallel, ohne das System-Python anzutasten |
| Pakete und Projekte | uv | Ersetzt pip, venv und pipx; sehr schnell; `uv run` startet alles in der richtigen Umgebung |
| Code-Qualität | ruff, pre-commit (via `uv tool install`) | Linter und Formatter in einem Werkzeug; formatiert in VS Code beim Speichern |
| Node.js | nvm + aktuelle LTS-Version | Für npm-basierte Werkzeuge und Web-Projekte, ohne sudo |
| Git und GitHub | git, GitHub CLI (`gh`), SSH-Key, eigene Aliasse | Login per Browser, Credential-Helper, Pull Requests und Repos direkt aus dem Terminal |
| Editor | VS Code (Windows) mit WSL-Remote, Extensions aus `packages/vscode-extensions.txt`, Machine-Settings | Editor läuft auf Windows, Code und Werkzeuge in Linux; Ruff, Pylance, Jupyter, Docker vorkonfiguriert |
| KI-Assistent (primär) | Claude Code: CLI `claude`, VS-Code-Extension, Claude-Desktop-App | Programmieren, Erklären, Refactoring und Tests direkt im Projekt; Einstellungen und `CLAUDE.md` liegen im Repo |
| KI-Assistent (sekundär) | ChatGPT-App (Windows), Codex CLI `codex`, VS-Code-Extension `openai.chatgpt` | Zweitmeinung, Recherche, dieselbe Aufgabe mit zwei Assistenten vergleichen |
| Container | Docker Desktop (Windows) mit WSL-Integration | `docker` und `docker compose` in Ubuntu, ohne eigenen Docker-Daemon in WSL |
| Terminal-Werkzeuge | ripgrep, fd, bat, jq, tree, htop, tmux, direnv | Schneller suchen, hübscher anzeigen, projektbezogene Umgebungsvariablen |
| Konfiguration | Symlinks aus diesem Repo für zsh, Git, SSH, VS Code, Claude Code, Codex sowie `/etc/wsl.conf` | Eine Quelle der Wahrheit: eine Änderung im Repo gilt nach `git pull` auf jeder Maschine |

## Schnellstart

Drei Wege, je nachdem, wer du bist und was du vorhast. Alle Wege enden beim selben Installer `install.sh`. Er ist **idempotent**: Du kannst ihn jederzeit erneut ausführen, bereits Erledigtes wird übersprungen und nichts geht verloren.

### Weg A – Neuer Rechner (für mich)

**1. Windows vorbereiten.** Das Repo auf GitHub öffnen, über „Code → Download ZIP" herunterladen und entpacken (falls das Repo öffentlich ist, geht auch der Einzeiler aus dem Kopfkommentar von `windows/setup.ps1`). Dann PowerShell **als Administrator** öffnen, in den entpackten Unterordner `windows` wechseln und ausführen:

```powershell
Set-ExecutionPolicy -Scope Process Bypass; .\setup.ps1
```

Das Skript installiert WSL 2 mit Ubuntu 24.04, Windows Terminal, VS Code, PowerShell 7, optional Docker Desktop, die Claude-Desktop-App und ChatGPT und legt eine `.wslconfig` an. Bei der ersten WSL-Installation ist ein Neustart nötig. Danach Ubuntu aus dem Startmenü öffnen und Benutzername plus Passwort anlegen.

**2. In Ubuntu: GitHub CLI installieren und anmelden.** Ein frisches Ubuntu hat `gh` noch nicht. Das Ubuntu-Paket reicht für den Login; `install.sh` richtet in Schritt 3 zusätzlich das offizielle GitHub-Apt-Repo ein, von dem `gh` bei künftigen Updates (`update-all`) kommt.

```bash
sudo apt-get update && sudo apt-get install -y git gh
```

```bash
gh auth login
```

Auswahl: GitHub.com → HTTPS → Login with a web browser. Den angezeigten Code im Browser auf Windows eingeben.

**3. Repo klonen und Installer starten.**

```bash
gh repo clone Elias-Martinelli/dotfiles ~/code/Elias-Martinelli/dotfiles
```

```bash
cd ~/code/Elias-Martinelli/dotfiles && ./install.sh
```

Der Installer fragt zu Beginn nach Git-Name und E-Mail, nach Codex CLI und nach `wsl.conf` und läuft dann ohne weitere Rückfragen durch. Details zu jeder Frage stehen in [docs/02-installation.md](docs/02-installation.md).

### Weg B – Einsteiger (z. B. mein Vater)

Folge zuerst [docs/01-windows-vorbereiten.md](docs/01-windows-vorbereiten.md) (WSL, Ubuntu, Terminal, VS Code – Schritt für Schritt mit Erklärungen) und danach [docs/02-installation.md](docs/02-installation.md). Der Kern der Installation ist ein einziger Befehl im Ubuntu-Terminal:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Elias-Martinelli/dotfiles/main/bootstrap.sh)
```

`bootstrap.sh` installiert `git` und `curl`, klont das Repo nach `~/code/dotfiles` und startet `install.sh`.

> ⚠️ Der Einzeiler funktioniert nur, wenn das Repo auf GitHub **öffentlich** ist. Solange es privat ist, nimm Weg A: `gh auth login`, dann `gh repo clone`.

> 💡 **Für Einsteiger:** Du kannst dem Installer beim Arbeiten zuschauen, er sagt bei jedem Schritt, was er gerade tut. Wenn etwas abbricht (zum Beispiel weil das WLAN weg war), führst du denselben Befehl einfach noch einmal aus. Alles, was schon erledigt ist, wird übersprungen.

### Weg C – Bestehende Maschine nachziehen

Wenn das Repo schon auf dem Rechner liegt und du nur Änderungen übernehmen willst, reicht der Alias aus `zsh/aliases`:

```bash
dotfiles-update
```

Er macht im Repo-Ordner `git pull --ff-only` und setzt anschliessend mit `./install.sh --links-only -y` alle Symlinks neu. Von Hand ist das dasselbe wie:

```bash
cd ~/code/Elias-Martinelli/dotfiles && git pull --ff-only && ./install.sh --links-only
```

Sollen auch neue Pakete oder Werkzeuge installiert werden (zum Beispiel eine neue Zeile in `packages/apt.txt`), lässt du die Flags weg und startest `./install.sh` komplett. Er überspringt alles, was schon da ist.

## Was install.sh macht

`install.sh` ist ein Bash-Skript für Ubuntu 22.04/24.04 unter WSL 2. Unter anderen Distributionen bricht es mit einer klaren Meldung ab; ohne WSL läuft es mit einer Warnung weiter. Es darf **nicht** als root gestartet werden. `sudo` wird nur für apt, die Locale und `/etc/wsl.conf` gebraucht und einmal nach den Fragen abgefragt. Jeder Schritt prüft zuerst, ob er schon erledigt ist, und meldet dann „übersprungen (bereits vorhanden)".

1. **Vorprüfungen** – Ubuntu/Debian, nicht root, WSL-Erkennung, `curl` und `git` vorhanden (sonst Hinweis auf `bootstrap.sh`).
2. **Fragen stellen** – Git-Name und E-Mail (Vorgabe: bestehende Werte aus `git config --global`), Codex CLI installieren? (Vorgabe: Ja), `/etc/wsl.conf` schreiben? Alle Fragen kommen **vor** den langen Installationen; mit `-y` werden die Vorgaben genommen.
3. **apt** – offizielles GitHub-CLI-Apt-Repo einrichten (falls es fehlt), `apt-get update`, dann alle Pakete aus `packages/apt.txt` installieren (Basis-Werkzeuge, `gh`, alle Build-Abhängigkeiten für pyenv) und die Locale `en_US.UTF-8` erzeugen.
4. **zsh** – oh-my-zsh unbeaufsichtigt installieren, Plugins `zsh-autosuggestions` und `zsh-syntax-highlighting` klonen, Login-Shell auf zsh umstellen (`chsh` fragt dabei nach deinem Passwort).
5. **Python** – pyenv (inklusive pyenv-virtualenv) installieren, Python `3.12` kompilieren (dauert einige Minuten) und als `pyenv global` setzen.
6. **uv** – uv installieren (ohne PATH-Änderung, das übernimmt `zsh/zshrc`) und die Werkzeuge aus `packages/uv-tools.txt` per `uv tool install` einrichten (ruff, pre-commit).
7. **Node** – nvm installieren (ohne Eintrag in die zshrc), aktuelle LTS-Version installieren und als Standard setzen.
8. **KI-Werkzeuge** – Claude Code nativ nach `~/.local/bin/claude` installieren; optional Codex CLI (offizielles Installer-Skript, Fallback `npm install -g @openai/codex`). Beides ohne sudo.
9. **VS Code** – nur wenn `code` in WSL erreichbar ist: alle Extensions aus `packages/vscode-extensions.txt` installieren. Sonst Hinweis, VS Code auf Windows zu installieren, einmal `code .` aus Ubuntu zu starten und `./install.sh --skip-apt --skip-python --skip-node --skip-ai` erneut auszuführen.
10. **Verknüpfen** – Symlinks von `~` ins Repo setzen (Tabelle unten). Bestehende echte Dateien wandern in den Backup-Ordner, Symlinks aufs Repo werden übersprungen, fremde oder tote Symlinks ersetzt.
11. **wsl.conf** – nur unter WSL und nur mit Zustimmung: `wsl/wsl.conf` mit deinem Benutzernamen nach `/etc/wsl.conf` (systemd an, Standardbenutzer gesetzt). Danach in PowerShell `wsl --shutdown` ausführen und WSL neu öffnen.
12. **Zusammenfassung** – was installiert und was übersprungen wurde, Backup-Ordner, nächste Schritte (`exec zsh`, `gh auth login`, `claude`, `codex`, `code .`, `claude doctor`).

### Verknüpfungen (Schritt 10)

| Im Repo | Ziel | Art |
|---|---|---|
| `zsh/zshrc` | `~/.zshrc` | Symlink |
| `zsh/zprofile` | `~/.zprofile` | Symlink |
| `zsh/aliases` | `~/.aliases` | Symlink |
| `zsh/zshrc.local.example` | `~/.zshrc.local` | Kopie, nur wenn noch nicht vorhanden |
| `git/gitconfig` | `~/.gitconfig` | Symlink |
| `git/gitconfig.local.example` | `~/.gitconfig.local` | Kopie mit Name und E-Mail, wird nie überschrieben |
| `ssh/config` | `~/.ssh/config` | Symlink (`~/.ssh` bekommt `chmod 700`) |
| `vscode/settings.json` | `~/.vscode-server/data/Machine/settings.json` | Symlink |
| `claude/settings.json` | `~/.claude/settings.json` | Symlink |
| `claude/CLAUDE.md` | `~/.claude/CLAUDE.md` | Symlink |
| `claude/rules/` | `~/.claude/rules` | Symlink auf den Ordner |
| `codex/config.toml` | `~/.codex/config.toml` | Kopie, nur wenn Codex gewünscht und noch keine Datei vorhanden (Codex schreibt rechnerspezifische Daten hinein) |
| `wsl/wsl.conf` | `/etc/wsl.conf` | Kopie mit sudo (Schritt 11) |

### Flags und Umgebungsvariablen

Alle Flags lassen sich kombinieren.

| Flag | Wirkung |
|---|---|
| `-y`, `--yes` | Keine Rückfragen, Standardantworten verwenden (Git-Name/E-Mail aus `GIT_NAME`/`GIT_EMAIL` oder aus der bestehenden Git-Konfiguration; Codex: Ja) |
| `--links-only` | Nur Symlinks und Kopien setzen (Schritt 10), nichts installieren |
| `--skip-apt` | Schritt 3 (apt-Pakete, GitHub-CLI-Repo) überspringen |
| `--skip-python` | Schritt 5 (pyenv, Python 3.12) überspringen |
| `--skip-node` | Schritt 7 (nvm, Node LTS) überspringen |
| `--skip-ai` | Schritt 8 (Claude Code, Codex CLI) überspringen |
| `--skip-vscode` | Schritt 9 (VS-Code-Extensions) überspringen |
| `--skip-wslconf` | Schritt 11 (`/etc/wsl.conf`) überspringen |
| `--no-codex` | Codex CLI nicht installieren und nicht danach fragen; `~/.codex/config.toml` wird nur angelegt, wenn Codex bereits installiert ist (Standard: fragen, Vorgabe Ja) |
| `--dry-run` | Alle Aktionen nur anzeigen (`[dry-run] befehl ...`), nichts ausführen; braucht weder sudo noch Internet |
| `-h`, `--help` | Hilfe anzeigen (deutsch) |

| Umgebungsvariable | Standard | Wirkung |
|---|---|---|
| `GIT_NAME` | bestehender `git config --global user.name` | Name für `~/.gitconfig.local`, vor allem zusammen mit `-y` |
| `GIT_EMAIL` | bestehender `git config --global user.email` | E-Mail für `~/.gitconfig.local`, vor allem zusammen mit `-y` |
| `PYTHON_VERSION` | `3.12` | Python-Version für `pyenv install` und `pyenv global`; ein Präfix wie `3.12` nimmt die neueste 3.12.x |
| `DOTFILES_BACKUP_DIR` | `~/.dotfiles-backup/<YYYYmmdd-HHMMSS>` | Ordner, in den bestehende Dateien vor dem Verlinken verschoben werden |

Beispiele:

```bash
./install.sh --dry-run -y
```

```bash
GIT_NAME="Max Muster" GIT_EMAIL="max@example.com" ./install.sh -y --no-codex
```

```bash
PYTHON_VERSION=3.13 ./install.sh --skip-node --skip-ai
```

## Struktur des Repos

```
dotfiles/
├── README.md                       # Diese Datei: Einstieg, Schnellstart, Struktur, Pflege
├── .gitignore                      # Hält lokale Dateien (*.local, .env, Backups) aus dem Repo
├── .editorconfig                   # Einheitliche Einrückung und Zeilenenden für alle Editoren
├── bootstrap.sh                    # Einzeiler-Einstieg für frisches WSL: git/curl sicherstellen, Repo klonen, install.sh starten
├── install.sh                      # Haupt-Installer für WSL/Ubuntu (bash), idempotent, 12 Schritte
├── packages/
│   ├── apt.txt                     # apt-Pakete, ein Paket pro Zeile, #-Kommentare erlaubt
│   ├── uv-tools.txt                # Globale CLI-Tools via uv tool install (ruff, pre-commit)
│   └── vscode-extensions.txt       # Extension-IDs für die WSL-Seite, ein Eintrag pro Zeile, #-Kommentare
├── zsh/
│   ├── zshrc                       # Hauptkonfiguration: oh-my-zsh, Plugins, pyenv, nvm, PATH, update-all
│   ├── zprofile                    # Nur PATH-Grundlagen für Login-Shells (pyenv, ~/.local/bin)
│   ├── aliases                     # Eigene Aliasse (Python, Git, Dotfiles, KI), jeder kommentiert
│   └── zshrc.local.example         # Vorlage für Maschinenspezifisches (-> ~/.zshrc.local, nicht im Repo)
├── git/
│   ├── gitconfig                   # Farben, Aliasse, Defaults; ohne [user]; include ~/.gitconfig.local
│   └── gitconfig.local.example     # Vorlage mit Name/E-Mail (-> ~/.gitconfig.local, gitignored)
├── ssh/
│   └── config                      # GitHub über ~/.ssh/id_ed25519, Keep-alive; Linux-tauglich
├── vscode/
│   └── settings.json               # Machine-Settings für WSL-Remote (-> ~/.vscode-server/data/Machine/settings.json)
├── claude/
│   ├── settings.json               # Claude-Code-Einstellungen: Permissions, Updates (-> ~/.claude/settings.json)
│   ├── CLAUDE.md                   # Persönliche Anweisungen für alle Projekte (-> ~/.claude/CLAUDE.md)
│   └── rules/
│       └── python.md               # Regeln für Python-Dateien, gilt für **/*.py (-> ~/.claude/rules/python.md)
├── codex/
│   └── config.toml                 # Vorlage für die Codex-CLI-Konfiguration (Kopie -> ~/.codex/config.toml)
├── templates/
│   ├── pyproject.toml              # Vorlage für neue Python-Projekte (uv + ruff + pytest)
│   └── project-CLAUDE.md           # Vorlage für ein Projekt-CLAUDE.md
├── wsl/
│   └── wsl.conf                    # systemd an, Standardbenutzer __USER__ (Installer ersetzt) -> /etc/wsl.conf
├── windows/
│   ├── setup.ps1                   # PowerShell (Admin): WSL+Ubuntu, Terminal, VS Code, optional Docker, Claude, ChatGPT
│   └── wslconfig.example           # Vorlage für C:\Users\<Name>\.wslconfig (RAM/CPU für WSL) mit Erklärungen
└── docs/
    ├── 01-windows-vorbereiten.md   # Einsteiger-Guide: WSL installieren, Terminal, VS Code, erstes Login
    ├── 02-installation.md          # dotfiles installieren (Weg A/B/C), Fragen des Installers, danach
    ├── 03-python.md                # pyenv, uv, ruff, ipdb, Jupyter, neues Projekt, altes Projekt
    ├── 04-claude-code.md           # Login, CLI/VS Code/Desktop-App, settings.json, CLAUDE.md, Alltag, Kosten, Tipps
    ├── 05-chatgpt-codex.md         # ChatGPT-App, Codex CLI, VS-Code-Extension, wann Claude / wann ChatGPT
    ├── 06-git-github.md            # gh auth login, SSH-Key, Aliasse, täglicher Ablauf, eigene Repos
    ├── 07-alltag.md                # Shell-Tipps, Dateien Windows<->WSL, Docker Desktop, Updates, Backup
    └── 99-troubleshooting.md       # Bekannte Fehler und Lösungen
```

Absichtlich **nicht** im Repo: `~/.zshrc.local`, `~/.gitconfig.local`, `~/.claude.json`, SSH-Schlüssel, Tokens und Passwörter (siehe `.gitignore`).

## Pflege

Weil die Konfigurationsdateien im Home nur Symlinks ins Repo sind, ist jede Änderung an `~/.zshrc`, `~/.gitconfig`, den VS-Code-Machine-Settings oder `~/.claude/settings.json` automatisch eine Änderung im Repo. Sie fehlt nur noch im Git-Verlauf.

### Änderungen committen und pushen

```bash
dotfiles
```

Der Alias wechselt in den Repo-Ordner, egal wo er liegt (er folgt dem Symlink von `~/.zshrc`). Dann wie gewohnt:

```bash
git status
```

```bash
git add -A && git commit -m "zsh: Alias für ... ergänzt"
```

```bash
git push
```

Auf den anderen Rechnern anschliessend `dotfiles-update` ausführen (Weg C).

### Eine neue Einstellung aufnehmen

| Was | Wo im Repo | Danach |
|---|---|---|
| Neues apt-Paket | `packages/apt.txt`, eine Zeile | `./install.sh` (Vorhandenes wird übersprungen; mit `--skip-python --skip-node --skip-ai --skip-vscode` geht es schneller) |
| Neues Python-CLI-Tool | `packages/uv-tools.txt` | `./install.sh --skip-apt --skip-python --skip-node --skip-ai --skip-vscode` |
| Neue VS-Code-Extension (WSL) | `packages/vscode-extensions.txt` | `./install.sh --skip-apt --skip-python --skip-node --skip-ai` |
| Neuer Alias | `zsh/aliases`, mit Kommentar | `exec zsh` |
| Neue Shell-Funktion oder Umgebungsvariable | `zsh/zshrc` | `exec zsh` |
| VS-Code-Einstellung (Machine-Ebene) | in VS Code ändern, landet dank Symlink in `vscode/settings.json` | nur committen |
| Verhalten von Claude Code | `claude/CLAUDE.md`, `claude/rules/*.md`, `claude/settings.json` | neue Claude-Sitzung starten |
| Nur für diese eine Maschine | `~/.zshrc.local`, `~/.gitconfig.local` | nichts, diese Dateien sind ignoriert |

Für die installierten Programme selbst gibt es die Funktion `update-all` aus `zsh/zshrc`: Sie aktualisiert apt-Pakete, uv und die uv-Tools, Claude Code, Codex CLI und oh-my-zsh in einem Rutsch.

### Symlink-Falle

⚠️ Verschiebe den Repo-Ordner **nie** und benenne ihn **nie** um, ohne danach `./install.sh --links-only` im neuen Ordner auszuführen. Sonst zeigen alle Symlinks ins Leere: zsh startet mit dem Menü „zsh-newuser-install", Git kennt deine Aliasse nicht mehr, VS Code und Claude Code verlieren ihre Einstellungen. Behebung:

```bash
cd /neuer/pfad/zu/dotfiles && ./install.sh --links-only
```

Manche Programme ersetzen einen Symlink beim Speichern durch eine echte Datei (zum Beispiel Claude Code, wenn es `~/.claude/settings.json` selbst schreibt). Prüfen mit `ls -la ~/.claude/settings.json`: Steht dort kein `->`, ist der Link weg. Dann zuerst die Unterschiede ansehen und ins Repo übernehmen, danach neu verlinken:

```bash
dotfiles && diff ~/.claude/settings.json claude/settings.json
```

```bash
./install.sh --links-only
```

Die ersetzte Datei liegt danach im Backup-Ordner (`~/.dotfiles-backup/<Datum>`), es geht also nichts verloren.

### Ausprobieren ohne Risiko

```bash
./install.sh --dry-run -y
```

zeigt jeden Befehl, den der Installer ausführen würde, und ändert nichts – weder Dateien noch Downloads.

## Dokumentation

Die Anleitungen bauen aufeinander auf. Einsteiger lesen sie von oben nach unten, Fortgeschrittene springen direkt zum Thema.

- [docs/01-windows-vorbereiten.md](docs/01-windows-vorbereiten.md) – Einsteiger-Guide: WSL 2 und Ubuntu 24.04 installieren, Windows Terminal und VS Code einrichten, erstes Login, häufige Stolpersteine.
- [docs/02-installation.md](docs/02-installation.md) – Die dotfiles installieren (Weg A/B/C), jede Frage des Installers erklärt, was mit bestehenden Dateien passiert, Prüfbefehle und Logins danach.
- [docs/03-python.md](docs/03-python.md) – pyenv, uv und ruff im Zusammenspiel: neues Projekt anlegen, altes Projekt weiterführen, Jupyter, Debugging mit ipdb, pre-commit.
- [docs/04-claude-code.md](docs/04-claude-code.md) – Claude Code als primärer KI-Assistent: Login, Terminal/VS Code/Desktop-App, unsere `settings.json` Zeile für Zeile, `CLAUDE.md` und Regeln, Arbeitsmuster, Kosten, Troubleshooting.
- [docs/05-chatgpt-codex.md](docs/05-chatgpt-codex.md) – ChatGPT-App und Codex CLI installieren und anmelden, wann Claude und wann ChatGPT, Vergleichstabelle, Datenschutz.
- [docs/06-git-github.md](docs/06-git-github.md) – Git-Grundlagen, `gh auth login`, SSH-Schlüssel, unsere Git-Aliasse, täglicher Ablauf mit Branches und Pull Requests, eigene Repos anlegen.
- [docs/07-alltag.md](docs/07-alltag.md) – Terminal-Bedienung, oh-my-zsh-Kürzel, `update-all`, Dateien zwischen Windows und WSL, Docker Desktop, WSL-Befehle in PowerShell, Backup-Strategie.
- [docs/99-troubleshooting.md](docs/99-troubleshooting.md) – Bekannte Fehler mit Ursache und Lösung: tote Symlinks, `_docker`-Meldung, `command not found`, pyenv-Build, Git-Passwortabfragen, WSL startet nicht, DNS, alles zurücksetzen.

## Getestet mit

Referenzmaschine, Stand September 2026:

| Komponente | Version |
|---|---|
| Windows | Windows 11 |
| WSL | 2.4.x (Update auf 2.7.x verfügbar) |
| Ubuntu | 24.04.2 LTS (noble) |
| zsh | 5.9 |
| Python (`pyenv global`) | 3.12 |
| uv / ruff | 0.12.x / 0.16.x |
| GitHub CLI (`gh`) | 2.70 |
| VS Code | 1.139 mit WSL-Remote |
| Docker Desktop | 4.40 |

`install.sh` unterstützt zusätzlich Ubuntu 22.04, das ist aber nicht regelmässig getestet. Achtung: `git/gitconfig` setzt `merge.conflictstyle = zdiff3`, das braucht Git ab 2.35; Ubuntu 22.04 liefert 2.34 und bricht damit jedes Merge ab. Unter 22.04 deshalb in `~/.gitconfig.local` `conflictstyle = diff3` im Abschnitt `[merge]` setzen (die Datei wird zuletzt geladen und gewinnt).
