# Git und GitHub

Git verwaltet die Geschichte deines Codes, GitHub bewahrt sie online auf. Die dotfiles bringen eine fertige
Git-Konfiguration (`git/gitconfig`), die GitHub-Kommandozeile `gh` und eine SSH-Konfiguration mit. Diese Seite
erklärt, was davon bereits läuft, wie du dich anmeldest und wie der Alltag mit Git aussieht.

## Git in 10 Zeilen

> 💡 **Für Einsteiger:** Wenn du Git noch nie benutzt hast, reichen diese zehn Begriffe für den Anfang.

1. Ein **Repository** (kurz *Repo*) ist ein Projektordner, dessen Änderungen Git aufzeichnet.
2. `git init` macht aus einem Ordner ein Repo; `git clone <url>` holt ein bestehendes Repo auf deinen Rechner.
3. Ein **Commit** ist ein gespeicherter Zwischenstand mit Beschreibung – wie ein Speicherpunkt im Spiel.
4. Vor dem Commit wählst du mit `git add <datei>` aus, was hinein soll (**Staging**); `git status` zeigt den Stand.
5. `git commit -m "Beschreibung"` legt den Commit an. Viele kleine Commits sind besser als ein grosser.
6. Ein **Branch** ist ein Seitenzweig, in dem du etwas ausprobierst, ohne `main` zu stören.
7. **origin** ist der Name des Online-Repos auf GitHub; `git push` schickt Commits hin, `git pull` holt neue ab.
8. Ein **Pull Request** (PR) ist die Bitte, einen Branch in `main` zu übernehmen – mit Diskussion und Review.
9. Die Datei `.gitignore` listet, was Git ignorieren soll (Umgebungen, Passwörter, Zwischendateien).
10. Nichts ist verloren, solange es einmal committet war: `git log` zeigt die Geschichte, `git restore` holt zurück.

## Was schon eingerichtet ist

| Datei | Was drin steht |
|---|---|
| `~/.gitconfig` -> `git/gitconfig` (Symlink) | Farben, Aliasse, Standardverhalten – für alle Rechner gleich |
| `~/.gitconfig.local` (Kopie von `git/gitconfig.local.example`, nicht im Repo) | Dein Name und deine E-Mail |
| `~/.ssh/config` -> `ssh/config` (Symlink) | GitHub über `~/.ssh/id_ed25519`, Schlüssel landen im ssh-agent |
| `gh` (GitHub CLI, aus `packages/apt.txt`) | Login, Repos anlegen, Pull Requests – alles vom Terminal |

Die wichtigsten Einstellungen aus `git/gitconfig` und warum sie so gesetzt sind:

| Einstellung | Wirkung |
|---|---|
| `init.defaultBranch = main` | Neue Repos starten mit dem Branch `main` (GitHub-Standard) statt `master` |
| `push.autoSetupRemote = true` | Der erste `git push` eines neuen Branchs funktioniert ohne `--set-upstream` |
| `push.default = simple` | `git push` schickt nur den aktuellen Branch |
| `pull.rebase = false` | `git pull` mergt statt zu rebasen – vorhersehbar für Einsteiger |
| `fetch.prune = true` | Auf GitHub gelöschte Branches verschwinden auch lokal aus `origin/...` |
| `merge.conflictstyle = zdiff3` | Konfliktmarker zeigen zusätzlich den gemeinsamen Ursprung. Braucht Git ab 2.35 (Ubuntu 24.04 hat 2.43); unter Ubuntu 22.04 in `~/.gitconfig.local` `diff3` setzen |
| `rerere.enabled = true` | Einmal gelöste Konflikte merkt sich Git und löst sie beim nächsten Mal selbst |
| `diff.colorMoved = default` | Verschobene Zeilen werden im Diff anders eingefärbt als gelöschte/neue |
| `core.editor = code --wait` | Commit-Messages und Rebase-Listen öffnen sich in VS Code |
| `core.pager = less -FRSX` | Kurze Ausgaben direkt im Terminal, lange in `less` (mit `q` beenden) |
| `core.autocrlf = input` | Windows-Zeilenenden (CRLF) werden beim Commit zu LF |
| `help.autocorrect = 1` | `git statsu` wird nach 0,1 Sekunden automatisch als `git status` ausgeführt |

