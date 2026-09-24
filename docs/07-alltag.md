# Alltag: Shell, Windows und WSL, Docker, Updates, Backup

Alles, was du nach der Installation täglich brauchst – kurz und mit den Kürzeln, die die dotfiles mitbringen.

## Terminal-Bedienung

> 💡 **Für Einsteiger:** Die Zeile, in die du tippst, heisst *Prompt*. Bei uns zeigt sie (Theme `robbyrussell`)
> einen Pfeil, den aktuellen Ordner und – in einem Git-Repo – den Branch. Rechts steht die aktive Python-Version,
> z. B. `[🐍 3.12.3]`. Der Pfeil wird rot, wenn der letzte Befehl fehlgeschlagen ist. Tilde `~` steht für dein
> Home-Verzeichnis `/home/<name>`.

| Taste | Was passiert |
|---|---|
| `Tab` | Befehl, Dateiname oder Option vervollständigen; zweimal `Tab` zeigt alle Möglichkeiten |
| `→` oder `End` | grauen Vorschlag (zsh-autosuggestions) komplett übernehmen |
| `Ctrl+→` | nur das nächste Wort des Vorschlags übernehmen / ein Wort nach rechts springen |
| `Ctrl+←` | ein Wort nach links springen |
| `↑` / `↓` | durch die History blättern; erst etwas tippen, dann `↑` zeigt nur Befehle, die das Getippte enthalten |
| `Ctrl+R` | rückwärts in der History suchen: tippen, mit `Ctrl+R` zum nächsten Treffer, `Enter` ausführen, `Ctrl+G` abbrechen |
| `Ctrl+A` / `Ctrl+E` | an den Zeilenanfang / ans Zeilenende |
| `Ctrl+U` | ganze Zeile löschen |
| `Ctrl+W` | Wort links vom Cursor löschen |
| `Ctrl+K` | alles rechts vom Cursor löschen |
| `Ctrl+L` | Bildschirm leeren (wie `clear`) |
| `Ctrl+C` | laufenden Befehl abbrechen |
| `Ctrl+D` | Shell beenden (Terminal schliessen) |
| `q` | `less` verlassen – z. B. bei `git log`, `git diff`, `man` |
| `Ctrl+Shift+C` / `Ctrl+Shift+V` | Windows Terminal: kopieren / einfügen (`Ctrl+C` kopiert ebenfalls, wenn Text markiert ist; `Ctrl+V` fügt ein) |
| `Ctrl+Shift+T` / `Ctrl+Tab` | Windows Terminal: neuer Tab / nächster Tab |
| `Alt+Shift+D` | Windows Terminal: Fenster teilen (zweites Terminal daneben) |
| `Ctrl+Shift+F` | Windows Terminal: im Terminal-Text suchen |

Die History speichert 50'000 Befehle und teilt sie sofort zwischen allen offenen Terminals (`zsh/zshrc`). Ein Befehl mit
einem Leerzeichen davor wird nicht gespeichert – praktisch, wenn ein Token in der Zeile steht. `!!` wiederholt den
letzten Befehl, `sudo !!` wiederholt ihn mit sudo.

Weitere Helfer aus den oh-my-zsh-Plugins in `zsh/zshrc`:

- **last-working-dir:** Ein neues Terminal startet im Ordner, in dem du zuletzt warst; `lwd` springt dorthin.
- **common-aliases:** `cp` und `mv` fragen vor dem Überschreiben nach (`-i`); `rm` fragt bei uns absichtlich nicht.
  Globale Kürzel am Zeilenende: `G` = `| grep`, `L` = `| less`, `H` = `| head`, `T` = `| tail` – z. B. `ls G csv`.
- **zsh-syntax-highlighting:** Ein grüner Befehl existiert, ein roter nicht – du siehst Tippfehler vor dem Enter.

## oh-my-zsh-Git-Kürzel

Das Plugin `git` definiert über hundert Kürzel. Diese brauchst du wirklich:

