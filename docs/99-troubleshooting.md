# Troubleshooting: bekannte Fehler und Lösungen

Diese Seite ist zum Nachschlagen: Du hast eine Fehlermeldung, suchst sie in der Tabelle und folgst dem Link zur Lösung. Alle Befehle gehören ins **Ubuntu-Terminal**, ausser wenn ausdrücklich PowerShell steht. `<repo>` steht für den Ordner, in dem das Repo liegt (Elias: `~/code/Elias-Martinelli/dotfiles`, Einsteiger: `~/code/dotfiles`); der Alias `dotfiles` bringt dich hin.

> 💡 **Für Einsteiger:** Lies die Fehlermeldung ganz, auch wenn sie kryptisch aussieht. Meistens steckt der entscheidende Hinweis in wenigen Wörtern (`command not found`, `Permission denied`, `BUILD FAILED`). Such genau diese Wörter in der Tabelle, folge dem Link und arbeite die Lösung Schritt für Schritt ab. Fast alle Probleme hier lösen sich mit einem neuen Terminal oder einem erneuten `./install.sh`.

## Übersicht

| Symptom | Ursache | Lösung |
|---|---|---|
| zsh startet mit einem Menü „zsh-newuser-install" | `~/.zshrc` ist ein toter Symlink (Repo-Ordner verschoben, umbenannt oder gelöscht) | `q` drücken, dann `./install.sh --links-only` im Repo → [Details](#zsh-startet-mit-dem-menü-zsh-newuser-install) |
| `compinit: no such file or directory: ... _docker` beim Start; `docker: command not found` | Docker Desktop läuft nicht oder die WSL-Integration ist aus | Docker Desktop starten, Integration einschalten, `exec zsh` → [Details](#docker-compinit-meldung-und-docker-command-not-found) |
| `code: command not found` | WSL nach der VS-Code-Installation nicht neu gestartet; „Add to PATH" fehlte; VS Code in Ubuntu statt auf Windows installiert | `wsl --shutdown`, VS Code auf Windows prüfen → [Details](#code-command-not-found) |
| `claude: command not found` (auch `uv`, `ruff`, `codex`) | `~/.local/bin` ist in diesem Terminal noch nicht im PATH | `exec zsh` oder neues Terminal → [Details](#claude-command-not-found-auch-uv-ruff-codex) |
| pyenv meldet `BUILD FAILED` | Build-Pakete fehlen | `./install.sh` erneut starten → [Details](#pyenv-build-failed) |
| `pyenv: python: command not found` | `.python-version` nennt eine Version oder Umgebung, die nicht installiert ist | Version installieren oder `.python-version` anpassen → [Details](#pyenv-python-command-not-found) |
| Ruff formatiert beim Speichern nicht; VS Code findet `.venv` nicht | falscher Interpreter, Extension fehlt oder Settings-Symlink weg | Interpreter wählen, Extensions nachinstallieren → [Details](#ruff-formatiert-nicht-oder-uv-umgebung-in-vs-code-nicht-erkannt) |
| Git fragt bei jedem Push nach Benutzername und Passwort | Credential-Helper von gh fehlt | `gh auth setup-git` → [Details](#git-fragt-bei-jedem-push-nach-benutzername-und-passwort) |
| `Permission denied (publickey)` | Remote nutzt SSH, aber kein Schlüssel ist bei GitHub hinterlegt | Remote auf HTTPS umstellen oder SSH-Schlüssel anlegen → [Details](#permission-denied-publickey) |
| WSL startet nicht, Fehler `Wsl/Service/...`, Fenster schliesst sofort | WSL-Dienst hängt oder ist veraltet; Virtualisierung aus | PowerShell: `wsl --shutdown`, `wsl --update` → [Details](#wsl-startet-nicht-oder-meldet-wslservice-fehler) |
| Uhrzeit in Ubuntu falsch (nach Standby) | Uhr der WSL-VM ist stehen geblieben | `sudo hwclock -s` → [Details](#uhrzeit-in-ubuntu-falsch) |
| Kein Internet in Ubuntu, `Temporary failure in name resolution` | DNS-Auflösung in WSL gestört (oft wegen VPN) | `wsl --shutdown`, VPN trennen, `/etc/resolv.conf` prüfen → [Details](#kein-internet-in-ubuntu-temporary-failure-in-name-resolution) |
| `~/.claude/settings.json` (oder `~/.zshrc`, `~/.gitconfig`) ist keine Verknüpfung mehr | ein Programm hat den Symlink durch eine echte Datei ersetzt | Unterschiede ins Repo übernehmen, `./install.sh --links-only` → [Details](#eine-konfigurationsdatei-ist-keine-verknüpfung-mehr) |
| Ich will alles zurücksetzen | – | Backup-Ordner, `./install.sh` erneut oder `wsl --unregister` → [Details](#alles-zurücksetzen) |

## zsh startet mit dem Menü zsh-newuser-install

**Symptom.** Ein neues Terminal zeigt statt des Prompts einen Text, der mit `This is the Z Shell configuration function for new users, zsh-newuser-install.` beginnt, und bietet die Auswahl `(q) Quit and do nothing`, `(0) Exit, creating the file ~/.zshrc`, `(1) Continue to the main menu` und `(2) Populate your ~/.zshrc` an.

**Ursache.** zsh findet keine `~/.zshrc`. Bei uns ist `~/.zshrc` ein Symlink ins Repo; wurde der Repo-Ordner verschoben, umbenannt oder gelöscht, zeigt der Link ins Leere. Typische Fälle: der Umzug vom alten Le-Wagon-Repo ([02-installation.md](02-installation.md#umzug-von-einem-alten-dotfiles-ordner)) oder ein `mv` des Ordners ohne anschliessendes Neu-Verlinken.

**Lösung.**

1. Drück `q` (Quit and do nothing). ⚠️ Nicht `0` oder `2`: Beide schreiben eine neue `~/.zshrc` durch den toten Link hindurch, statt ihn zu reparieren. Du landest in einer nackten zsh ohne Farben und Aliasse; das ist für den Moment in Ordnung.
2. Wechsle in den Repo-Ordner an seinem **neuen** Ort und setze die Links neu. Schritt 10 erkennt tote Symlinks und ersetzt sie:

   ```bash
   cd /neuer/pfad/zu/dotfiles
   ```

   ```bash
   ./install.sh --links-only
   ```

3. Prüfen, danach ein neues Terminal öffnen:

   ```bash
   ls -la ~/.zshrc
   ```

   Der Pfeil muss ins Repo zeigen: `.zshrc -> /home/<name>/code/.../dotfiles/zsh/zshrc`.

Ist das Repo weg (gelöscht, Platte gewechselt), klone es neu ([02-installation.md](02-installation.md)) und starte danach `./install.sh --links-only`. Hintergrund in der README unter [Symlink-Falle](../README.md#symlink-falle).

## Docker: compinit-Meldung und docker: command not found

**Symptom.** Beim Öffnen eines Terminals erscheint `compinit: no such file or directory: /usr/share/zsh/vendor-completions/_docker`, oder `docker ps` antwortet mit `docker: command not found`, obwohl Docker Desktop installiert ist.

**Ursache.** Beide Meldungen haben dieselbe Ursache: Docker Desktop auf Windows läuft nicht, oder seine WSL-Integration für `Ubuntu-24.04` ist ausgeschaltet. Der Befehl `docker` und die Datei `_docker` werden von Docker Desktop in Ubuntu eingeblendet und verschwinden, sobald es nicht läuft. Die `compinit`-Meldung ist harmlos; sie stört nur.

**Lösung.**

1. Docker Desktop starten (Windows-Taste, `Docker` tippen).
2. Zahnrad (Settings) → Resources → WSL integration → Schalter bei `Ubuntu-24.04` einschalten → „Apply & restart".
3. Im Ubuntu-Terminal die Shell neu laden:

   ```bash
   exec zsh
   ```

   Die Meldung ist weg, und `docker --version` antwortet.

Willst du Docker gerade nicht nutzen, kannst du die Meldung ignorieren. Einrichtung und Alltag mit Docker Desktop: [07-alltag.md](07-alltag.md#docker-desktop).

## code: command not found

**Symptom.** `code .` im Ubuntu-Terminal antwortet mit `code: command not found`.

**Ursache und Lösung, in dieser Reihenfolge prüfen:**

1. **WSL wurde nach der VS-Code-Installation nicht neu gestartet.** Ubuntu übernimmt den Windows-PATH (und damit `code`) erst beim Start der Distribution. Alle Ubuntu-Fenster schliessen, dann in der PowerShell:

   ```powershell
   wsl --shutdown
   ```

   Acht Sekunden warten, Ubuntu neu öffnen, `code .` erneut versuchen.
2. **„Add to PATH" war im Installer nicht angehakt.** Dann kennt schon Windows den Befehl nicht (in der PowerShell antwortet `code --version` ebenfalls mit einem Fehler). VS Code auf Windows deinstallieren und mit angehaktem „Zu PATH hinzufügen" (Add to PATH) neu installieren, siehe [01-windows-vorbereiten.md, Schritt 6](01-windows-vorbereiten.md#6-vs-code-installieren-und-mit-wsl-verbinden). Danach WSL wie in Punkt 1 neu starten.
3. **VS Code wurde in Ubuntu statt auf Windows installiert.** Das Linux-Paket bringt keine WSL-Anbindung. In Ubuntu wieder entfernen (`sudo apt remove code`, falls es per apt installiert wurde) und VS Code auf Windows installieren.
4. **Der Windows-PATH ist in WSL abgeschaltet.** Steht in `/etc/wsl.conf` unter `[interop]` die Zeile `appendWindowsPath=false`, sieht Ubuntu keine Windows-Programme. Unsere `wsl/wsl.conf` setzt `true`. Prüfen:

   ```bash
   cat /etc/wsl.conf
   ```

   Steht dort `false`, auf `true` ändern (`sudo nano /etc/wsl.conf`, speichern mit Ctrl + O und Enter, beenden mit Ctrl + X) und WSL wie in Punkt 1 neu starten.

## claude: command not found (auch uv, ruff, codex)

**Symptom.** `claude`, `uv`, `ruff` oder `codex` antworten mit `command not found`, obwohl der Installer sie als installiert gemeldet hat.

**Ursache.** Alle vier liegen in `~/.local/bin`. Diesen Ordner hängen `zsh/zshrc` (Zeile `export PATH="$HOME/.local/bin:$PATH"`) und `zsh/zprofile` in den PATH. Ein Terminal, das vor oder während der Installation geöffnet wurde, kennt die neue Konfiguration noch nicht. Läuft das Terminal noch mit bash statt zsh (Prompt `name@pc:~$` statt `➜`), wurde die Login-Shell nicht umgestellt.

**Lösung.**

1. Shell neu laden, oder das Terminal schliessen und neu öffnen:

   ```bash
   exec zsh
   ```

2. Ist der Prompt danach immer noch der von bash, hat `chsh` im Installer nicht geklappt (zum Beispiel falsches Passwort). Von Hand nachholen, dann das Terminal neu öffnen:

   ```bash
   chsh -s "$(command -v zsh)"
   ```

3. Fehlt die Datei tatsächlich?

   ```bash
   ls ~/.local/bin/claude
   ```

   Meldet `ls` `No such file or directory`, ist die Installation nicht durchgelaufen. Schritt 8 (und Schritt 6 für uv und ruff) gezielt wiederholen, im Repo-Ordner:

   ```bash
   ./install.sh --skip-apt --skip-python --skip-node --skip-vscode
   ```

4. Zum Schluss:

   ```bash
   claude doctor
   ```

## pyenv: BUILD FAILED

**Symptom.** Schritt 5 des Installers bricht ab mit `BUILD FAILED (Ubuntu 24.04 using python-build ...)`, oft begleitet von Zeilen wie `ModuleNotFoundError: No module named '_ssl'` oder `The necessary bits to build these optional modules were not found`.

**Ursache.** pyenv kompiliert Python aus dem Quellcode und braucht dafür Entwicklungs-Bibliotheken, die im System fehlen. Typisch nach `--skip-apt` oder wenn Schritt 3 abgebrochen wurde.

**Lösung.** Der Installer kennt die Liste. Erneut starten, im Repo-Ordner:

```bash
./install.sh
```

Schritt 3 installiert alles, was aus `packages/apt.txt` noch fehlt, und Schritt 5 versucht `pyenv install --skip-existing 3.12` erneut. Schneller, wenn Node, KI-Werkzeuge und VS Code schon da sind:

```bash
./install.sh --skip-node --skip-ai --skip-vscode
```

Falls du die Pakete lieber von Hand installierst: Das sind genau die Build-Abhängigkeiten aus `packages/apt.txt`:

```bash
sudo apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev libncurses-dev libffi-dev liblzma-dev tk-dev libxml2-dev libxmlsec1-dev llvm xz-utils libzstd-dev
```

Danach `pyenv install 3.12` oder wieder `./install.sh`.

## pyenv: python: command not found

**Symptom.** In einem Projektordner antwortet `python` mit:

```text
pyenv: python: command not found

The `python' command exists in these Python versions:
  3.12.3
```

In einem anderen Ordner funktioniert `python` normal.

**Ursache.** Im Ordner (oder in einem übergeordneten) liegt eine Datei `.python-version`, die eine Version oder eine pyenv-virtualenv nennt, die auf diesem Rechner nicht installiert ist. Das passiert bei geklonten Kurs-Projekten und nach dem Aufräumen alter Umgebungen. Prüfen:

```bash
cat .python-version
```

```bash
pyenv versions
```

**Lösung.** Entweder das Genannte installieren, zum Beispiel die Version:

```bash
pyenv install 3.12
```

beziehungsweise eine virtuelle Umgebung mit dem Namen aus `.python-version`:

```bash
pyenv virtualenv 3.12 <name>
```

Oder die Datei auf die vorhandene Version setzen (für uv-Projekte ohnehin richtig):

```bash
echo 3.12 > .python-version
```

Wie alte pyenv-Projekte weitergeführt oder auf uv migriert werden, steht in [03-python.md](03-python.md#bestehendes-pyenv-projekt-weiterführen) (Abschnitte „Bestehendes pyenv-Projekt weiterführen" und „Migration pyenv-virtualenv -> uv").

## Ruff formatiert nicht oder uv-Umgebung in VS Code nicht erkannt

**Symptom.** Beim Speichern einer `.py`-Datei passiert nichts (Imports bleiben unsortiert), Pylance unterstreicht Pakete aus deiner `.venv` als unbekannt, oder unten rechts in VS Code steht ein falscher Interpreter.

**Ursache.** Eine von drei Sachen: VS Code nutzt den falschen Interpreter, die Extensions fehlen auf der Ubuntu-Seite, oder der Symlink unserer Machine-Settings ist weg.

**Lösung, der Reihe nach:**

1. **Interpreter wählen.** Ctrl + Shift + P, „Python: Select Interpreter" tippen, den Eintrag mit `./.venv/bin/python` wählen (uv-Projekt) beziehungsweise `~/.pyenv/versions/<env>/bin/python` (pyenv-Projekt). Details in [03-python.md](03-python.md#neues-projekt-schritt-für-schritt), Punkt 7.
2. **Extensions prüfen.** Im Ubuntu-Terminal:

   ```bash
   code --list-extensions | grep -i ruff
   ```

   Kommt nichts zurück, fehlen die Extensions auf der WSL-Seite. Nachinstallieren, im Repo-Ordner:

   ```bash
   ./install.sh --skip-apt --skip-python --skip-node --skip-ai
   ```

   Danach das VS-Code-Fenster neu laden (Ctrl + Shift + P, „Developer: Reload Window").
3. **Settings-Symlink prüfen.**

   ```bash
   ls -la ~/.vscode-server/data/Machine/settings.json
   ```

   Der Pfeil muss auf `<repo>/vscode/settings.json` zeigen. Fehlt der Pfeil oder die Datei, neu verlinken (im Repo-Ordner):

   ```bash
   ./install.sh --links-only
   ```

   Eine ersetzte Datei liegt danach in `~/.dotfiles-backup/<YYYYmmdd-HHMMSS>/`.

## Git fragt bei jedem Push nach Benutzername und Passwort

**Symptom.** `git push` oder `git pull` verlangt `Username for 'https://github.com':` und danach ein Passwort. Ein GitHub-Passwort wird dort ohnehin nicht mehr akzeptiert.

**Ursache.** Git kennt den Credential-Helper von gh nicht: Beim Login wurde „Authenticate Git with your GitHub credentials?" mit No beantwortet, `gh auth login` fehlt ganz, oder die `~/.gitconfig` wurde seither ersetzt.

**Lösung.**

```bash
gh auth status
```

Meldet gh `You are not logged into any GitHub hosts`, zuerst `gh auth login` wie in [02-installation.md](02-installation.md#github-gh-auth-login). Dann den Helper eintragen:

```bash
gh auth setup-git
```

Der Befehl schreibt durch den Symlink in `git/gitconfig`; ob du das committest oder mit `GIT_CONFIG_GLOBAL` in `~/.gitconfig.local` umlenkst, steht in [06-git-github.md](06-git-github.md#credential-helper-warum-git-nicht-nach-dem-passwort-fragt).

## Permission denied (publickey)

**Symptom.** `git clone`, `git pull` oder `git push` bricht ab mit `git@github.com: Permission denied (publickey).` und `fatal: Could not read from remote repository.`

**Ursache.** Das Repo nutzt eine SSH-Adresse (`git@github.com:...`), aber auf diesem Rechner ist kein SSH-Schlüssel vorhanden oder er ist bei GitHub nicht hinterlegt. Prüfen, welche Adresse das Repo nutzt:

```bash
git remote -v
```

**Lösung A (schnell): auf HTTPS umstellen.** Dann übernimmt gh die Anmeldung:

```bash
git remote set-url origin https://github.com/<benutzer>/<repo>.git
```

**Lösung B: SSH-Schlüssel einrichten.** Schritt für Schritt in [06-git-github.md](06-git-github.md#ssh-schlüssel-optional); die Kurzfassung:

```bash
ssh-keygen -t ed25519 -C "du@example.com"
```

```bash
gh ssh-key add ~/.ssh/id_ed25519.pub --title "WSL Laptop"
```

```bash
ssh -T git@github.com
```

Erwartete Antwort: `Hi <dein-name>! You've successfully authenticated, but GitHub does not provide shell access.`

## WSL startet nicht oder meldet Wsl/Service-Fehler

**Symptom.** Das Ubuntu-Fenster schliesst sich sofort wieder, zeigt einen Fehlercode wie `Wsl/Service/CreateInstance/...` oder `Wsl/Service/0x...`, oder `wsl` in der PowerShell antwortet gar nicht.

**Ursache.** Der WSL-Dienst auf Windows hängt oder ist veraltet; nach einem Windows-Update fehlt ein Neustart; seltener ist die Virtualisierung deaktiviert.

**Lösung, in dieser Reihenfolge (alles in der PowerShell):**

1. WSL komplett beenden und aktualisieren, dann Ubuntu neu öffnen:

   ```powershell
   wsl --shutdown
   ```

   ```powershell
   wsl --update
   ```

2. Hilft das nicht: Windows neu starten und Ubuntu erneut öffnen.
3. Bleibt der Fehler, insbesondere mit `0x80370102` oder `WslRegisterDistribution failed`: Virtualisierung im BIOS und die Windows-Funktionen prüfen, beschrieben in [01-windows-vorbereiten.md](01-windows-vorbereiten.md#häufige-stolpersteine).

Weitere WSL-Befehle (`wsl -l -v`, `wsl --status`) in [07-alltag.md](07-alltag.md#wsl-befehle-in-powershell).

## Uhrzeit in Ubuntu falsch

**Symptom.** Nach dem Standby oder Zuklappen des Laptops zeigt `date` in Ubuntu eine alte Uhrzeit; `apt`, `git` oder HTTPS-Verbindungen melden Zertifikats- oder Zeitfehler.

**Ursache.** Die Uhr der WSL-VM läuft im Standby nicht weiter und wird nicht immer automatisch nachgestellt.

**Lösung.** Uhr aus der Hardware-Uhr (Windows-Zeit) übernehmen:

```bash
sudo hwclock -s
```

Oder WSL neu starten, in der PowerShell:

```powershell
wsl --shutdown
```

## Kein Internet in Ubuntu (Temporary failure in name resolution)

**Symptom.** `sudo apt update`, `curl`, `git pull` oder `ping github.com` melden `Temporary failure in name resolution` oder `Could not resolve host`, während Windows online ist.

**Ursache.** Ubuntu bekommt seine DNS-Einstellungen von WSL über die Datei `/etc/resolv.conf`. Nach einem Netzwechsel oder mit einem VPN kann diese ins Leere zeigen.

**Lösung, in dieser Reihenfolge:**

1. WSL neu starten, in der PowerShell:

   ```powershell
   wsl --shutdown
   ```

   Acht Sekunden warten, Ubuntu neu öffnen, `ping -c 3 github.com` testen. Läuft ein VPN, dieses trennen und den Test wiederholen; funktioniert es dann, liegt es am VPN (Firmen-VPNs erlauben oft nur ihren eigenen DNS-Server).
2. Nachsehen, welchen DNS-Server Ubuntu nutzt:

   ```bash
   cat /etc/resolv.conf
   ```

   Normal ist eine Zeile `nameserver <IP>`; eine Adresse wie `10.255.255.254` oder `172.x.x.1` ist der WSL-Vermittler und in Ordnung.
3. **Letzte Option, nur wenn 1 und 2 nicht helfen: DNS von Hand setzen.** Damit WSL die Datei nicht bei jedem Start neu schreibt, braucht `/etc/wsl.conf` einen zusätzlichen Abschnitt. Das ist eine **maschinenspezifische** Änderung: Sie gehört nicht in `wsl/wsl.conf` im Repo, und `install.sh` überschreibt sie bei späteren Läufen nicht (Schritt 11 fasst eine `/etc/wsl.conf`, die schon `systemd=true` enthält, nicht mehr an).

   ```bash
   sudo nano /etc/wsl.conf
   ```

   Am Ende ergänzen, speichern (Ctrl + O, Enter), beenden (Ctrl + X):

   ```text
   [network]
   generateResolvConf=false
   ```

   In der PowerShell WSL beenden:

   ```powershell
   wsl --shutdown
   ```

   Ubuntu neu öffnen und die alte Datei durch einen festen DNS-Server ersetzen (hier Cloudflare; `8.8.8.8` für Google geht ebenso):

   ```bash
   sudo rm -f /etc/resolv.conf
   ```

   ```bash
   echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf
   ```

   Rückgängig machen: die zwei Zeilen aus `/etc/wsl.conf` entfernen, `/etc/resolv.conf` löschen, in der PowerShell `wsl --shutdown`.

## Eine Konfigurationsdatei ist keine Verknüpfung mehr

**Symptom.** Änderungen im Repo wirken sich nicht mehr aus, oder `dotfiles && git status` zeigt nichts, obwohl du Einstellungen geändert hast. Typisch bei `~/.claude/settings.json`; es kann aber auch `~/.zshrc`, `~/.gitconfig` oder die VS-Code-Settings treffen.

**Ursache.** Ein Programm hat beim Speichern den Symlink gelöscht und eine echte Datei an dieselbe Stelle geschrieben (Claude Code tut das zum Beispiel, wenn es `~/.claude/settings.json` selbst aktualisiert). Prüfen:

```bash
ls -la ~/.claude/settings.json
```

Steht in der Ausgabe kein `->` mit dem Pfad ins Repo, ist der Link weg.

**Lösung.**

1. Unterschiede ansehen; was du behalten willst, in die Repo-Datei übernehmen:

   ```bash
   diff ~/.claude/settings.json <repo>/claude/settings.json
   ```

2. Neu verlinken, im Repo-Ordner:

   ```bash
   ./install.sh --links-only
   ```

   Die ersetzte Datei wandert nach `~/.dotfiles-backup/<YYYYmmdd-HHMMSS>/.claude/settings.json`; es geht nichts verloren.
3. Übernommene Änderungen committen (`dotfiles && git status`).

Dasselbe Vorgehen gilt für jede andere Datei aus der Verknüpfungstabelle in [02-installation.md](02-installation.md#was-mit-bestehenden-dateien-passiert-schritt-10). Hintergrund in der README unter [Symlink-Falle](../README.md#symlink-falle).

## Alles zurücksetzen

**Sanft: einzelne Dateien aus dem Backup zurückholen.** Alles, was der Installer ersetzt hat, liegt mit derselben Pfadstruktur in `~/.dotfiles-backup/<YYYYmmdd-HHMMSS>/`. Beispiel für die zshrc: Ordner nachschauen, Symlink entfernen, Backup zurückkopieren.

```bash
ls ~/.dotfiles-backup/
```

```bash
rm ~/.zshrc
```

```bash
cp -a ~/.dotfiles-backup/<YYYYmmdd-HHMMSS>/.zshrc ~/.zshrc
```

Willst du später doch wieder die Repo-Version, genügt `./install.sh --links-only`. Der Installer darf jederzeit erneut laufen (er ist idempotent), auch komplett mit `./install.sh`; er repariert dabei Links und installiert Fehlendes nach.

**Hart: Ubuntu komplett neu aufsetzen.** Wenn gar nichts mehr geht oder du mit einer sauberen Distribution neu anfangen willst. ⚠️ `wsl --unregister` löscht **alle** Dateien in Ubuntu, auch `~/code`. Deshalb zuerst alles auf GitHub pushen und die Distribution exportieren ([07-alltag.md](07-alltag.md#backup-strategie)). Alles in der PowerShell; heisst deine Distribution nur `Ubuntu`, ersetze den Namen (`wsl -l -v` zeigt ihn):

```powershell
wsl --shutdown
```

```powershell
wsl --export Ubuntu-24.04 D:\backup\ubuntu.tar
```

```powershell
wsl --unregister Ubuntu-24.04
```

```powershell
wsl --install -d Ubuntu-24.04
```

Danach wie beim ersten Mal: Benutzer anlegen nach [01-windows-vorbereiten.md, Schritt 2](01-windows-vorbereiten.md#2-ubuntu-öffnen-und-benutzer-anlegen), dann [02-installation.md](02-installation.md) von Anfang an. Aus dem Export lässt sich mit `wsl --import` jederzeit eine zweite Distribution anlegen, um einzelne Dateien zurückzuholen ([07-alltag.md](07-alltag.md#wsl-befehle-in-powershell)).