## Identität: Name und E-Mail

install.sh hat `~/.gitconfig.local` aus deinen Antworten erzeugt. Prüfen:

```bash
cat ~/.gitconfig.local
```

Ändern – **nicht** mit `git config --global`, sondern gezielt in der lokalen Datei:

```bash
git config --file ~/.gitconfig.local user.name "Vorname Nachname"
```

```bash
git config --file ~/.gitconfig.local user.email "du@example.com"
```

⚠️ `~/.gitconfig` ist ein Symlink ins dotfiles-Repo. Git schreibt beim Setzen von Werten durch den Symlink
hindurch – `git config --global user.name ...` würde deinen Namen also in `git/gitconfig` und damit ins Repo
schreiben. Genau deshalb ist die Identität in die ignorierte Datei `~/.gitconfig.local` ausgelagert: Das Repo kann
öffentlich werden, und jede Person (du, dein Vater) benutzt dieselben dotfiles mit eigener Identität.

Die E-Mail sollte zu deinem GitHub-Konto gehören, damit GitHub Commits deinem Profil zuordnet (GitHub: Settings ->
Emails; dort gibt es auch eine `noreply`-Adresse, falls du die echte nicht zeigen willst). Kontrolle in einem Repo:

```bash
git config user.email
```

## GitHub-Login mit gh

Ohne Login kann Git nicht auf private Repos zugreifen und nicht pushen. Der Login läuft einmalig über den Browser:

```bash
gh auth login
```

gh stellt nacheinander diese Fragen (mit den Pfeiltasten wählen, Enter bestätigt):

| Frage | Antwort |
|---|---|
| `Where do you use GitHub?` | **GitHub.com** |
| `What is your preferred protocol for Git operations on this host?` | **HTTPS** (SSH geht auch, siehe unten – HTTPS ist der einfachere Start) |
| `Authenticate Git with your GitHub credentials?` | **Yes** – damit fragt Git nie nach einem Passwort |
| `How would you like to authenticate GitHub CLI?` | **Login with a web browser** |

Dann zeigt gh `First copy your one-time code: XXXX-XXXX`. Merk dir den Code, drück Enter – der Browser öffnet sich
auf der GitHub-Seite zur Geräteanmeldung. Falls kein Browser aufgeht (unter WSL kommt das vor), öffne
<https://github.com/login/device> von Hand in Windows. Code eingeben, „Authorize github" bestätigen. Zurück im
Terminal steht `Logged in as <dein-name>`. Prüfen:

```bash
gh auth status
```

### Credential-Helper: warum Git nicht nach dem Passwort fragt

Mit **Yes** bei „Authenticate Git with your GitHub credentials?" trägt gh sich als *Credential-Helper* ein: Git holt
sich das Zugangs-Token bei jedem Push von gh, statt dich zu fragen. Nachträglich geht das auch mit:

```bash
gh auth setup-git
```

Dabei schreibt gh einen Block `[credential "https://github.com"]` mit `helper = !/usr/bin/gh auth git-credential`
per `git config --global` – also durch den Symlink in `git/gitconfig`. Das ist unkritisch (es steht kein Token
darin, nur der Verweis auf gh), aber `dotfiles && git status` zeigt danach eine Änderung. Du hast zwei Möglichkeiten:

- **Committen.** Auf jedem Rechner mit gh aus apt stimmt der Pfad `/usr/bin/gh`. Einfachste Variante.
- **Lokal halten.** Den Helper stattdessen in `~/.gitconfig.local` eintragen und die Repo-Datei zurücksetzen:

  ```bash
  GIT_CONFIG_GLOBAL="$HOME/.gitconfig.local" gh auth setup-git
  ```

  ```bash
  dotfiles && git checkout -- git/gitconfig
  ```

  `GIT_CONFIG_GLOBAL` lenkt für diesen einen Befehl die „globale" Git-Konfiguration auf die lokale Datei um.

## SSH-Schlüssel (optional)

Mit HTTPS und gh bist du komplett arbeitsfähig. SSH brauchst du, wenn du `git@github.com:...`-URLs bevorzugst,
auf Server zugreifst oder Repos ohne gh klonen willst. Unsere `ssh/config` ist dafür vorbereitet:

```
Host github.com
  User git
  IdentityFile ~/.ssh/id_ed25519
  AddKeysToAgent yes
  IdentitiesOnly yes
```

**1. Prüfen, ob schon ein Schlüssel existiert**

```bash
ls -la ~/.ssh
```

Gibt es `id_ed25519` und `id_ed25519.pub`, springe zu Schritt 3.

**2. Schlüssel erzeugen**

```bash
ssh-keygen -t ed25519 -C "du@example.com"
```

Die Frage nach dem Speicherort mit Enter bestätigen (Standard `~/.ssh/id_ed25519`). Eine Passphrase ist empfohlen:
Sie schützt den Schlüssel, falls jemand an deine Dateien kommt. Dank `AddKeysToAgent yes` und dem
oh-my-zsh-Plugin `ssh-agent` (in `zsh/zshrc`) musst du sie pro Sitzung nur einmal eingeben.

> 💡 **Für Einsteiger:** Es entstehen zwei Dateien. `id_ed25519` ist der **private** Schlüssel – der bleibt auf
> deinem Rechner und wird nie verschickt, kopiert oder ins Repo gelegt. `id_ed25519.pub` ist der **öffentliche**
> Schlüssel; den darf GitHub bekommen.

**3. Öffentlichen Schlüssel bei GitHub hinterlegen**

```bash
gh ssh-key add ~/.ssh/id_ed25519.pub --title "WSL Laptop"
```

Meldet gh fehlende Berechtigungen (`insufficient OAuth scopes`), hol sie nach und wiederhole den Befehl:

```bash
gh auth refresh -h github.com -s admin:public_key
```

Alternativ im Browser: GitHub -> Settings -> SSH and GPG keys -> New SSH key, Inhalt von `~/.ssh/id_ed25519.pub`
einfügen (`cat ~/.ssh/id_ed25519.pub | clip.exe` kopiert ihn in die Windows-Zwischenablage).

**4. Verbindung testen**

```bash
ssh -T git@github.com
```

Beim ersten Mal fragt SSH `Are you sure you want to continue connecting (yes/no)?` – mit `yes` antworten. Erwartete
Antwort: `Hi <dein-name>! You've successfully authenticated, but GitHub does not provide shell access.`

**5. gh und bestehende Repos auf SSH umstellen (nur wenn gewünscht)**

```bash
gh config set git_protocol ssh --host github.com
```

Ab jetzt klont `gh repo clone` per SSH. Ein vorhandenes Repo umstellen:

```bash
git remote set-url origin git@github.com:Elias-Martinelli/mein-projekt.git
```

## Unsere Git-Aliasse

Aliasse aus `git/gitconfig` – sie funktionieren in jeder Shell als `git <alias>`:

| Alias | Befehl | Wofür |
|---|---|---|
| `git co` | `checkout` | Branch oder Datei auschecken |
| `git st` | `status -sb` | kompakter Status mit Branch-Zeile |
| `git br` | `branch` | Branches anzeigen |
| `git ci` | `commit` | committen |
| `git fo` | `fetch origin` | Stand von GitHub holen, ohne zu mergen |
| `git d` | `!git --no-pager diff` | Diff direkt im Terminal (ohne `less`) |
| `git dt` | `difftool` | Diff im externen Werkzeug |
| `git stat` | `!git --no-pager diff --stat` | nur die Statistik: welche Dateien, wie viele Zeilen |
| `git remoteSetHead` | `remote set-head origin --auto` | `origin/HEAD` auf den Standard-Branch des Remotes setzen |
| `git defaultBranch` | Name des Standard-Branchs (`main`) | Baustein für `sweep` und `m` |
| `git sweep` | löscht lokale Branches, die schon in `main` gemergt sind, und räumt `origin/...` auf | nach gemergten PRs |
| `git lg` | farbiger Graph aller Branches | Überblick über die Geschichte |
| `git serve` | `git daemon ...` | Repo im lokalen Netz freigeben (selten) |
| `git m` | auf den Standard-Branch wechseln | zurück auf `main` |
| `git unstage <datei>` | `reset HEAD -- <datei>` | Datei aus dem Staging nehmen, Änderung bleibt |