| Kürzel | Befehl |
|---|---|
| `gst` | `git status` |
| `ga <datei>` / `gaa` | `git add <datei>` / `git add --all` |
| `gcmsg "text"` | `git commit --message "text"` |
| `gp` / `gl` | `git push` / `git pull` |
| `gco <branch>` / `gcb <name>` | Branch wechseln / neuen Branch anlegen und wechseln |
| `gsw <branch>` / `gswc <name>` | dasselbe mit `git switch` |
| `gd` / `gds` | Diff der Arbeitskopie / des Staging-Bereichs |
| `glog` | `git log --oneline --decorate --graph` |
| `glola` | Graph aller Branches mit Autor und Zeit |
| `gcm` | auf `main` wechseln |
| `gsta` / `gstp` | Änderungen parken / zurückholen |

Die vollständige Liste zeigt `alias | grep '^g'`; unsere eigenen Git-Aliasse (`git st`, `git lg`, `git sweep`, ...)
stehen in [docs/06-git-github.md](06-git-github.md).

## Unsere Aliasse (zsh/aliases)

| Alias | Steht für | Wofür |
|---|---|---|
| `myip` | `curl https://ipinfo.io/json` | öffentliche IP-Adresse samt Standort |
| `speedtest` | speedtest-cli per `python3 -` | Internet-Geschwindigkeit messen |
| `ll` | lange Dateiliste mit lesbaren Grössen | Ordnerinhalt ansehen |
| `la` | wie `ll`, zusätzlich versteckte Dateien | auch `.gitignore`, `.env` usw. sehen |
| `..` / `...` | `cd ..` / `cd ../..` | ein / zwei Ordner nach oben |
| `py` | `python3` | kurz für Python |
| `venv` | `uv venv` | virtuelle Umgebung `.venv` im aktuellen Ordner anlegen |
| `ur` | `uv run` | Befehl in der Projektumgebung ausführen, z. B. `ur python main.py` |
| `rf` | `ruff format . && ruff check --fix .` | Code formatieren und automatisch korrigieren |
| `pt` | `uv run pytest` | Tests ausführen |
| `gundo` | `git reset --soft HEAD~1` | letzten Commit zurücknehmen, Änderungen bleiben gestaged |
| `glast` | `git log -1 HEAD --stat` | letzten Commit mit geänderten Dateien anzeigen |
| `gsweep` | `git sweep` (Alias aus `git/gitconfig`, siehe [docs/06](06-git-github.md)) | gemergte Branches lokal löschen |
| `dotfiles` | `cd` ins dotfiles-Repo (findet es über den Symlink `~/.zshrc`) | Einstellungen committen |
| `dotfiles-update` | `git pull --ff-only` im Repo, dann `./install.sh --links-only -y` | Stand eines anderen Rechners nachziehen |
| `cc` | `claude` | Claude Code starten |
| `ccc` | `claude --continue` | letzte Claude-Code-Sitzung in diesem Ordner fortsetzen |
| `cx` | `codex` | OpenAI Codex CLI starten |

`cc` überdeckt den C-Compiler; wenn du ihn je brauchst: `command cc` oder `gcc`.

Bedingte Aliasse aus `zsh/zshrc` (nur gesetzt, wenn das Programm da ist): `open` = `explorer.exe`, `pbcopy` =
`clip.exe`, `fd` = `fdfind` und `bat` = `batcat` (Ubuntu nennt die beiden Pakete `fd-find` und `bat` anders als das
Original). Weitere Werkzeuge aus `packages/apt.txt`: `rg` (ripgrep, sehr schnelles grep), `htop`, `tree`, `jq`, `tmux`.

Maschinenspezifische Aliasse (z. B. `alias hslu='cd "$HOME/code/GitLab HSLU"'`) gehören in `~/.zshrc.local`, nicht
ins Repo – Vorlage: `zsh/zshrc.local.example`. Nach Änderungen an zshrc oder Aliassen: `exec zsh`.

## Update-Routine: update-all

`update-all` ist eine Funktion in `zsh/zshrc`. Einmal pro Woche reicht:

```bash
update-all
```

Was passiert, in dieser Reihenfolge:

| Schritt | Befehle | Hinweis |
|---|---|---|
| Ubuntu-Pakete | `sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get autoremove -y` | fragt einmal nach deinem sudo-Passwort |
| uv und uv-Tools | `uv self update`, `uv tool upgrade --all` | aktualisiert auch ruff und pre-commit |
| Claude Code | `claude update` | nur wenn `claude` installiert ist |
| Codex CLI | `curl -fsSL https://chatgpt.com/codex/install.sh \| CODEX_NON_INTERACTIVE=1 sh` | nur wenn `codex` installiert ist; der Installer ist gleichzeitig der Updater, `CODEX_NON_INTERACTIVE=1` verhindert seine Rückfrage „Start Codex now?" |
| oh-my-zsh | `omz update` | läuft zuletzt, weil oh-my-zsh die Shell bei Änderungen neu startet |

