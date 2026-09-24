# Die dotfiles installieren

Voraussetzung: Ubuntu 24.04 läuft in WSL 2 und du hast ein Ubuntu-Terminal offen (siehe [01-windows-vorbereiten.md](01-windows-vorbereiten.md)). Alle Befehle auf dieser Seite gehören ins **Ubuntu-Terminal**, ausser wenn ausdrücklich PowerShell steht.

Der Installer `install.sh` richtet in 12 Schritten die komplette Umgebung ein: zsh mit oh-my-zsh, Python (pyenv, uv, ruff), Node (nvm), GitHub CLI, Claude Code, optional Codex CLI, VS-Code-Extensions und alle Konfigurationsdateien aus diesem Repo. Rechne mit **10 bis 20 Minuten**; am längsten dauert das Kompilieren von Python (einige Minuten, in denen scheinbar nichts passiert).

> 💡 **Für Einsteiger:** Der Installer ist **idempotent**. Das bedeutet: Du kannst ihn beliebig oft starten. Alles, was schon erledigt ist, meldet er als „übersprungen (bereits vorhanden)" und macht beim Rest weiter. Wenn also mitten in der Installation das WLAN wegbricht oder du versehentlich das Fenster schliesst, startest du denselben Befehl einfach noch einmal. Es geht nichts verloren.

## Drei Wege