Dazu kommen die Kürzel des oh-my-zsh-Plugins `git` (ohne `git` davor, direkt in zsh). Die nützlichsten:

| Kürzel | Befehl | Kürzel | Befehl |
|---|---|---|---|
| `gst` | `git status` | `gss` | `git status --short` |
| `ga <datei>` | `git add <datei>` | `gaa` | `git add --all` |
| `gcmsg "text"` | `git commit --message "text"` | `gc` | `git commit --verbose` (Editor öffnet sich) |
| `gp` | `git push` | `gl` | `git pull` |
| `gf` | `git fetch` | `gd` | `git diff` |
| `gds` | `git diff --staged` | `glog` | `git log --oneline --decorate --graph` |
| `glola` | Graph aller Branches mit Autor und Zeit | `gb` | `git branch` |
| `gco <branch>` | `git checkout <branch>` | `gcb <name>` | `git checkout -b <name>` (neuer Branch) |
| `gsw <branch>` | `git switch <branch>` | `gswc <name>` | `git switch --create <name>` |
| `gcm` | auf `main` wechseln | `gm <branch>` | `git merge <branch>` |
| `gsta` | `git stash push` (Änderungen parken) | `gstp` | `git stash pop` (zurückholen) |
| `grhh` | `git reset --hard` ⚠️ verwirft alle lokalen Änderungen | `grb <branch>` | `git rebase <branch>` |

Alle Kürzel auflisten: `alias | grep '^g'`.

## Täglicher Ablauf

**Arbeiten auf `main` (kleine, eigene Projekte):**

```bash
git status
```

```bash
git add -A
```

```bash
git commit -m "feat: einlesen der rohdaten als parquet"
```

```bash
git push
```

Für Commit-Messages nutzen wir die Präfixe aus `claude/CLAUDE.md`, damit die Geschichte lesbar bleibt:

| Präfix | Wann |
|---|---|
| `feat:` | neue Funktion |
| `fix:` | Fehlerbehebung |
| `docs:` | nur Dokumentation |
| `refactor:` | Umbau ohne Verhaltensänderung |
| `test:` | Tests |
| `chore:` | Wartung: Abhängigkeiten, Konfiguration, Aufräumen |

**Arbeiten mit Branch und Pull Request (Teamarbeit, grössere Änderungen):**

1. Branch anlegen und wechseln:

   ```bash
   git switch -c feature/datenbereinigung
   ```

2. Committen wie oben. Dann pushen – dank `push.autoSetupRemote` reicht:

   ```bash
   git push
   ```

3. Pull Request anlegen (Titel und Text aus den Commits) oder mit `--web` im Browser ausfüllen:

   ```bash
   gh pr create --fill
   ```

4. Status und Checks im Blick behalten: `gh pr view --web` öffnet den PR im Browser, `gh pr checks` zeigt die CI.

5. Mergen und den Branch lokal wie auf GitHub löschen:

   ```bash
   gh pr merge --squash --delete-branch
   ```

6. Zurück auf `main`, aktualisieren, aufräumen:

   ```bash
   git m && git pull && git sweep
   ```

Fremde PRs ansehen: `gh pr list`, dann `gh pr checkout 12` holt den Branch des PRs Nummer 12 auf deinen Rechner.

**Wenn etwas schiefgeht:**

| Problem | Lösung |
|---|---|
| Datei geändert, will zurück zum letzten Commit | `git restore <datei>` |
| Datei versehentlich mit `git add` gestaged | `git unstage <datei>` |
| Commit-Message falsch (noch nicht gepusht) | `git commit --amend` |
| Letzten Commit zurücknehmen, Änderungen behalten (noch nicht gepusht) | `git reset --soft HEAD~1` |
| Was habe ich zuletzt gemacht? | `glog` oder `git lg` |
| Änderungen kurz parken, Branch wechseln, zurückholen | `gsta`, `gsw main`, ..., `gstp` |
| Konflikt beim Merge/Pull | Datei öffnen, Marker `<<<<<<<`/`|||||||`/`=======`/`>>>>>>>` auflösen, `git add`, `git commit` |

Auf `main` nie `git push --force` – das steht auch so in `claude/CLAUDE.md`.