Nicht enthalten, weil selten nötig oder anderswo geregelt:

| Was | Wie |
|---|---|
| pyenv selbst | `git -C "$(pyenv root)" pull` (pyenv ist ein Git-Checkout) |
| Neue Python-Version | `pyenv install 3.13`, danach bei Bedarf `pyenv global 3.13` |
| Node.js (nvm) | `nvm install --lts` und `nvm alias default 'lts/*'` |
| VS Code und Extensions | aktualisieren sich selbst (Windows-Seite) |
| Windows-Programme (Terminal, VS Code, Docker Desktop, Claude-App, ...) | PowerShell: `winget upgrade --all` |
| WSL selbst | PowerShell: `wsl --update` |
| Die dotfiles | `dotfiles-update` (holt Änderungen und setzt Symlinks nach) |

## Dateien: Windows <-> WSL

Zwei Welten, zwei Dateisysteme. Faustregel: **Projekte immer ins Linux-Home** (`~/code/...`). Dort sind Git, uv und
VS Code schnell; auf `/mnt/c` ist jeder Dateizugriff ein Umweg über Windows und spürbar langsamer.

| Von | Nach | So |
|---|---|---|
| WSL | Windows-Explorer im aktuellen Ordner öffnen | `explorer.exe .` (Alias: `open .`) |
| Windows-Explorer | Linux-Home ansehen | Adressleiste: `\\wsl.localhost\Ubuntu-24.04\home\<name>` – oder links im Explorer der Eintrag „Linux" |
| WSL | Windows-Laufwerke | `/mnt/c/Users/<Windows-Name>/Downloads`, `/mnt/d/...` |
| WSL | Pfad umrechnen | `wslpath -w ~/code` (Linux -> Windows), `wslpath -u 'C:\Users'` (Windows -> Linux) |

Eine heruntergeladene Datei ins Projekt holen:

```bash
cp /mnt/c/Users/<Windows-Name>/Downloads/daten.csv ~/code/mein-projekt/data/
```

Der Distributionsname steckt im Explorer-Pfad: Nach `wsl --install -d Ubuntu-24.04` heisst er `Ubuntu-24.04`; eine
älter installierte Distribution heisst oft nur `Ubuntu`. Nachsehen in PowerShell mit `wsl -l -v`.

> 💡 **Für Einsteiger:** Bearbeite Dateien im Linux-Home nie mit Windows-Programmen direkt über den
> `\\wsl.localhost`-Pfad, wenn es auch anders geht – VS Code mit `code .` aus Ubuntu ist der richtige Weg. Und
> Zeilenenden: Windows-Editoren erzeugen CRLF, Linux erwartet LF; unsere Git-Konfiguration (`core.autocrlf = input`)
> und die `.editorconfig` fangen das ab.

## Windows-Programme aus WSL

Weil `appendWindowsPath=true` in `/etc/wsl.conf` steht, kannst du Windows-Programme direkt aufrufen – die Endung
`.exe` ist Pflicht (Ausnahme `code`, das bringt ein eigenes Startskript mit):

| Befehl | Wirkung |
|---|---|
| `code .` | VS Code auf Windows öffnet den Ordner im WSL-Remote-Modus |
| `explorer.exe .` | Windows-Explorer im aktuellen Ordner |
| `cat datei.txt \| clip.exe` | Inhalt in die Windows-Zwischenablage (Alias `pbcopy`) |
| `notepad.exe datei.txt` | Datei in Notepad öffnen |
| `powershell.exe -c "Get-Date"` | PowerShell-Befehl ausführen |
| `cmd.exe /C dir` | CMD-Befehl ausführen |
| `wslview https://github.com` | URL oder Datei mit dem Windows-Standardprogramm öffnen – braucht das Paket `wslu` (`sudo apt install wslu`, nicht in `packages/apt.txt`) |
| `wsl.exe --shutdown` | funktioniert auch von innen – beendet aber sofort dein eigenes Terminal |