| Weg | Für wen | Kurzfassung |
|---|---|---|
| **A: Neuer Rechner (Elias)** | Elias auf einem frischen Rechner, solange das Repo privat ist | `gh auth login`, dann `gh repo clone`, dann `./install.sh` |
| **B: Einsteiger** | Alle, die das Repo nur benutzen wollen (z. B. Elias' Vater) | Ein einziger Befehl: `bootstrap.sh` klont das Repo und startet den Installer. Braucht ein **öffentliches** Repo. |
| **C: Bestehende Maschine nachziehen** | Rechner, auf dem die dotfiles schon liegen | `dotfiles-update` (holt Änderungen und setzt die Links neu) |

## Weg A: Neuer Rechner (Elias)

Ein frisches Ubuntu hat die GitHub CLI `gh` noch nicht. Das Ubuntu-Paket reicht für den Login; der Installer richtet in Schritt 3 zusätzlich das offizielle GitHub-Apt-Repo ein, von dem `gh` bei künftigen Updates (`update-all`) kommt.

```bash
sudo apt-get update && sudo apt-get install -y git gh
```

```bash
gh auth login
```

Die Antworten auf die Fragen von `gh auth login` stehen im Abschnitt [GitHub-Login](#github-gh-auth-login) weiter unten: GitHub.com, HTTPS, Yes, Login with a web browser. Danach das Repo klonen und den Installer starten:

```bash
gh repo clone Elias-Martinelli/dotfiles ~/code/Elias-Martinelli/dotfiles
```

```bash
cd ~/code/Elias-Martinelli/dotfiles && ./install.sh
```

Der Installer stellt jetzt seine Fragen (siehe [Die Fragen des Installers](#die-fragen-des-installers)) und läuft dann ohne weitere Rückfragen durch.

### Umzug von einem alten dotfiles-Ordner

Liegt unter `~/code/Elias-Martinelli/dotfiles` noch das alte Le-Wagon-Repo, dessen Dateien per Symlink eingebunden sind (`~/.zshrc`, `~/.zprofile`, `~/.aliases`, `~/.gitconfig`, `~/.rspec`, die VS-Code-Machine-Settings und `~/.vscode-server/data/Machine/keybindings.json`), dann verschiebe den alten Ordner, klone das neue Repo an dieselbe Stelle und starte den Installer **im selben Terminalfenster**, ohne dazwischen ein neues zu öffnen:

```bash
mv ~/code/Elias-Martinelli/dotfiles ~/code/ARCHIV/dotfiles-lewagon
```

```bash
gh repo clone Elias-Martinelli/dotfiles ~/code/Elias-Martinelli/dotfiles
```

```bash
cd ~/code/Elias-Martinelli/dotfiles && ./install.sh
```

Warum im selben Fenster: Nach dem `mv` zeigen die alten Symlinks ins Leere. Öffnest du jetzt ein neues Terminal, begrüsst dich zsh mit dem Menü „zsh-newuser-install" (erklärt in [99-troubleshooting.md](99-troubleshooting.md), dort mit `q` verlassen). Der Installer ersetzt solche toten Links in Schritt 10 automatisch, danach ist alles wieder normal.

Drei Dateien des alten Repos werden bewusst **nicht** übernommen: `keybindings.json` (enthielt nur Tastenkürzel für die nie installierte Extension `pasteAndIndent`; ausserdem liest VS Code Tastenkürzel nur aus `%APPDATA%\Code\User\keybindings.json` auf der Windows-Seite, nicht aus dem Machine-Ordner in WSL), `rspec` (Ruby-Rest aus dem Kurs) und die macOS-`config` für SSH (unter Linux nie verlinkt; ersetzt durch `ssh/config`). Die Links `~/.vscode-server/data/Machine/keybindings.json` und `~/.rspec` zeigen nach dem `mv` ins Leere; der Installer entfernt genau diese beiden toten Relikt-Links in Schritt 10 mit. Lässt du den alten Ordner dagegen liegen, entferne die beiden Links von Hand:

```bash
rm -f ~/.vscode-server/data/Machine/keybindings.json ~/.rspec
```

## Weg B: Einsteiger

Ein Befehl genügt. Kopiere ihn komplett ins Ubuntu-Terminal und drück Enter:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Elias-Martinelli/dotfiles/main/bootstrap.sh)
```

Was passiert: `bootstrap.sh` prüft, dass du unter Ubuntu bist, installiert bei Bedarf `git` und `curl` (fragt dafür nach deinem Passwort), klont das Repo nach `~/code/dotfiles` und startet dort `install.sh`. Liegt das Repo schon in `~/code/dotfiles`, holt es nur die neusten Änderungen (`git pull --ff-only`).

⚠️ Der Befehl funktioniert nur, wenn das Repo auf GitHub **öffentlich** ist. Ist es privat, meldet `bootstrap.sh` deutlich, dass das Klonen fehlgeschlagen ist. Dann gibt es zwei Möglichkeiten: Elias schaltet das Repo auf öffentlich, oder du gehst nach Weg A vor (dazu muss dein GitHub-Konto Zugriff auf das Repo haben, Elias kann dich als Mitarbeiter eintragen).

> 💡 **Für Einsteiger:** `curl -fsSL <adresse>` lädt eine Datei aus dem Internet, `bash <(...)` führt sie sofort als Skript aus. Das ist bequem, aber du solltest so etwas nur mit Skripten machen, deren Herkunft du kennst. Hier stammt es aus Elias' Repo; du kannst es vorher im Browser unter <https://github.com/Elias-Martinelli/dotfiles/blob/main/bootstrap.sh> lesen.

Der Installer stellt zuerst seine Fragen (Name und E-Mail für Git, Codex, wsl.conf; siehe nächster Abschnitt). **Erst danach** verlangt er einmal dein Linux-Passwort für `sudo`, mit der Meldung „Für apt bzw. /etc/wsl.conf wird sudo benötigt". Tipp das Passwort also nicht schon bei der Frage nach deinem Namen ein. Danach kannst du 10 bis 20 Minuten etwas anderes machen; nur bei Schritt 4 (zsh) kommt eventuell noch einmal eine Passwortabfrage von `chsh`.

## Weg C: Bestehende Maschine nachziehen

Wenn die dotfiles schon installiert sind und du nur Änderungen aus dem Repo übernehmen willst:

```bash
dotfiles-update
```

Der Alias (aus `zsh/aliases`) wechselt in den Repo-Ordner, egal wo er liegt, holt mit `git pull --ff-only` die Änderungen und setzt mit `./install.sh --links-only -y` alle Symlinks neu. Von Hand ist das:

```bash
cd ~/code/Elias-Martinelli/dotfiles && git pull --ff-only && ./install.sh --links-only
```

Sind auch neue Programme dazugekommen (eine neue Zeile in `packages/apt.txt`, `packages/uv-tools.txt` oder `packages/vscode-extensions.txt`), lass `--links-only` weg und starte `./install.sh` ganz oder mit passenden `--skip-*`-Flags. Vorhandenes wird übersprungen.

## Die Fragen des Installers

Alle Fragen kommen in **Schritt 2, vor den langen Installationen**. Du beantwortest sie einmal und musst danach nicht mehr am Rechner sitzen. In eckigen Klammern steht jeweils die Vorgabe; Enter übernimmt sie.

| Frage | Vorgabe | Was du antwortest |
|---|---|---|
| **Git-Name** | dein bestehender `git config --global user.name`, sonst leer | Vor- und Nachname, so wie er in deinen Commits erscheinen soll, z. B. `Peter Muster`. Ohne Vorgabe ist die Antwort Pflicht. |
| **Git-E-Mail** | dein bestehender `git config --global user.email`, sonst leer | Die E-Mail-Adresse deines GitHub-Kontos. Ohne Vorgabe Pflicht. |
| **Codex CLI installieren?** | Ja | `Ja`, wenn du ein bezahltes ChatGPT-Konto hast oder Codex später ausprobieren willst. `Nein`, wenn du nur Claude nutzt. Lässt sich jederzeit mit einem weiteren Lauf ohne `--no-codex` nachholen. |
| **/etc/wsl.conf schreiben?** | Ja (nur unter WSL) | `Ja`. Die Datei schaltet systemd ein und setzt dich als Standardbenutzer. Enthält `/etc/wsl.conf` schon `systemd=true`, wird nichts geändert. |

Name und E-Mail landen **nicht** im Repo, sondern in `~/.gitconfig.local`, die der Installer aus `git/gitconfig.local.example` erzeugt. Existiert die Datei schon, bleibt sie unangetastet.

> 💡 **Für Einsteiger:** Git ist das Programm, das Änderungen an deinem Code protokolliert. Jede gespeicherte Änderung („Commit") trägt Name und E-Mail des Autors. Deshalb fragt der Installer danach. Du kannst die Werte später in `~/.gitconfig.local` ändern.

### Ohne Fragen: `-y`

Mit `-y` stellt der Installer keine Fragen und nimmt die Vorgaben (Codex: Ja, wsl.conf: Ja). Git-Name und E-Mail müssen dann aus einer bestehenden Git-Konfiguration kommen oder als Umgebungsvariablen mitgegeben werden:

```bash
GIT_NAME="Peter Muster" GIT_EMAIL="peter@example.com" ./install.sh -y
```

### Flags und Umgebungsvariablen

Alle Flags lassen sich kombinieren.

| Flag | Wirkung |
|---|---|
| `-y`, `--yes` | Keine Rückfragen, Standardantworten verwenden |
| `--links-only` | Nur Symlinks und Kopien setzen (Schritt 10), nichts installieren |
| `--skip-apt` | Schritt 3 (apt-Pakete, GitHub-CLI-Repo) überspringen |
| `--skip-python` | Schritt 5 (pyenv, Python) überspringen |
| `--skip-node` | Schritt 7 (nvm, Node) überspringen |
| `--skip-ai` | Schritt 8 (Claude Code, Codex CLI) überspringen |
| `--skip-vscode` | Schritt 9 (VS-Code-Extensions) überspringen |
| `--skip-wslconf` | Schritt 11 (`/etc/wsl.conf`) überspringen |
| `--no-codex` | Codex CLI nicht installieren und nicht danach fragen |
| `--dry-run` | Alle Aktionen nur anzeigen (`[dry-run] befehl ...`), nichts ausführen, kein sudo, kein Internet nötig |
| `-h`, `--help` | Hilfe anzeigen |

| Umgebungsvariable | Standard | Wirkung |
|---|---|---|
| `GIT_NAME` | bestehender `git config --global user.name` | Name für `~/.gitconfig.local` (vor allem mit `-y`) |
| `GIT_EMAIL` | bestehender `git config --global user.email` | E-Mail für `~/.gitconfig.local` (vor allem mit `-y`) |
| `PYTHON_VERSION` | `3.12` | Python-Version für pyenv; ein Präfix wie `3.12` nimmt die neuste 3.12.x |
| `DOTFILES_BACKUP_DIR` | `~/.dotfiles-backup/<YYYYmmdd-HHMMSS>` | Ordner für bestehende Dateien, die der Installer ersetzt |

Wer zuerst sehen will, was passieren würde, ohne dass etwas verändert wird:

```bash
./install.sh --dry-run -y
```

## Was der Installer tut (12 Schritte)

Jeder Schritt meldet sich mit einer Überschrift wie `──── Schritt 1/12: Vorprüfungen ────`. So erkennst du, wo er gerade steht.

| Schritt | Titel | Was passiert | Überspringen mit |
|---|---|---|---|
| 1 | Vorprüfungen | Ubuntu/Debian? Nicht root? WSL? `curl` und `git` da? Sonst Hinweis auf `bootstrap.sh`. | – |
| 2 | Fragen stellen | Git-Name, Git-E-Mail, Codex ja/nein, wsl.conf ja/nein (siehe oben). Danach fragt der Installer einmal nach dem `sudo`-Passwort, falls Pakete fehlen oder wsl.conf geschrieben wird. | `-y` |
| 3 | apt | GitHub-CLI-Apt-Repo einrichten, `apt-get update`, alle Pakete aus `packages/apt.txt` installieren (Basiswerkzeuge, `gh`, Build-Abhängigkeiten für pyenv), Locale `en_US.UTF-8` erzeugen. | `--skip-apt` |
| 4 | zsh | oh-my-zsh unbeaufsichtigt installieren, Plugins `zsh-autosuggestions` und `zsh-syntax-highlighting` klonen, Login-Shell auf zsh umstellen. `chsh` fragt dabei nach deinem Passwort. | – |
| 5 | Python | pyenv (mit pyenv-virtualenv) installieren, Python `3.12` **kompilieren** (dauert einige Minuten), als `pyenv global` setzen. | `--skip-python` |
| 6 | uv | uv installieren, dann `uv tool install` für jede Zeile aus `packages/uv-tools.txt` (ruff, pre-commit). | `--skip-python` überspringt nur Schritt 5; uv läuft immer, ausser mit `--links-only` |
| 7 | Node | nvm installieren, aktuelle LTS-Version installieren und als Standard setzen. | `--skip-node` |
| 8 | KI-Werkzeuge | Claude Code nativ nach `~/.local/bin/claude`; optional Codex CLI. Beides ohne sudo. | `--skip-ai`, `--no-codex` |
| 9 | VS Code | Nur wenn `code` in Ubuntu erreichbar ist: Extensions aus `packages/vscode-extensions.txt` installieren. Sonst Hinweis, VS Code auf Windows zu installieren, einmal `code .` auszuführen und später `./install.sh --skip-apt --skip-python --skip-node --skip-ai` zu starten. | `--skip-vscode` |
| 10 | Verknüpfen | Symlinks von `~` ins Repo setzen (Tabelle unten). Läuft auch bei `--links-only`. | – |
| 11 | wsl.conf | Nur unter WSL und nur mit Zustimmung: `wsl/wsl.conf` mit deinem Benutzernamen nach `/etc/wsl.conf` (sudo). | `--skip-wslconf` |
| 12 | Zusammenfassung | Was installiert und was übersprungen wurde, Backup-Ordner, nächste Schritte. | – |

### Was mit bestehenden Dateien passiert (Schritt 10)

Der Installer legt keine Kopien deiner Konfiguration an, sondern **Symlinks**: Verweise von `~/.zshrc`, `~/.gitconfig` usw. auf die Dateien im Repo. Dadurch gilt jede Änderung im Repo sofort, und jede Änderung an `~/.zshrc` ist automatisch eine Änderung im Repo.

| Im Repo | Ziel im Home | Art |
|---|---|---|
| `zsh/zshrc`, `zsh/zprofile`, `zsh/aliases` | `~/.zshrc`, `~/.zprofile`, `~/.aliases` | Symlink |
| `zsh/zshrc.local.example` | `~/.zshrc.local` | Kopie, nur wenn nicht vorhanden |
| `git/gitconfig` | `~/.gitconfig` | Symlink |
| `git/gitconfig.local.example` | `~/.gitconfig.local` | Kopie mit Name und E-Mail, nie überschrieben |
| `ssh/config` | `~/.ssh/config` | Symlink (`~/.ssh` mit `chmod 700`) |
| `vscode/settings.json` | `~/.vscode-server/data/Machine/settings.json` | Symlink |
| `claude/settings.json`, `claude/CLAUDE.md`, `claude/rules/` | `~/.claude/settings.json`, `~/.claude/CLAUDE.md`, `~/.claude/rules` | Symlinks (rules als Ordner-Link) |
| `codex/config.toml` | `~/.codex/config.toml` | Kopie, nur wenn Codex gewünscht und noch keine Datei vorhanden |

Für jedes Ziel gilt:

- Existiert dort eine **echte Datei oder ein Ordner** (z. B. die Standard-`.bashrc`-artige `~/.zshrc` von oh-my-zsh oder eine selbst geschriebene `~/.gitconfig`), wird sie in den **Backup-Ordner** `~/.dotfiles-backup/<YYYYmmdd-HHMMSS>/` verschoben, mit derselben Pfadstruktur (also z. B. `.../.vscode-server/data/Machine/settings.json`). Der Installer meldet jede Sicherung und nennt den Ordner in der Zusammenfassung.
- Ist dort schon ein **Symlink auf die Repo-Datei**, passiert nichts („übersprungen").
- Zeigt ein Symlink **woandershin** oder **ins Leere** (alter dotfiles-Ordner), wird er ersetzt.

Nichts wird gelöscht – mit einer Ausnahme: Die beiden toten Relikt-Links `~/.vscode-server/data/Machine/keybindings.json` und `~/.rspec` aus dem alten Le-Wagon-Repo (siehe [Umzug von einem alten dotfiles-Ordner](#umzug-von-einem-alten-dotfiles-ordner)) entfernt der Installer, weil sie ins Leere zeigen und nichts enthalten, das man sichern könnte. Was du aus dem Backup zurückhaben willst, findest du dort und kannst es in die Repo-Datei oder in `~/.zshrc.local` bzw. `~/.gitconfig.local` übernehmen.

> 💡 **Für Einsteiger:** Ein **Symlink** (symbolischer Link) ist eine Verknüpfung, wie eine Datei-Verknüpfung auf dem Windows-Desktop. `ls -la ~/.zshrc` zeigt ihn mit einem Pfeil: `.zshrc -> /home/peter/code/dotfiles/zsh/zshrc`. Wichtig: Verschiebe oder benenne den Repo-Ordner nie um, ohne danach `./install.sh --links-only` auszuführen, sonst zeigen alle Verknüpfungen ins Leere.

## Nach der Installation

### 1. Terminal neu laden

Die neue Shell-Konfiguration gilt erst in einem neuen Terminal. Entweder das Fenster schliessen und Ubuntu neu öffnen, oder im laufenden Fenster:

```bash
exec zsh
```

Danach sieht der Prompt anders aus: Das oh-my-zsh-Theme `robbyrussell` zeigt links einen Pfeil `➜` und den aktuellen Ordner, rechts steht `[🐍 3.12.x]`, die aktive Python-Version (eingerichtet in `zsh/zshrc`).

Hat der Installer `/etc/wsl.conf` geschrieben (dann nennt seine Zusammenfassung als ersten nächsten Schritt `wsl --shutdown`), mach zuerst [Schritt 5](#5-wsl-neu-starten-wslconf). Dieser WSL-Neustart ersetzt das `exec zsh`.

> 💡 **Für Einsteiger:** `exec zsh` startet die Shell im selben Fenster neu und liest dabei die frische Konfiguration ein. Sieht dein Prompt danach immer noch aus wie vorher (`name@pc:~$`, ohne Pfeil), lies in [99-troubleshooting.md](99-troubleshooting.md#claude-command-not-found-auch-uv-ruff-codex) nach.

### 2. Prüfbefehle

Jeder dieser Befehle gibt eine Versionsnummer zurück. Die genauen Zahlen sind unwichtig; es zählt, dass keine Fehlermeldung kommt. Tipp sie einzeln ein.

```bash
zsh --version
```

Erwartet: `zsh 5.9 (x86_64-ubuntu-linux-gnu)` oder ähnlich.

```bash
pyenv version
```

Erwartet: `3.12.x (set by /home/<name>/.pyenv/version)`, also die neuste 3.12, die der Installer kompiliert hat.

```bash
uv --version
```

```bash
ruff --version
```

Erwartet: `uv 0.x.y` beziehungsweise `ruff 0.x.y`.

```bash
node --version
```

Erwartet: eine Versionsnummer mit vorangestelltem `v` (die aktuelle LTS-Version von Node).

```bash
claude --version
```

Erwartet: eine Versionsnummer. Claude Code hält sich danach selbst aktuell.

```bash
gh --version
```

Erwartet: `gh version 2.x.y (YYYY-MM-DD)` und eine zweite Zeile mit der Release-Adresse.

```bash
code --version
```

Erwartet: drei Zeilen (Versionsnummer, ein langer Commit-Hash, `x64`). Beim allerersten Aufruf lädt der Befehl den VS-Code-Server nach Ubuntu, das dauert etwa eine halbe Minute; danach antwortet er sofort.

Nur wenn du bei der Codex-Frage Ja gesagt hast:

```bash
codex --version
```

Meldet einer der Befehle `command not found`:

| Befehl | Wahrscheinliche Ursache | Lösung |
|---|---|---|
| `claude`, `uv`, `ruff` | Das Terminal hat die neue Konfiguration noch nicht geladen (`~/.local/bin` fehlt im PATH) | `exec zsh` oder neues Terminal; bleibt es dabei: [99-troubleshooting.md](99-troubleshooting.md#claude-command-not-found-auch-uv-ruff-codex) |
| `pyenv`, `node` | wie oben: Konfiguration noch nicht geladen | `exec zsh`; hilft das nicht, ist Schritt 5 bzw. 7 nicht durchgelaufen: `./install.sh` erneut starten |
| `code` | VS Code ist nicht auf Windows installiert, oder WSL wurde danach nicht neu gestartet | [01-windows-vorbereiten.md, Schritt 6](01-windows-vorbereiten.md#6-vs-code-installieren-und-mit-wsl-verbinden); danach in der PowerShell `wsl --shutdown` und Ubuntu neu öffnen |
| `codex` | Bei der Frage „Codex CLI installieren?" stand Nein | Erneuter Lauf ohne `--no-codex`, zum Beispiel `./install.sh --skip-apt --skip-python --skip-node --skip-vscode`, und die Frage mit Ja beantworten |

### 3. Logins

Die Werkzeuge sind installiert, kennen aber deine Konten noch nicht. Drei Logins, alle einmalig.

#### GitHub: gh auth login

Weg A hat diesen Login schon erledigt. Prüfen:

```bash
gh auth status
```

Steht dort `Logged in to github.com account <dein-name>`, überspring den Rest dieses Abschnitts. Sonst:

```bash
gh auth login
```

gh stellt vier Fragen; mit den Pfeiltasten wählen, Enter bestätigt:

| Frage | Antwort |
|---|---|
| `Where do you use GitHub?` | **GitHub.com** |
| `What is your preferred protocol for Git operations on this host?` | **HTTPS** |
| `Authenticate Git with your GitHub credentials?` | **Yes** |
| `How would you like to authenticate GitHub CLI?` | **Login with a web browser** |

Dann zeigt gh einen Einmal-Code (`First copy your one-time code: XXXX-XXXX`). Merk ihn dir und drück Enter: Der Browser öffnet die GitHub-Seite zur Geräteanmeldung. Öffnet sich unter WSL kein Browser, geh in Windows von Hand auf <https://github.com/login/device>. Code eingeben, „Authorize github" bestätigen; im Terminal erscheint `Logged in as <dein-name>`.

Zum Schluss den Credential-Helper eintragen (mit **Yes** oben ist er schon gesetzt, der Befehl schadet nicht) und den Status prüfen:

```bash
gh auth setup-git
```

```bash
gh auth status
```

Warum das nötig ist und wie du die dadurch geänderte `~/.gitconfig` handhabst, steht in [06-git-github.md](06-git-github.md#github-login-mit-gh).

#### Claude Code

```bash
claude
```

Beim ersten Start stellt Claude Code ein paar Einrichtungsfragen (unter anderem zum Farbschema) und bietet dann die Anmeldung an. Wähle die Anmeldung mit deinem Claude-Konto (Pro oder Max; der Gratis-Plan reicht nicht). Der Browser öffnet sich, du bestätigst die Anmeldung, und Claude Code meldet im Terminal, dass du angemeldet bist. Beende die Sitzung mit `/exit`, dann:

```bash
claude doctor
```

`claude doctor` prüft Installation, Version und Auto-Update und meldet Probleme im Klartext. Alles Weitere zu Claude Code, unseren Einstellungen und dem Alltag damit steht in [04-claude-code.md](04-claude-code.md).

#### Wenn du nicht Elias bist

Die dotfiles sind Elias' persönliche Einstellungen. Drei Dinge passt du an dich an:

1. **Claude Code:** `claude/CLAUDE.md` beginnt mit dem Abschnitt „Über mich" (Elias, HSLU-Student). Ändere ihn vor der ersten richtigen Sitzung, sonst hält Claude dich für Elias. Bearbeite die Datei im Repo, nicht `~/.claude/CLAUDE.md` (das ist nur ein Symlink auf dieselbe Datei):

   ```bash
   dotfiles && code claude/CLAUDE.md
   ```

   Name, Rolle und Sprache anpassen, speichern, dann `git add -A && git commit -m "claude: CLAUDE.md personalisiert"`.
2. **Git-Identität:** kommt aus den Installer-Fragen und steht in `~/.gitconfig.local`. Nichts weiter zu tun.
3. **Eigene Aliasse und Einstellungen:** gehören in `~/.zshrc.local` (liegt nicht im Repo), nicht in `zsh/aliases`.

#### Codex CLI (nur wenn Ja)

```bash
codex
```

Wähle „Sign in with ChatGPT" und melde dich im Browser mit deinem ChatGPT-Konto an (bezahlter Plan nötig). Codex, die VS-Code-Extension und die Aufgabenteilung mit Claude sind in [05-chatgpt-codex.md](05-chatgpt-codex.md) beschrieben.

### 4. VS Code

```bash
cd ~/code && code .
```

Es öffnet sich VS Code mit dem Ordner `code`; unten links steht `WSL: Ubuntu-24.04`. Öffne die Extensions-Ansicht (Ctrl + Shift + X). Im Abschnitt „WSL: Ubuntu-24.04 – Installed" müssen unter anderem **Ruff**, **Python** und **Claude Code** stehen. Ist der Abschnitt leer, war `code` während der Installation noch nicht erreichbar und Schritt 9 wurde übersprungen. Nachholen im Ubuntu-Terminal, im Repo-Ordner (der Alias `dotfiles` bringt dich hin):

```bash
./install.sh --skip-apt --skip-python --skip-node --skip-ai
```

**Ruff-Test.** Lege in VS Code eine neue Datei an: links im Explorer mit Rechtsklick auf den freien Bereich „Neue Datei…" (New File…) wählen, `test_ruff.py` eintippen, Enter. Füge diesen Inhalt ein, absichtlich in falscher Reihenfolge:

```python
import sys
import os

print(os.getcwd(), sys.version)
```

Speichern mit Ctrl + S. Ruff sortiert die Imports sofort um (`import os` steht jetzt vor `import sys`) und formatiert die Datei. Genau das stellt unsere `vscode/settings.json` ein: `editor.formatOnSave` und `source.organizeImports` für Python-Dateien. Passiert beim Speichern nichts, siehe [99-troubleshooting.md](99-troubleshooting.md#ruff-formatiert-nicht-oder-uv-umgebung-in-vs-code-nicht-erkannt). Die Testdatei kannst du danach löschen:

```bash
rm ~/code/test_ruff.py
```

> 💡 **Für Einsteiger:** Eine **Extension** ist eine Erweiterung für VS Code, ähnlich einem Browser-Add-on. Weil VS Code in Ubuntu arbeitet, gibt es zwei Listen: Extensions auf der Windows-Seite (Oberfläche, zum Beispiel „WSL") und Extensions in Ubuntu (alles, was mit deinem Code arbeitet, zum Beispiel Ruff). Der Installer füllt die Ubuntu-Liste aus `packages/vscode-extensions.txt`.

### 5. WSL neu starten (wsl.conf)

Nur nötig, wenn der Installer `/etc/wsl.conf` geschrieben hat (Frage „/etc/wsl.conf schreiben?" mit Ja beantwortet und die Datei enthielt noch kein `systemd=true`). Die Datei schaltet systemd ein und setzt dich als Standardbenutzer; beides gilt erst nach einem vollständigen Neustart von WSL.

Schliesse alle Ubuntu-Fenster und alle VS-Code-Fenster mit WSL-Verbindung. Dann in der **PowerShell** (nicht in Ubuntu):

```powershell
wsl --shutdown
```

Etwa acht Sekunden warten (WSL braucht die Zeit, um wirklich herunterzufahren), dann Ubuntu neu öffnen und prüfen:

```bash
systemctl is-system-running
```

Erwartet: `running` oder `degraded`. Letzteres heisst nur, dass ein unwichtiger Dienst nicht gestartet ist; ohne systemd käme stattdessen eine Fehlermeldung wie `System has not been booted with systemd`.

```bash
whoami
```

Erwartet: dein Linux-Benutzername, nicht `root`.

> 💡 **Für Einsteiger:** **systemd** ist der Dienstverwalter von Linux; mit ihm laufen Hintergrunddienste (Datenbanken, Docker-Werkzeuge) so wie auf einem normalen Ubuntu-Server. Der **Standardbenutzer** legt fest, als wer sich ein neues Ubuntu-Fenster öffnet, damit du nicht versehentlich als Administrator `root` arbeitest.

## Was tun bei Abbruch

Der Installer ist idempotent (siehe den Kasten ganz oben): Du kannst ihn jederzeit mit Ctrl + C abbrechen oder abbrechen lassen (Netzwerk weg, Fenster zu, Laptop zugeklappt) und einfach denselben Befehl noch einmal starten. Erledigte Schritte meldet er als „übersprungen (bereits vorhanden)" und macht beim ersten unfertigen Schritt weiter.

Weg A:

```bash
cd ~/code/Elias-Martinelli/dotfiles && ./install.sh
```

Weg B (der Einzeiler erkennt das vorhandene Repo, holt nur Änderungen mit `git pull --ff-only` und startet dann den Installer):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Elias-Martinelli/dotfiles/main/bootstrap.sh)
```

Willst du Zeit sparen, überspring die fertigen Schritte mit den `--skip-*`-Flags, zum Beispiel nach einem Abbruch beim Python-Kompilieren mit `./install.sh --skip-apt`.

Zwei Sonderfälle nach einem Abbruch:

- Bricht Schritt 5 mit `BUILD FAILED` ab, fehlen Build-Pakete; der erneute Lauf holt sie in Schritt 3 nach. Details in [99-troubleshooting.md](99-troubleshooting.md#pyenv-build-failed).
- Begrüsst dich ein neues Terminal mit dem Menü „zsh-newuser-install", fehlt `~/.zshrc` oder zeigt ins Leere. Drück `q`, starte den Installer erneut, fertig. Erklärt in [99-troubleshooting.md](99-troubleshooting.md#zsh-startet-mit-dem-menü-zsh-newuser-install).
