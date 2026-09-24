# Claude Code: Login, Alltag, Einstellungen

Claude Code ist der wichtigste KI-Assistent in dieser Umgebung. Es liest dein Projekt, schlägt Änderungen vor,
führt Tests aus und erklärt fremden Code – im Terminal, in VS Code oder in der Claude-Desktop-App. Diese Seite
zeigt, wie du dich anmeldest, wie eine Sitzung abläuft, was unsere `claude/settings.json` Zeile für Zeile bewirkt,
wie `CLAUDE.md` und Regeln zusammenspielen und was du tust, wenn etwas hakt. ChatGPT und die Codex CLI als
Zweitmeinung stehen in [05-chatgpt-codex.md](05-chatgpt-codex.md).

> 💡 **Für Einsteiger:** Claude Code ist kein Chatfenster, in das du Code kopierst. Es ist ein Programm, das
> **in deinem Projektordner** arbeitet: Es darf Dateien lesen, Änderungen vorschlagen und Befehle wie `pytest`
> ausführen – aber mit unseren Einstellungen fragt es dich vor jeder Änderung und zeigt dir den Unterschied (den „Diff")
> an. Du bleibst also immer am Steuer. Alles, was Claude an deinem Code ändert, siehst du auch in `git status`.

## Drei Wege, Claude Code zu nutzen

Alle drei Wege nutzen dasselbe Konto und, sobald sie in Ubuntu laufen, dieselben Dateien unter `~/.claude`
(unsere Symlinks aus Schritt 10 von `install.sh`). Du kannst jederzeit wechseln.

| Weg | So startest du | Vorteile | Nachteile |
|---|---|---|---|
| **Terminal** (Ubuntu oder VS-Code-Terminal) | Im Projektordner `claude` (Alias `cc`), letzte Sitzung fortsetzen mit `ccc` | Alle Befehle und Tastenkürzel, Tab-Vervollständigung, `!` für Shell-Befehle, funktioniert überall, auch per SSH | Diffs im Terminal statt im Editor; für Einsteiger anfangs ungewohnt |
| **VS-Code-Extension** `anthropic.claude-code` | Spark-Symbol oben rechts im Editor (erscheint, wenn eine Datei offen ist) oder links in der Activity Bar | Sieht markierten Text, zeigt Diffs direkt im Editor, Checkpoints zum Zurückspulen, Klickbedienung für Berechtigungsmodus | Nur ein Teil der Slash-Befehle (`/` tippen zeigt sie); kein `!`-Kürzel, keine Tab-Vervollständigung |
| **Claude-Desktop-App** (Windows), Reiter „Code" mit **WSL-Sitzung** | Umgebung wählen: „WSL" → `Ubuntu-24.04`, dann Linux-Ordner (z. B. `/home/<name>/code/projekt`) wählen, Ordner beim ersten Mal vertrauen | Mehrere Sitzungen parallel, Diff-Ansicht, PR-Status, „Open in editor" öffnet VS Code über Remote-WSL; die Sitzung läuft komplett in Ubuntu | In WSL-Sitzungen fehlen (Stand 2026-09): integriertes Terminal, Connectors und Plugins, Sitzungs-Forking, Datei-Browser und `@`-Dateivorschläge |

Zwei Dinge, die oft verwirren:

- Die VS-Code-Extension bringt eine **eigene Kopie** der Claude-Code-CLI für ihr Panel mit. `claude` im
  Terminal funktioniert trotzdem nur mit der eigenständigen CLI, die `install.sh` in Schritt 8 nach
  `~/.local/bin/claude` installiert. Beides ist bei uns vorhanden.
- In einem VS-Code-Fenster mit `WSL: Ubuntu-24.04` unten links läuft die Extension **in Ubuntu** und liest
  dieselben Dateien wie das Terminal (`~/.claude/settings.json`, `~/.claude/CLAUDE.md`). Öffnest du VS Code ohne
  WSL (ein Windows-Ordner), gilt stattdessen das Windows-Profil – Projekte gehören darum immer nach `~/code`.

## Voraussetzung: ein Konto

Claude Code braucht ein Konto mit **Pro, Max, Team oder Enterprise** oder ein Console-Konto (API, Abrechnung
pro Token). Der Gratis-Plan von claude.ai reicht **nicht**. Konto anlegen auf <https://claude.ai>, das Abo kannst du
später abschliessen.

Alternative zum Abo-Login: ein API-Key aus der Console in `~/.zshrc.local` (Vorlage `zsh/zshrc.local.example`,
Zeile `export ANTHROPIC_API_KEY=...`). Ist die Variable gesetzt, fragt Claude Code beim Start einmal, ob es den
Key verwenden soll, statt den Browser zu öffnen. Der Key gehört **nie** ins Repo.

## Installation prüfen und anmelden

`install.sh` installiert Claude Code nativ (Schritt 8, ohne sudo):

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Das musst du normalerweise nicht selbst ausführen. Prüfen, ob alles da ist:

```bash
claude --version
```

```bash
claude doctor
```

`claude doctor` prüft Installation und Einstellungsdateien, ohne eine Sitzung zu starten, und nennt Warnungen
samt Lösungsvorschlag – der erste Anlaufpunkt bei Problemen.

**Anmelden (einmalig pro Rechner):**

1. In einem beliebigen Ordner `claude` starten.
2. Claude Code öffnet den Browser (auf Windows). Dort mit deinem Claude-Konto anmelden und den Zugriff bestätigen.
3. Zurück im Terminal ist die Sitzung angemeldet. Später neu anmelden mit `/login` in einer Sitzung.

In der VS-Code-Extension erscheint beim ersten Öffnen des Panels ein Anmeldebildschirm („Sign in"), in der
Desktop-App meldest du dich in der App an. Terminal, Extension und WSL-Sitzungen der Desktop-App teilen sich in
Ubuntu die Anmeldung; sie liegt in `~/.claude.json`, die absichtlich **nicht** im Repo ist.

> 💡 **Für Einsteiger:** Öffnet sich kein Browser (das kommt in WSL vor), zeigt Claude Code den Anmelde-Link im
> Terminal an. Öffne ihn im Browser auf Windows, melde dich an und folge dann den Anweisungen im Terminal.

## Erste Schritte in einem Projekt

Claude Code arbeitet immer im Ordner, in dem du es startest, und sieht dessen Dateien:

```bash
cd ~/code/mein-projekt
```

```bash
claude
```

Dann tippst du einfach, was du willst: „Erkläre mir, was dieses Projekt macht", „Schreibe Tests für
`src/features.py`". Mit `Enter` schickst du ab, `Ctrl+C` unterbricht eine laufende Antwort, `/exit` oder `Ctrl+D`
beendet die Sitzung.

### Ein Projekt-CLAUDE.md anlegen

In einem neuen Projekt als Erstes:

```text
/init
```

`/init` liest den Code und erzeugt eine `CLAUDE.md` im Projektordner: Befehle, Struktur, Konventionen. Lies sie
durch und kürze, was falsch oder überflüssig ist. Alternativ kopierst du unsere Vorlage `templates/project-CLAUDE.md`
nach `CLAUDE.md` und passt sie an. Mehr dazu unter [CLAUDE.md, Regeln und Auto-Memory](#claudemd-regeln-und-auto-memory).

### Plan-Modus: erst denken, dann ändern

Für alles, was mehr als eine Datei betrifft, lohnt sich der **Plan-Modus**: Claude liest, untersucht und schlägt
einen Plan vor, ändert aber nichts, bis du den Plan genehmigst.

- `Shift+Tab` schaltet den Berechtigungsmodus weiter: Manual (`default`) → `acceptEdits` → `plan` → wieder
  Manual. Die Statuszeile zeigt z. B. `⏸ plan mode on`.
- Nur eine Frage im Plan-Modus stellen: die Nachricht mit `/plan` beginnen, z. B. `/plan Refactoring von io.py`.
- Sitzung direkt im Plan-Modus starten:

```bash
claude --permission-mode plan
```

Ist der Plan fertig, fragt Claude, wie es weitergehen soll: Plan annehmen und jede Änderung einzeln bestätigen
(„Yes, manually approve edits"), Plan annehmen und Änderungen automatisch übernehmen, oder weiter planen („No, keep
planning"). Mit `Ctrl+G` kannst du den Plan vorher in deinem Editor bearbeiten.

### Die wichtigsten Slash-Befehle

In der Sitzung beginnt jeder Befehl mit `/`. `/help` zeigt alle.

| Befehl | Wirkung |
|---|---|
| `/init` | `CLAUDE.md` für das Projekt erzeugen |
| `/plan [aufgabe]` | Plan-Modus für die nächste Aufgabe |
| `/model` | Modell wechseln und als Standard speichern (mit `s` nur für diese Sitzung); bei manchen Modellen mit ←/→ den Aufwand („effort") anpassen |
| `/permissions` | Allow-, Ask- und Deny-Regeln ansehen und ändern (unsere stehen in `claude/settings.json`) |
| `/usage` | Verbrauch: Balken deines Plan-Kontingents (Pro/Max), Aufschlüsselung, Aktivität; `/cost` ist ein Alias |
| `/status` | Einstellungen-Dialog auf dem Reiter Status: Version, Modell, Konto, Verbindung |
| `/context` | Zeigt als Raster, was gerade den Kontext füllt (Dateien, `CLAUDE.md`, Werkzeuge) und wo du sparen kannst |
| `/compact [hinweis]` | Gespräch zusammenfassen und so Kontext freigeben; optional mit Fokus, z. B. `/compact nur die offenen Bugs behalten` |
| `/clear` | Neues Gespräch mit leerem Kontext (die alte Sitzung bleibt über `/resume` erreichbar) |
| `/memory` | `CLAUDE.md`-Dateien öffnen, Auto-Memory ein- oder ausschalten und ansehen |
| `/resume` | Frühere Sitzung auswählen und fortsetzen |
| `/rewind` | Gespräch und/oder Code auf einen früheren Punkt zurücksetzen |
| `/sandbox` | Sandbox ein- oder ausschalten (siehe [Was darf Claude auf meinem Rechner?](#was-darf-claude-auf-meinem-rechner)) |
| `/doctor` | Setup-Check in der Sitzung, kann Probleme direkt beheben |
| `/login` | Neu anmelden oder Konto wechseln |
| `/exit` | Sitzung beenden |

### Die wichtigsten Befehle im Terminal

| Befehl | Wirkung |
|---|---|
| `claude` (Alias `cc`) | Interaktive Sitzung im aktuellen Ordner |
| `claude "frage"` | Sitzung starten und die Frage sofort stellen |
| `claude -p "frage"` | Einzelfrage ohne interaktive Sitzung; Antwort landet auf der Standardausgabe (`-p` = `--print`), z. B. `claude -p "Erkläre diesen Fehler: $(cat fehler.log)"` |
| `claude --continue` oder `claude -c` (Alias `ccc`) | Letzte Sitzung in diesem Ordner fortsetzen |
| `claude --resume` oder `claude -r` | Sitzung aus einer Liste auswählen; mit Namen oder ID direkt: `claude -r "name"` |
| `claude --permission-mode plan` | Im Plan-Modus starten (auch `default`, `acceptEdits`) |
| `claude --model sonnet` | Modell für diese Sitzung wählen (`sonnet`, `opus`, `haiku` oder voller Modellname) |
| `claude update` | Auf die neueste Version des eingestellten Kanals aktualisieren (Teil von `update-all`) |
| `claude doctor` | Installations- und Einstellungsdiagnose ohne Sitzung |
| `claude --version` | Installierte Version |

Die native Installation aktualisiert sich zusätzlich selbst im Hintergrund; `update-all` aus `zsh/zshrc` ruft
`claude update` trotzdem auf, damit alles in einem Rutsch aktuell ist.

> 💡 **Für Einsteiger:** `cc` überdeckt den C-Compiler gleichen Namens. Solltest du ihn je brauchen, tipp
> `command cc` oder `gcc` (steht so auch in `zsh/aliases`).

## Unsere settings.json Zeile für Zeile

`~/.claude/settings.json` ist ein Symlink auf `claude/settings.json` im Repo. Sie gilt für **alle** Projekte
(„User-Ebene"). Daneben gibt es pro Projekt `.claude/settings.json` (wird mit dem Team geteilt, ins Git) und
`.claude/settings.local.json` (persönlich, steht in unserer `.gitignore`). Setzt eine Projektdatei denselben
Schlüssel, gewinnt sie über die User-Datei.

```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "permissions": {
    "defaultMode": "default",
    "allow": [
      "Bash(git status *)",
      "Bash(git diff *)",
      "Bash(git log *)",
      "Bash(ls *)",
      "Bash(uv run pytest *)",
      "Bash(uv run python -m pytest *)",
      "Bash(uv run ruff *)",
      "Bash(uv add *)",
      "Bash(uv sync *)",
      "Bash(ruff *)",
      "Bash(pytest *)",
      "Bash(python -m pytest *)"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(~/.ssh/**)",
      "Read(~/.claude.json)",
      "Bash(rm -rf /*)"
    ]
  },
  "autoUpdatesChannel": "latest",
  "cleanupPeriodDays": 60,
  "env": {},
  "theme": "dark"
}
```

### `$schema`

Verweist auf das offizielle JSON-Schema. VS Code prüft damit beim Bearbeiten die Schlüssel und Werte und schlägt
sie per Autovervollständigung vor. Auf Claude Code selbst hat die Zeile keinen Einfluss.

### `permissions.defaultMode: "default"`

Legt fest, in welchem [Berechtigungsmodus](#berechtigungsmodi) jede neue Sitzung startet. `"default"` ist der
Modus **Manual**: Claude fragt vor jeder Änderung und vor jedem Befehl, der nicht in `permissions.allow` steht.

Ohne diese Zeile würden Sitzungen mit einem Pro-, Max- oder Team-Abo seit Claude Code 2.1.228 im Modus **Auto**
starten: Dann entscheidet eine Hintergrundprüfung statt dir, ob eine Aktion zur Aufgabe passt. Wir setzen bewusst
Manual, damit auch Einsteiger jede Änderung sehen. Claude Code fragt dich deshalb einmal, ob es die Einstellung
auf Auto umstellen soll. Antworte mit „Nein", wenn du bei Manual bleiben willst. Einzelne Sitzungen schaltest du
jederzeit mit `Shift+Tab` in einen anderen Modus.

Willst du Auto dauerhaft, aber nur auf **deinem** Rechner (das Repo bleibt für alle anderen bei Manual):

- **Terminal:** in `~/.zshrc.local` die Zeile `alias claude='claude --permission-mode auto'` eintragen, dann
  `exec zsh`. Der Flag gewinnt über die Datei und gilt auch für die Aliasse `cc` und `ccc`.
- **VS-Code-Extension:** einmal in der Modus-Anzeige unter dem Eingabefeld „Auto" wählen. Die Extension merkt sich
  diese Wahl für neue Gespräche, sie hat Vorrang vor `claude/settings.json`.

⚠️ Antworte auf die einmalige Frage „auf Auto umstellen?" mit **Nein**, sonst schreibt Claude Code `"auto"` über
den Symlink in `claude/settings.json` im Repo und damit für alle Rechner.

### `permissions.allow`

Eine Liste von Regeln für Aktionen, die Claude **ohne Rückfrage** ausführen darf. Alles andere unterliegt dem
Berechtigungsmodus (Manual fragt). Unsere Liste enthält nur lesende Befehle oder solche, die im Projekt Tests,
Formatierung und Abhängigkeiten betreffen:

| Regel | Erlaubt | Warum |
|---|---|---|
| `Bash(git status *)`, `Bash(git diff *)`, `Bash(git log *)` | Git-Zustand, Änderungen und Verlauf ansehen | Lesend; Claude braucht das ständig, um Änderungen zu prüfen |
| `Bash(ls *)` | Ordnerinhalte auflisten | Lesend |
| `Bash(uv run pytest *)`, `Bash(uv run python -m pytest *)`, `Bash(uv run ruff *)` | Tests und Ruff in der Projektumgebung starten | Ohne diese Regeln wäre jeder Testlauf eine Rückfrage. Bewusst **nicht** `Bash(uv run *)`: `uv run` startet jedes beliebige Programm (auch `uv run rm ...`), die Regel würde also alles erlauben |
| `Bash(uv add *)`, `Bash(uv sync *)` | Pakete eintragen, `.venv` und `uv.lock` abgleichen | Ändert nur `pyproject.toml`, `uv.lock` und `.venv` im Projekt |
| `Bash(ruff *)` | Formatieren und Linten | Ändert nur Formatierung im Projekt |
| `Bash(pytest *)`, `Bash(python -m pytest *)` | Tests direkt starten | Lesend im Sinn von: führt nur Tests aus |

So funktioniert das Muster: Der `*` steht für beliebigen Text an seiner Stelle. Ein `*` **am Ende mit Leerzeichen
davor** trifft den Befehl mit beliebigen Argumenten **und** den nackten Befehl – `Bash(git status *)` erlaubt also
`git status` und `git status --short`, aber nicht `git status-foo` oder `git stash`. Das Leerzeichen gehört zur
Regel: `Bash(ls *)` erlaubt `ls -la`, aber nicht `lsof`. Wählst du in einer Rückfrage „Yes, and don't ask again",
schreibt Claude Code genau solche Regeln – allerdings **nicht** in unsere Datei, sondern in
`.claude/settings.local.json` im Wurzelordner des jeweiligen Git-Projekts. Sie gelten also nur für dieses Projekt.
Mit `/permissions` siehst du alle Regeln und aus welcher Datei sie stammen. Soll eine Regel für alle Projekte
gelten, trägst du sie von Hand in `claude/settings.json` im Repo ein und committest sie.

### `permissions.deny`

Regeln, die Claude in **jedem** Modus blockieren, auch wenn du sonst alles erlaubt hast:

| Regel | Blockiert | Warum |
|---|---|---|
| `Read(./.env)`, `Read(./.env.*)` | Lesen von `.env`, `.env.local` usw. **im aktuellen Projektordner** (`./` = relativ zum Arbeitsverzeichnis) | Dort liegen API-Keys und Passwörter |
| `Read(~/.ssh/**)` | Alles unter `~/.ssh` (`~/` = relativ zum Home) | Private SSH-Schlüssel |
| `Read(~/.claude.json)` | Deine Claude-Anmeldedaten | Gehören weder in den Kontext noch ins Repo |
| `Bash(rm -rf /*)` | Der klassische Katastrophenbefehl | Sicherheitsnetz |

Gut zu wissen: `Read`- und `Edit`-Regeln greifen bei Claudes eigenen Dateiwerkzeugen und bei Shell-Befehlen, die
Claude Code als Dateizugriff erkennt (`cat`, `head`, `tail`, `sed`, Umleitungen mit `>`). Ein Python-Skript, das
selbst eine Datei öffnet, sehen sie nicht – dafür gibt es die Sandbox (siehe unten). Die Liste ist ein
Sicherheitsnetz, kein Tresor: Geheimnisse gehören trotzdem nicht in den Projektordner, sondern in `.env` (ignoriert)
oder in `~/.zshrc.local`.

### Zuschreibung in Commits und Pull Requests (`attribution`)

Claude Code hängt an Commits, die es selbst erstellt, standardmässig den Trailer
`Co-Authored-By: <Modellname> <noreply@anthropic.com>` an und ergänzt Pull-Request-Beschreibungen um
`🤖 Generated with [Claude Code](https://claude.com/claude-code)`. Diesen Standard lassen wir bewusst aktiv
(deshalb steht dazu nichts in unserer `settings.json`): So bleibt transparent, welche Commits mit Claude entstanden sind.

Willst du die Zuschreibung ändern oder ausblenden, setzt du im Repo (`claude/settings.json`) den Schlüssel
`attribution`. Leere Strings blenden den jeweiligen Teil aus:

```json
{
  "attribution": {
    "commit": "",
    "pr": "",
    "sessionUrl": false
  }
}
```

`sessionUrl` betrifft nur Commits aus Cloud- oder Remote-Control-Sitzungen (Link auf die claude.ai-Sitzung).
Der ältere Schlüssel `includeCoAuthoredBy` ist seit Version 2.0.62 veraltet und durch `attribution` ersetzt –
in neuen Konfigurationen nicht mehr verwenden.

### `autoUpdatesChannel: "latest"`

Welchen Kanal die Hintergrund-Updates der nativen Installation und `claude update` verfolgen: `"latest"` ist die
jeweils neueste Version (Standard, wenn der Schlüssel fehlt), `"stable"` eine Version, die typischerweise etwa
eine Woche alt ist und Releases mit groben Fehlern überspringt. Wer lieber eine Woche Abstand hat, ändert den
Wert im Repo auf `"stable"` – gilt dann nach `dotfiles-update` auf allen Rechnern.

### `cleanupPeriodDays: 60`

Wie viele Tage Claude Code Sitzungsprotokolle und andere Anwendungsdaten (Transkripte, Shell-Snapshots, Backups)
aufbewahrt, bevor eine Hintergrundbereinigung sie löscht. Standard sind 30 Tage, Minimum 1 (`0` ist ungültig).
60 Tage heisst: `claude --resume` findet Sitzungen aus den letzten zwei Monaten. Die Auto-Memory-Dateien (siehe
unten) sind von dieser Bereinigung ausgenommen.

### `theme: "dark"`

Farbschema der Oberfläche im Terminal. Claude Code fragt beim ersten Start danach und speichert die Wahl hier.
Passt `dark` nicht zu deinem Terminal, wählst du in einer Sitzung mit `/config` ein anderes Schema.

### `env: {}`

Umgebungsvariablen, die in jeder Sitzung und in allen von Claude gestarteten Unterprozessen gesetzt werden – zum
Beispiel Proxy-Variablen in einem Firmennetz oder Schalter aus der offiziellen Liste der Claude-Code-Variablen.
Bei uns leer: Was maschinenspezifisch ist, gehört in `~/.zshrc.local`, nicht ins Repo. Geheimnisse (API-Keys)
hier einzutragen wäre ein Fehler, weil die Datei im Repo liegt.

### Claude Code schreibt selbst in diese Datei

`/model` speichert das gewählte Modell als Standard, und der Schalter für Auto-Memory in `/memory` schreibt
`autoMemoryEnabled`. Auch die einmalige Frage nach dem Auto-Modus (siehe `permissions.defaultMode`) ändert bei
„Ja" diese Datei. Weil `~/.claude/settings.json` ein Symlink ist, landen solche Änderungen direkt in
`claude/settings.json`. Regeln aus „Yes, and don't ask again" landen dagegen im jeweiligen Projekt (siehe oben).
Nach solchen Änderungen prüfen und committen:

```bash
dotfiles && git diff claude/settings.json
```

Ersetzt ein Programm den Symlink durch eine echte Datei, hilft der Abschnitt [Troubleshooting](#troubleshooting).

## Berechtigungsmodi

Der Modus legt fest, was Claude ohne Rückfrage tun darf. Mit `Shift+Tab` wechselst du in der Sitzung, in der
VS-Code-Extension und in der Desktop-App über die Modus-Anzeige neben dem Eingabefeld.

| Modus (Anzeige) | Konfig-Wert | Ohne Rückfrage erlaubt | Wann sinnvoll |
|---|---|---|---|
| **Manual** (`⏸ manual mode on`) | `default` | Nur Lesen sowie unsere `allow`-Regeln | Bei uns der Startmodus (`permissions.defaultMode`). Jede Änderung und jeden anderen Befehl bestätigst du. Für Einsteiger und sensible Projekte |
| **Accept edits** (`⏵⏵ accept edits on`) | `acceptEdits` | Zusätzlich Dateiänderungen und einfache Dateibefehle (`mkdir`, `touch`, `mv`, `cp`) | Wenn du den Änderungen traust und schneller iterieren willst; andere Befehle fragen weiter |
| **Plan** (`⏸ plan mode on`) | `plan` | Lesen und Untersuchen; keine Änderungen bis zur Plan-Freigabe | Vor grösseren Änderungen, beim Einarbeiten in fremden Code |
| **Auto** (`⏵⏵ auto mode on`) | `auto` | Alles, aber jede Aktion wird von einer Hintergrundprüfung mit deiner Aufgabe abgeglichen | Ohne unsere Einstellung der Startmodus für Pro/Max/Team (ab 2.1.228). Erscheint im Zyklus nur, wenn für dein Konto und Modell verfügbar; für lange Aufgaben |
| **Bypass permissions** (`⏵⏵ bypass permissions on`) | `bypassPermissions` | Alles ohne Rückfrage | **Nicht empfohlen.** Nur in isolierten Containern oder VMs. Erscheint erst nach `claude --dangerously-skip-permissions` |

`dontAsk` gibt es nur in der CLI für Skripte: alles, was fragen würde, wird abgelehnt. Unsere `deny`-Regeln gelten
in **allen** Modi, auch in `bypassPermissions`.

### Was darf Claude auf meinem Rechner?

> 💡 **Für Einsteiger:** Im Standardmodus Manual liest Claude die Dateien im Projektordner (ausser den
> gesperrten aus `permissions.deny`) und fragt vor **jeder** Änderung und vor jedem Befehl, der nicht in
> `permissions.allow` steht. Die Rückfrage zeigt den geplanten Befehl bzw. den Diff – lies ihn, bevor du mit
> `Enter` bestätigst. Antworte mit „No", wenn du unsicher bist, und frag Claude, was der Befehl tut.
> Faustregel: Nie „Yes, and don't ask again" für Befehle wählen, die löschen, hochladen oder installieren.
> Und: Claude arbeitet als dein Benutzer – was du nicht darfst (z. B. ohne `sudo` Systemdateien ändern), darf
> Claude auch nicht.

Drei Schutzschichten, von aussen nach innen:

1. **Berechtigungsmodus** (siehe Tabelle) – wie oft Claude fragt.
2. **Regeln** in `claude/settings.json` – was immer erlaubt bzw. immer verboten ist.
3. **Sandbox** (optional) – eine Betriebssystem-Isolation, die Dateizugriffe und Netzwerk auch für Unterprozesse
   begrenzt. Sie ist **nicht** standardmässig aktiv und braucht unter WSL 2 zwei Pakete, die nicht in
   `packages/apt.txt` stehen:

```bash
sudo apt-get install bubblewrap socat
```

Danach Claude Code neu starten und in der Sitzung `/sandbox` eingeben. Fehlt noch etwas, zeigt der Reiter
„Dependencies" dort, was. Unter Ubuntu 24.04 kann zusätzlich eine AppArmor-Freigabe für `bwrap` nötig sein
(prüfen mit `sysctl kernel.apparmor_restrict_unprivileged_userns`; die offizielle Sandbox-Seite beschreibt die
Schritte). Für den Alltag reichen Modus und Regeln; die Sandbox lohnt sich, wenn du Claude länger unbeaufsichtigt
arbeiten lässt.

## CLAUDE.md, Regeln und Auto-Memory

Claude Code liest zu Beginn jeder Sitzung mehrere Dateien mit Anweisungen. Sie ergänzen sich; keine überschreibt
die andere. Zwei davon pflegen wir im Repo.

| Datei | Wo | Wer schreibt | Wann geladen | Wofür |
|---|---|---|---|---|
| **Persönliche Anweisungen** `~/.claude/CLAUDE.md` | Symlink auf `claude/CLAUDE.md` | du | In jeder Sitzung, in jedem Projekt | Wer du bist, wie du arbeitest, Sprache, Python- und Git-Konventionen |
| **Persönliche Regeln** `~/.claude/rules/*.md` | Symlink auf `claude/rules/` | du | Ohne `paths:` in jeder Sitzung; mit `paths:` erst, wenn Claude eine passende Datei liest. `claude/rules/python.md` hat `paths: ["**/*.py"]` | Detailregeln pro Dateityp, ohne die `CLAUDE.md` aufzublähen |
| **Projekt-CLAUDE.md** `<projekt>/CLAUDE.md` | Im Projekt-Repo, für alle Beteiligten | du oder das Team, `/init` oder `templates/project-CLAUDE.md` | In jeder Sitzung in diesem Ordner und in Unterordnern; Claude lädt auch `CLAUDE.md` aus Elternordnern | Zweck, Befehle, Struktur, „Nicht anfassen" |
| **Projekt-Regeln** `<projekt>/.claude/rules/*.md` | Im Projekt-Repo | Team | Wie persönliche Regeln; persönliche Regeln werden **vor** Projektregeln geladen | Teamregeln pro Thema (`testing.md`, `api.md`) |
| **Private Projekt-Notizen** `<projekt>/CLAUDE.local.md` | Im Projekt, in dessen `.gitignore` | du | Zusammen mit der `CLAUDE.md` | Persönliches, das nicht ins Team-Repo soll |
| **Auto-Memory** `~/.claude/projects/<projekt>/memory/MEMORY.md` | Nur auf dieser Maschine, ausserhalb des Repos | Claude | Die ersten 200 Zeilen bzw. 25 KB in jeder Sitzung; Themendateien daneben bei Bedarf | Was Claude aus deinen Korrekturen lernt („immer uv, nie pip") |

So spielen sie zusammen: Sagst du Claude „merk dir, dass die Tests eine lokale Postgres brauchen", landet das im
Auto-Memory. Sagst du „schreib das in die CLAUDE.md", ändert Claude die Projektdatei. Regeln mit `paths:` sind
das Mittel gegen zu lange Dateien: Unsere Python-Regeln kosten nur Kontext, wenn wirklich Python im Spiel ist.
Ziel für jede `CLAUDE.md`: unter 200 Zeilen, konkret, prüfbar („`uv run pytest` vor jedem Commit" statt „gute
Tests schreiben").

Auto-Memory ist standardmässig an; ausschalten kannst du es in `/memory` (schreibt `autoMemoryEnabled` in unsere
`settings.json`) oder nur für ein Projekt in dessen `.claude/settings.json`.

### Pflegen

- Alles, was du an `~/.claude/CLAUDE.md` oder `~/.claude/rules/` änderst – auch über `/memory` –, steht dank
  Symlink sofort im Repo. Danach:

```bash
dotfiles && git status
```

```bash
git add -A && git commit -m "claude: regel fuer notebooks ergaenzt" && git push
```

- Auf anderen Rechnern `dotfiles-update`. Eine neue Sitzung starten, damit die Änderung gilt.
- `/context` zeigt, welche Dateien geladen sind und wie viel Kontext sie belegen. Steht deine Anweisung dort,
  Claude hält sich aber nicht daran, ist sie meist zu vage oder steht im Widerspruch zu einer anderen Datei.
- Nach `/compact` liest Claude die Projekt-`CLAUDE.md` neu von der Platte; Regeln mit `paths:` laden wieder,
  sobald Claude passende Dateien anfasst.
- Neue Regel-Datei: `claude/rules/<thema>.md` anlegen, oben optional ein Frontmatter mit `paths:` (Vorbild
  `claude/rules/python.md`). Ohne `paths:` gilt sie immer.

### Cowork-Sitzungen der Desktop-App

⚠️ **Nur** in Cowork-Sitzungen der Claude-Desktop-App überspringt Claude Code eine `~/.claude/CLAUDE.md`, die ein
Symlink (oder Hardlink) ist, sowie einen verlinkten `~/.claude/rules/`-Ordner oder verlinkte Regel-Dateien, die
ausserhalb des Arbeitsverzeichnisses liegen. Terminal, VS-Code-Extension und WSL-Sitzungen im Reiter „Code" laden
unsere Symlinks normal – dort musst du nichts tun.

Nutzt du Cowork und willst deine Anweisungen auch dort: Kopiere `claude/CLAUDE.md` und den Ordner `claude/rules/`
in das `~/.claude`, das Cowork verwendet (auf Windows in der Regel der Ordner `.claude` in deinem Benutzerprofil),
statt sie zu verlinken – und kopiere nach jeder Änderung im Repo erneut. Das ist der einzige Ort, an dem wir
bewusst auf den Symlink verzichten.

## Tipps für gute Prompts

Vier Bausteine machen aus einer Frage einen Auftrag, den Claude gut erledigen kann:

| Baustein | Schlecht | Besser |
|---|---|---|
| **Kontext** | „Mach das schneller" | „`load_data()` in `src/io.py` braucht 40 s für die 2-GB-CSV in `data/raw/`" |
| **Ziel** | „Verbessere den Code" | „Die Funktion soll unter 5 s bleiben und dasselbe DataFrame liefern" |
| **Einschränkungen** | – | „Nur pandas und pyarrow, keine neuen Abhängigkeiten; die Signatur darf sich nicht ändern; bestehende Tests müssen grün bleiben" |
| **Beispiel oder Prüfung** | – | „Prüfe mit `uv run pytest tests/test_io.py` und zeig mir den Zeitvergleich" |

Weitere Gewohnheiten, die sich auszahlen:

- **Erst erklären lassen, dann ändern.** „Erkläre mir, wie `report.py` die Kennzahlen berechnet, ändere noch
  nichts." Danach weisst du, ob Claude das Problem verstanden hat.
- **Dateien beim Namen nennen.** Pfade wie `src/features.py` und Funktionsnamen sparen Suchzeit und Kontext.
- **Klein schneiden.** Eine Aufgabe pro Auftrag. Ist die erledigt und committet, kommt die nächste. Zwischendurch
  `/clear`, wenn das Thema wechselt, sonst zehrt altes Zeug am Kontext.
- **Korrigieren statt neu anfangen.** „Nicht so – die Funktion soll `Path` statt `str` nehmen" ist besser als
  ein neuer Prompt. Was du öfter korrigierst, gehört in die `CLAUDE.md` oder eine Regel.
- **Fehlermeldungen komplett einfügen.** Der ganze Traceback, nicht nur die letzte Zeile.

Unsere `claude/CLAUDE.md` nimmt Claude einiges davon ab: Antworten auf Deutsch, Code auf Englisch, uv statt pip,
Tests und `ruff check .` vor „fertig", Rückfrage vor destruktiven Aktionen, Commits nur auf Verlangen.

## Arbeitsmuster für Data Science

Beispiel-Prompts, die sich im Studium bewährt haben (die Blöcke sind Text zum Eintippen, keine Shell-Befehle):

**Ein fremdes Notebook verstehen**

```text
Lies notebooks/exploration.ipynb und erkläre mir in 10 Punkten, was dort passiert: Datenquelle, Bereinigung,
Features, Modell, Auswertung. Nenne Stellen, die fehleranfällig oder undokumentiert sind. Ändere nichts.
```

**Notebook-Logik in Module überführen**

```text
Verschiebe die Datenaufbereitung aus notebooks/exploration.ipynb (Zellen 3 bis 9) in Funktionen unter
src/mein_projekt/features.py mit Type Hints und Docstrings. Das Notebook soll die Funktionen danach nur noch
importieren. Ergebnis muss identisch bleiben: vergleiche den DataFrame vor und nach dem Umbau mit
pandas.testing.assert_frame_equal.
```

**Tests schreiben lassen**

```text
Schreibe pytest-Tests für src/mein_projekt/features.py in tests/test_features.py: je ein Normalfall und ein
Randfall pro öffentlicher Funktion (leerer DataFrame, fehlende Spalte, NaN). Kleine Fixtures statt echter Daten.
Führe uv run pytest aus und zeig mir das Ergebnis.
```

**Fehler jagen**

```text
uv run python -m mein_projekt bricht mit folgendem Traceback ab: <Traceback einfügen>. Finde die Ursache, erkläre
sie mir und schlage eine Korrektur vor. Frag nach, bevor du Dateien änderst.
```

**Refactoring mit Netz**

Zuerst `Shift+Tab` in den Plan-Modus, dann:

```text
report.py hat 800 Zeilen und mischt Laden, Berechnen und Plotten. Schlage eine Aufteilung in Module vor, die zu
unserer Struktur (io.py, features.py, report.py) passt. Danach umsetzen, Tests laufen lassen, Ruff prüfen.
```

Für Notebooks in VS Code: Claude kann `.ipynb`-Dateien lesen und bearbeiten, aber grosse Zellausgaben (Tabellen,
Bilder) füllen den Kontext. Ausgaben vorher löschen („Clear All Outputs") oder Claude auf bestimmte Zellen
verweisen. Rohdaten und Modelle gehören ohnehin nicht ins Repo (`.gitignore`), und `permissions.deny` hält Claude
von `.env` fern.

## Zusammenspiel mit Git

Claude Code kennt Git und darf laut unserer `settings.json` jederzeit `git status`, `git diff` und `git log`
ausführen. Committen soll es laut `claude/CLAUDE.md` nur, wenn du es ausdrücklich verlangst.

**Committen lassen:**

```text
Zeig mir git status und git diff, fasse zusammen, was geändert wurde, und committe mit einer passenden
Conventional-Commit-Message.
```

Claude schlägt die Message vor (Präfixe `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:` wie in
[06-git-github.md](06-git-github.md)), fragt vor dem `git commit` nach und hängt den Trailer `Co-Authored-By`
an (Standard-Zuschreibung, siehe Abschnitt `attribution` oben).

**Pull Request erstellen lassen:** `gh` ist eingeloggt, Claude kann es benutzen:

```text
Erstelle einen Branch feature/datenbereinigung, committe die Änderungen und erstelle einen Pull Request mit
gh pr create. Titel und Beschreibung aus den Commits.
```

**Was Claude nie ohne Nachfrage tun darf** (steht in `claude/CLAUDE.md`): `git push --force` auf `main`,
`git reset --hard`, Branches löschen, Dateien mit Geheimnissen committen. Sollte trotzdem etwas schiefgehen:
`/rewind` setzt Code und Gespräch auf einen früheren Punkt zurück, und solange etwas committet war, holt
`git reflog` es zurück.

> 💡 **Für Einsteiger:** Lass dir am Anfang jeden Commit von Claude **vorschlagen**, aber tipp `git commit`
> selbst. So lernst du, was ein guter Commit ist, und behältst die Kontrolle über den Verlauf.

## Kosten und Kontingent im Blick behalten

Mit einem **Pro- oder Max-Abo** ist die Nutzung im Abo enthalten; es gibt aber ein Kontingent pro Zeitraum. Ist
es aufgebraucht, wartest du, bis es sich erneuert, oder schaltest auf claude.ai Nutzungsguthaben („usage credits")
frei.

| Befehl | Zeigt |
|---|---|
| `/usage` (Alias `/cost`) | Balken deines Plan-Kontingents, Aufschlüsselung, welche Verhaltensweisen (lange Kontexte, Cache-Misses) das Kontingent belasten, Aktivitätsstatistik. Der Block „Session" mit einem Dollarbetrag ist für API-Konten gedacht; für Abonnenten ist er nur eine Rechengrösse |
| `/status` | Version, Modell, Konto, Verbindung |
| `/context` | Was gerade den Kontext füllt |
| Desktop-App | Der Ring neben der Modellauswahl: Kontextauslastung der Sitzung und Plan-Verbrauch |

Sparen ohne Qualitätsverlust:

- `/clear` bei Themenwechsel, `/compact` in langen Sitzungen – der Kontext ist der grösste Kostentreiber.
- Kleine Aufgaben mit einem kleineren Modell (`/model`), das grosse für Architektur und knifflige Bugs.
- Keine riesigen Dateien oder Notebook-Ausgaben „nur zur Sicherheit" in den Kontext.
- `claude -p "..."` für Einzelfragen, statt eine lange Sitzung offen zu halten.

Mit API-Key (Console) zahlst du pro Token; dann ist der Dollarbetrag in `/usage` real und `claude -p` in Skripten
kann Kosten verursachen, ohne dass du zuschaust.

## Troubleshooting

| Symptom | Lösung |
|---|---|
| Login-Schleife: Browser meldet Erfolg, Terminal fragt erneut | `claude doctor` ausführen und Warnungen abarbeiten; dann `claude` neu starten und `/login`. Uhrzeit in WSL prüfen (`date`), eine falsche Uhr lässt Logins scheitern – Fix in [99-troubleshooting.md](99-troubleshooting.md) |
| `claude: command not found` | `~/.local/bin` ist in dieser Shell noch nicht im PATH (setzt `zsh/zshrc`). Neues Terminal öffnen oder `exec zsh`. Prüfen: `ls -la ~/.local/bin/claude`. Fehlt die Datei: `./install.sh --skip-apt --skip-python --skip-node --skip-vscode --skip-wslconf` im dotfiles-Repo |
| `ls -la ~/.claude/settings.json` zeigt keinen Pfeil `->` mehr | Ein Programm hat den Symlink durch eine echte Datei ersetzt. Unterschiede ins Repo übernehmen, dann neu verlinken (Befehle unten); die ersetzte Datei liegt danach im Backup-Ordner `~/.dotfiles-backup/<Datum>` |
| Claude hält sich nicht an `CLAUDE.md` | `/context` prüfen, ob die Datei geladen ist; `/memory` öffnet sie. Anweisung konkreter formulieren; Widersprüche zwischen persönlicher und Projekt-Datei auflösen; Datei kürzen |
| VS Code zeigt „Not logged in · Please run /login" | Die Extension öffnet den Anmeldebildschirm meist selbst. Sonst Command Palette (`Ctrl+Shift+P`) → „Developer: Reload Window" |
| Spark-Symbol in VS Code fehlt | Es erscheint oben rechts nur, wenn eine Datei offen ist. Alternativ links in der Activity Bar oder Command Palette → „Claude Code" |
| Desktop-App findet keine WSL-Umgebung | WSL 2 nötig (`wsl -l -v` in PowerShell), `git` muss in Ubuntu installiert sein (`packages/apt.txt`). Auf verwalteten Firmengeräten kann der Administrator WSL-Sitzungen abschalten |
| Alte Version | `claude update` oder `update-all`; `claude --version` zeigt den Stand |
| Sandbox lässt sich nicht einschalten | `sudo apt-get install bubblewrap socat`, Claude Code neu starten, `/sandbox` → Reiter Dependencies |

**Symlink wiederherstellen:**

```bash
dotfiles && diff ~/.claude/settings.json claude/settings.json
```

```bash
dotfiles && ./install.sh --links-only
```

Weitere Fälle (tote Symlinks nach dem Verschieben des Repos, `_docker`-Meldung, DNS, Uhrzeit) stehen in
[99-troubleshooting.md](99-troubleshooting.md).

## Weiterführend

Offizielle Dokumentation (englisch), alle unter <https://code.claude.com/docs/en/>:

| Thema | Seite |
|---|---|
| Installation, Login, Updates | `setup` |
| Alle Terminal-Flags | `cli-reference` |
| Slash-Befehle | `commands` |
| Tastenkürzel und Bedienung | `interactive-mode` |
| Alle Schlüssel der `settings.json` | `settings-reference` |
| Regeln für Berechtigungen | `permissions`, `permission-modes` |
| Sandbox | `sandboxing` |
| `CLAUDE.md`, Regeln, Auto-Memory | `memory` |
| VS-Code-Extension | `vs-code` |
| Desktop-App mit WSL | `desktop-wsl` |
| Kosten und Kontingent | `costs` |

Weiter mit [05-chatgpt-codex.md](05-chatgpt-codex.md), wenn du ChatGPT oder die Codex CLI als Zweitmeinung
einrichten willst, oder mit [06-git-github.md](06-git-github.md) für den Git-Alltag.