Umgekehrt in PowerShell: `wsl ls -la` führt einen Linux-Befehl im aktuellen Windows-Ordner aus, `wsl ~` öffnet
Ubuntu im Linux-Home.

## Docker Desktop

In WSL gibt es keinen eigenen Docker-Dienst. `docker` kommt von **Docker Desktop** auf Windows, das seine Befehle in
die Ubuntu-Distribution einblendet. Daraus folgt: `docker` funktioniert nur, solange Docker Desktop läuft.

**Einrichten (einmalig):**

1. Docker Desktop starten (Startmenü). Optional in Settings -> General „Start Docker Desktop when you sign in to your
   computer" aktivieren.
2. Settings -> General: „Use the WSL 2 based engine" muss aktiv sein.
3. Settings -> Resources -> WSL integration: den Schalter für `Ubuntu-24.04` einschalten, „Apply".
4. Neues Ubuntu-Terminal öffnen und testen:

   ```bash
   docker run hello-world
   ```

Danach wie gewohnt: `docker ps`, `docker compose up`, `docker system prune` (räumt gestoppte Container und
ungenutzte Images weg). In VS Code helfen die Extensions `ms-azuretools.vscode-docker` und
`ms-azuretools.vscode-containers` aus unserer Liste.

**Die `_docker`-Meldung beim Start der Shell.** Docker Desktop legt in Ubuntu einen Symlink
`/usr/share/zsh/vendor-completions/_docker` an, der auf `/mnt/wsl/docker-desktop/...` zeigt. Läuft Docker Desktop
nicht, existiert das Ziel nicht, und zsh meldet beim Start
`compinit: no such file or directory: /usr/share/zsh/vendor-completions/_docker`. Das ist harmlos – Docker Desktop
starten (oder die Meldung ignorieren), danach `exec zsh`.

Docker Desktop läuft als eigene WSL-Distribution (`docker-desktop` in `wsl -l -v`) und teilt sich RAM und CPU mit
Ubuntu innerhalb der Grenzen aus `.wslconfig`. `wsl --shutdown` beendet deshalb auch Docker.

## WSL-Befehle in PowerShell

Alle Befehle in **PowerShell** (oder CMD) auf der Windows-Seite. `<Distro>` ist der Name aus `wsl -l -v`
(z. B. `Ubuntu-24.04`).

| Befehl | Wirkung |
|---|---|
| `wsl -l -v` | installierte Distributionen mit Status (Running/Stopped) und WSL-Version |
| `wsl --list --running` | nur die laufenden |
| `wsl --status` | Standard-Distribution, Kernel-Version |
| `wsl --version` | Version von WSL und seinen Komponenten |
| `wsl --update` | WSL aktualisieren |
| `wsl --shutdown` | alle Distributionen und die WSL-VM sofort beenden – nötig nach Änderungen an `.wslconfig` oder `/etc/wsl.conf` |
| `wsl --terminate <Distro>` | nur eine Distribution beenden |
| `wsl -d <Distro>` | bestimmte Distribution starten |
| `wsl -d <Distro> -u root` | als root starten, z. B. um ein vergessenes Passwort zu setzen (`passwd <name>`) |
| `wsl --set-default <Distro>` | Standard-Distribution setzen (die `wsl` ohne `-d` startet) |
| `wsl --export <Distro> <Datei.tar>` | Distribution als Archiv sichern (siehe Backup) |
| `wsl --import <Distro> <Installationsordner> <Datei.tar>` | Archiv als (neue) Distribution einspielen |
| `wsl --manage <Distro> --set-sparse true` | virtuelle Festplatte gibt gelöschten Platz an Windows zurück |
| `wsl --unregister <Distro>` | ⚠️ Distribution samt allen Daten löschen – nur nach Export oder für einen Neuanfang |

**8-Sekunden-Regel:** Änderungen an `.wslconfig` oder `/etc/wsl.conf` greifen erst, wenn WSL vollständig beendet
war. Nach `wsl --shutdown` etwa acht Sekunden warten, dann Ubuntu neu öffnen.

## Ressourcen: .wslconfig