## Neues Repo anlegen

**Weg 1 – lokal beginnen, dann auf GitHub.** Nach `uv init` (siehe [docs/03-python.md](03-python.md)) oder
`git init` und dem ersten Commit:

```bash
gh repo create mein-projekt --private --source=. --push
```

Das erstellt das Repo `Elias-Martinelli/mein-projekt` auf GitHub, trägt es als `origin` ein und pusht. Für ein
öffentliches Repo `--public` statt `--private`. Sichtbarkeit später ändern: `gh browse --settings` öffnet die
Repo-Einstellungen im Browser.

**Weg 2 – auf GitHub beginnen, dann klonen.**

```bash
gh repo create mein-projekt --private --clone --gitignore Python --add-readme
```

Danach `cd mein-projekt`. `--gitignore Python` nimmt die Python-Vorlage von GitHub.

**Bestehendes Repo holen:**

```bash
gh repo clone Elias-Martinelli/deng ~/code/Elias-Martinelli/deng
```

`gh repo list Elias-Martinelli` zeigt alle deine Repos.

## .gitignore für Python

`uv init` legt eine passende `.gitignore` an. Für Projekte ohne uv holst du dir die GitHub-Vorlage:

```bash
gh repo gitignore view Python > .gitignore
```

(Quelle: <https://github.com/github/gitignore/blob/main/Python.gitignore>.) Wichtig ist, dass darin stehen:
`.venv/`, `__pycache__/`, `.env`, `.ipynb_checkpoints`. Ergänze projektspezifisch grosse Datenordner (`data/raw/`)
und Modelle (`*.pkl`, `*.pt`) – Dateien über 100 MB nimmt GitHub nicht an. Geheimnisse (API-Keys, Passwörter) gehören
in eine `.env`- oder `.envrc`-Datei (direnv), niemals in den Code.

## init.defaultBranch = main

Neue Repos starten bei uns mit dem Branch `main`, so wie GitHub es seit 2020 vorgibt (die alte dotfiles-Version
hatte noch `master`). Bestehende Repos mit `master` funktionieren unverändert weiter. Umbenennen, falls du willst:

```bash
git branch -m master main
```

```bash
git push -u origin main
```

```bash
gh repo edit --default-branch main
```

```bash
git push origin --delete master
```

Zum Schluss `git remoteSetHead`, damit `origin/HEAD` (und damit `git defaultBranch`, `git sweep`, `git m`) auf
`main` zeigt.

## Umgang mit dem dotfiles-Repo selbst

Das Repo liegt bei dir unter `~/code/Elias-Martinelli/dotfiles` (Einsteiger: `~/code/dotfiles`); der Alias
`dotfiles` wechselt hinein, egal wo es liegt. Weil alle Konfigurationsdateien Symlinks ins Repo sind, landet jede
Änderung an `~/.zshrc`, `~/.gitconfig` oder `~/.claude/CLAUDE.md` direkt dort:

```bash
dotfiles && git status
```

```bash
git add -A && git commit -m "chore: alias fuer notebooks ergaenzt" && git push
```

Auf einem zweiten Rechner holst du den Stand mit `dotfiles-update` (macht `git pull --ff-only` und
`./install.sh --links-only -y`).

**Erstes Hochladen.** Solange es `Elias-Martinelli/dotfiles` auf GitHub noch nicht gibt, legst du es aus dem
Repo-Ordner heraus an – privat, mit der Option, es später öffentlich zu machen (dann funktioniert auch der
bootstrap-Einzeiler aus dem README):

```bash
gh repo create dotfiles --private --source=. --push
```

Vorher kurz sicherstellen, dass nichts Persönliches drin ist – die `.gitignore` schliesst `*.local`, `.env` und
Backups aus, aber ein Blick schadet nicht:

```bash
git grep -n -i -E "token|secret|passw" -- . ':!docs'
```

Was **nie** ins Repo gehört: `~/.gitconfig.local`, `~/.zshrc.local`, `~/.ssh/*`, `~/.claude.json`, gh-Tokens.
Diese Dateien liegen ausserhalb des Repos oder sind ignoriert; ein Backup davon machst du über den WSL-Export in
[docs/07-alltag.md](07-alltag.md).