`C:\Users\<Windows-Name>\.wslconfig` begrenzt, wie viel RAM und wie viele CPU-Kerne die WSL-VM (und damit Ubuntu plus
Docker) bekommen darf. Ohne Datei nimmt WSL die Hälfte des RAM und alle Kerne. `windows/setup.ps1` legt die Datei
aus `windows/wslconfig.example` an und setzt die Hälfte von RAM und Kernen ein; du kannst sie jederzeit anpassen:

```
[wsl2]
memory=52GB
processors=16
swap=16GB
```

Das sind Elias' Werte auf einem Rechner mit 64 GB RAM. Nach jeder Änderung `wsl --shutdown`, acht Sekunden warten,
Ubuntu neu öffnen – dann in Ubuntu kontrollieren:

```bash
nproc && free -h
```

Windows 11 bringt dafür auch eine grafische App mit: Startmenü -> „WSL Settings". Wächst die virtuelle Festplatte
von Ubuntu, obwohl du Dateien gelöscht hast, hilft `wsl --manage Ubuntu-24.04 --set-sparse true` (einmalig, bei
beendeter Distribution). Den belegten Platz aus Ubuntu-Sicht zeigt `df -h /`.

## Backup-Strategie

Der beste Schutz ist, dass sich alles aus zwei Quellen wiederherstellen lässt: **GitHub** (Code) und **dieses Repo**
(Umgebung). Ein WSL-Export deckt den Rest ab.

| Was | Wohin | Wie oft |
|---|---|---|
| Projektcode | GitHub – jedes Projekt ein Repo, regelmässig `git push` | täglich |
| Umgebung (Shell, Git, VS Code, Claude, Codex) | dieses dotfiles-Repo, `dotfiles && git push` | bei jeder Änderung |
| Maschinenspezifisches ausserhalb des Repos: `~/.gitconfig.local`, `~/.zshrc.local`, `~/.ssh`, `~/.claude.json`, `~/.codex` | steckt im WSL-Export; SSH-Passphrase und Logins zusätzlich im Passwort-Manager | monatlich |
| Grosse Daten (Rohdaten, Modelle) | nicht in Git – OneDrive/externe Platte, Pfad im README des Projekts notieren | nach Bedarf |
| Ganze Ubuntu-Distribution | `wsl --export` auf eine zweite Platte | monatlich |

**Export (PowerShell):** Zuerst Ubuntu sauber beenden, dann exportieren – die Datei wird schnell mehrere Dutzend GB
gross, also auf eine Platte mit Platz:

```powershell
wsl --terminate Ubuntu-24.04
```

```powershell
wsl --export Ubuntu-24.04 D:\backup\ubuntu-2026-09.tar
```

**Wiederherstellen (PowerShell):** auf dem alten oder einem neuen Rechner mit installiertem WSL:

```powershell
wsl --import Ubuntu-24.04 D:\WSL\Ubuntu-24.04 D:\backup\ubuntu-2026-09.tar
```

Der zweite Pfad ist der Ordner, in dem die virtuelle Festplatte liegen soll. Importierte Distributionen haben kein
Startmenü-Programm; du startest sie mit `wsl -d Ubuntu-24.04` und setzt sie bei Bedarf mit `wsl --set-default
Ubuntu-24.04` als Standard. Der Standardbenutzer kommt aus `/etc/wsl.conf` (`[user] default=...`) – das hat
install.sh gesetzt, deshalb landest du nach dem Import direkt wieder in deinem Konto.

**Die Alternative zum Export:** Ein frischer Aufbau nach [docs/01-windows-vorbereiten.md](01-windows-vorbereiten.md)
und [docs/02-installation.md](02-installation.md) dauert 10–20 Minuten, danach `gh repo clone` für jedes Projekt und
`uv sync` darin. Wenn das zuverlässig klappt, ist das Repo dein eigentliches Backup – der Export ist nur die
Abkürzung für Dinge, die du noch nicht ins Repo aufgenommen hast.

**Monatliche Checkliste:**

- [ ] `gh repo list Elias-Martinelli` – gibt es lokale Projekte in `~/code`, die noch kein Repo haben?
- [ ] In jedem Projekt `git status` – alles committet und gepusht?
- [ ] `dotfiles && git status` – Änderungen an der Umgebung gepusht?
- [ ] `update-all` gelaufen, `wsl --update` in PowerShell?
- [ ] `wsl --export` auf die Backup-Platte, alte Exporte löschen.
