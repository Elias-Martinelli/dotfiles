# ChatGPT und Codex: die Zweitmeinung

Claude Code ist in dieser Umgebung das Hauptwerkzeug fürs Programmieren (siehe [04-claude-code.md](04-claude-code.md)).
ChatGPT und die Codex CLI von OpenAI sind die **Ergänzung**: für eine zweite Meinung, für Recherche und Erklärungen,
für Bilder – und um dieselbe Aufgabe einmal von einem anderen Modell lösen zu lassen. Diese Seite zeigt, was wovon
wozu dient, wie du die ChatGPT-App und die Codex CLI installierst und anmeldest, und wo sich die beiden Assistenten
unterscheiden. Alles hier ist **optional**: Ohne bezahltes ChatGPT-Konto überspringst du die Codex-Teile einfach.

> 💡 **Für Einsteiger:** ChatGPT und Claude sind zwei Produkte von zwei Firmen (OpenAI und Anthropic). Beide können
> chatten, beide können programmieren. „Codex" ist der Name, unter dem OpenAI seinen Programmier-Assistenten
> fürs Terminal und für VS Code anbietet – das Gegenstück zu Claude Code. Du brauchst nicht beides. Wir haben
> beides, weil zwei Meinungen bei schwierigen Fragen mehr wert sind als eine.

## Rollenverteilung

| Aufgabe | Werkzeug | Warum |
|---|---|---|
| Programmieren im Projekt: Code lesen, ändern, Tests, Refactoring, Commits | **Claude Code** (Terminal, VS Code, Desktop-App) | Primär. Kennt durch `claude/CLAUDE.md` und `claude/rules/` unsere Arbeitsweise; Einstellungen liegen im Repo |
| Zweitmeinung zu einer Lösung, einem Konzept, einer Fehlermeldung | **ChatGPT-App** oder Codex CLI | Ein anderes Modell übersieht andere Dinge |
| Recherche, Erklärungen, Lernen, Zusammenfassungen | **ChatGPT-App** (oder Claude im Browser) | Chat ohne Projektbezug; das Terminal ist dafür der falsche Ort |
| Bilder erzeugen oder analysieren, Diagramme skizzieren | **ChatGPT-App** | Claude Code erzeugt keine Bilder |
| Dieselbe Programmieraufgabe zum Vergleich | **Codex CLI** neben Claude Code | Siehe [Tipp: dieselbe Aufgabe beiden geben](#tipp-dieselbe-aufgabe-beiden-geben) |

Unsere `claude/CLAUDE.md` weiss von dieser Arbeitsteilung: Bittest du Claude, eine Codex-Lösung zu bewerten, soll
es das sachlich tun, nicht konkurrierend.

## ChatGPT-Desktop-App (Windows)

Die ChatGPT-App gibt es für Windows offiziell im **Microsoft Store** (Herausgeber: OpenAI). Sie läuft auf der
Windows-Seite, hat mit WSL nichts zu tun und braucht keine Konfiguration aus diesem Repo.

- **Automatisch:** `windows/setup.ps1` installiert sie über die Store-Quelle von winget. Mit dem Parameter
  `-SkipChatGPT` lässt du sie (und die VS-Code-Extension `openai.chatgpt`) weg.
- **Von Hand:** Microsoft Store öffnen (Windows-Taste, `Store` tippen), nach `ChatGPT` suchen, die App des
  Herausgebers OpenAI installieren. Alternativ genügt <https://chatgpt.com> im Browser.
- **Anmelden:** App starten, „Continue to sign in" wählen, im Browser mit dem ChatGPT-Konto anmelden. Für den
  Chat reicht ein Gratis-Konto; für Codex (unten) brauchst du einen bezahlten Plan.

Die App bringt Codex auch als eigenen Bereich mit. Für Projekte in Ubuntu nutzen wir Codex aber über die CLI und
die VS-Code-Extension, weil beide direkt im Linux-Dateisystem arbeiten.

Tastenkürzel der App stehen in der App selbst unter Einstellungen; wir nennen hier bewusst keine, weil sie sich
zwischen Versionen ändern.

## Codex CLI installieren

`install.sh` fragt in Schritt 2 „Codex CLI (ChatGPT) zusätzlich zu Claude Code installieren?" (Vorgabe: Ja) und
installiert Codex dann in Schritt 8 – ohne sudo, mit dem offiziellen Installer. Schlägt der fehl und ist `npm`
vorhanden, weicht das Skript auf `npm install -g @openai/codex` aus. Mit `--no-codex` überspringst du Codex, mit
`--skip-ai` den ganzen Schritt 8. Später nachholen geht jederzeit: `./install.sh` erneut starten und die Frage
mit Ja beantworten.

Von Hand (im **Ubuntu-Terminal**, nie in der PowerShell – Codex muss in WSL laufen, damit es dein Linux-Projekt
und die Linux-Werkzeuge sieht):

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

Prüfen:

```bash
codex --version
```

```bash
which codex
```

`which codex` sollte auf `~/.local/bin/codex` zeigen – denselben Ordner, in dem auch `claude`, `uv` und `ruff`
liegen und den `zsh/zshrc` in den PATH nimmt. Meldet die Shell `codex: command not found`, neues Terminal öffnen
oder `exec zsh`.

## Codex aktualisieren

Der Installer ist gleichzeitig der Updater: derselbe Einzeiler wie oben holt die neueste Version. Bei uns macht
das `update-all` aus `zsh/zshrc` automatisch mit, sobald `codex` installiert ist. Codex kennt ausserdem einen
eigenen Befehl, der bei selbst-aktualisierbaren Installationen funktioniert:

```bash
codex update
```

## Anmelden

Codex verlangt ein ChatGPT-Konto mit **bezahltem Plan**. Erster Start:

```bash
codex
```

(oder der Alias `cx` aus `zsh/aliases`). Codex zeigt die Auswahl „Sign in with ChatGPT"; bestätigen, im Browser
auf Windows anmelden, zurück ins Terminal. Explizit anmelden oder das Konto wechseln:

```bash
codex login
```

Prüfen, ob und wie du angemeldet bist:

```bash
codex login status
```

Abmelden mit `codex logout`. Die Anmeldedaten liegen in `~/.codex/auth.json` – **nicht** im Repo, `install.sh`
kopiert aus dem Repo nur die Vorlage für `config.toml` nach `~/.codex`. CLI und VS-Code-Extension teilen sich dieselbe Anmeldung; meldest
du dich in einer ab, musst du dich in beiden neu anmelden.

Alternative ohne ChatGPT-Plan: ein API-Key der OpenAI-Plattform (Abrechnung pro Token). Er gehört in
`~/.zshrc.local` (Vorlage `zsh/zshrc.local.example`, Zeile `export OPENAI_API_KEY=...`), niemals ins Repo.

## Grundbefehle

| Befehl im Terminal | Wirkung |
|---|---|
| `codex` (Alias `cx`) | Interaktive Sitzung im aktuellen Ordner |
| `codex exec "aufgabe"` | Nicht-interaktiv: Codex arbeitet die Aufgabe ab, Fortschritt geht nach stderr, nur die Schlussantwort nach stdout – ideal zum Weiterleiten (`codex exec "..." > notizen.md`). Standardmässig nur lesend; Änderungen erlauben mit `codex exec --sandbox workspace-write "..."` |
| `codex resume` | Letzte Sitzung fortsetzen oder aus den gespeicherten Sitzungen dieses Ordners wählen |
| `codex --version` | Installierte Version |
| `codex login status` | Anmeldestatus |
| `codex update` | Aktualisieren (siehe oben) |

In der Sitzung beginnen Befehle wie bei Claude Code mit `/`:

| Befehl in der Sitzung | Wirkung |
|---|---|
| `/model` | Modell (und, wenn verfügbar, den Denkaufwand) wählen; Codex schreibt die Wahl in `~/.codex/config.toml` |
| `/permissions` | Festlegen, was Codex ohne Rückfrage darf: nur lesen, im Projektordner schreiben, alles |
| `/status` | Sitzungs-ID, Kontextauslastung, Kontingent (rate limits) |
| `/init` | `AGENTS.md` für das Projekt erzeugen (das Gegenstück zu `CLAUDE.md`) |
| `/plan` | Plan-Modus: erst Vorgehen vorschlagen, dann umsetzen |
| `/diff` | Git-Diff der bisherigen Änderungen anzeigen, auch untracked Dateien |
| `/compact` | Gespräch zusammenfassen, Kontext freigeben |
| `/clear` | Neues Gespräch |
| `/exit` (oder `/quit`) | Sitzung beenden |

> 💡 **Für Einsteiger:** Codex arbeitet in einer **Sandbox**: Im Modus `workspace-write` darf es nur im
> Projektordner schreiben und fragt, wenn es mehr braucht (z. B. Netzwerk oder Dateien ausserhalb). Je nach
> Einstellung startet es sogar nur lesend, bis du den Ordner als vertrauenswürdig markierst. Mit `/permissions`
> siehst du jederzeit, was gerade gilt. Wie bei Claude gilt: Diff lesen, bevor du bestätigst.

## ~/.codex/config.toml

`install.sh` legt `~/.codex/config.toml` als **Kopie** von `codex/config.toml` aus dem Repo an – nur, wenn du Codex
haben wolltest oder es bereits installiert ist, und nur, wenn dort noch keine Datei liegt. Anders als bei Claude
Code ist es bewusst kein Symlink: Codex schreibt rechnerspezifische Daten in die Datei (dein gewähltes Modell, das
Vertrauen für Projektordner mit ihrem absoluten Pfad, Hinweise der Oberfläche), und die gehören nicht ins Repo.
Die Vorlage im Repo ist absichtlich minimal: Sie enthält ausschliesslich Kommentare und
vier **auskommentierte** Beispiele für Schlüssel aus der offiziellen Konfigurationsreferenz. Ohne aktive Schlüssel
gelten die Codex-Standardwerte.

| Schlüssel | Bedeutung | Werte |
|---|---|---|
| `model` | Standardmodell. Setzt Codex selbst, wenn du in der Sitzung mit `/model` wählst | Modellname, z. B. `"gpt-6-sol"` |
| `approval_policy` | Wann Codex vor einer Aktion nachfragt | `"on-request"` (fragt, wenn es etwas ausserhalb der Sandbox braucht – Standard und empfohlen), `"never"` (nie fragen, nur für Automatisierung) |
| `model_reasoning_effort` | Wie ausführlich das Modell nachdenkt: langsamer und teurer, aber gründlicher | `"low"`, `"medium"`, `"high"`, `"xhigh"`, `"max"`, `"ultra"` – nicht jedes Modell kann alle |
| `sandbox_mode` | Was Codex im Dateisystem ohne Rückfrage darf | `"read-only"`, `"workspace-write"` (im Projektordner schreiben, sinnvoll für den Alltag), `"danger-full-access"` (nicht empfohlen) |

Zum Aktivieren die Raute am Zeilenanfang entfernen. Für **diesen Rechner** änderst du `~/.codex/config.toml`
direkt (oder lässt Codex das über `/model` tun). Soll eine Einstellung auf **allen** Rechnern gelten, trägst du sie
in `codex/config.toml` im Repo ein und committest sie; auf bestehenden Rechnern überträgst du sie von Hand, weil
der Installer eine vorhandene Datei nie überschreibt. Weitere Schlüssel nur aufnehmen,
wenn sie in der offiziellen Referenz stehen (Link am Ende der Seite), und die Datei danach mit
`python3 -c "import tomllib, pathlib; tomllib.loads(pathlib.Path('codex/config.toml').read_text())"` auf gültiges
TOML prüfen.

## VS-Code-Extension openai.chatgpt

Die Extension heisst im Marketplace „Codex – OpenAI's coding agent" und hat die ID `openai.chatgpt`. Sie ist
zweimal installiert: auf der Windows-Seite durch `windows/setup.ps1` und in Ubuntu durch `install.sh`
(Schritt 9, Liste `packages/vscode-extensions.txt`), damit sie in WSL-Fenstern läuft.

1. Ein Projekt aus Ubuntu öffnen (`code .`), unten links muss `WSL: Ubuntu-24.04` stehen.
2. Links in der Activity Bar auf das **Codex-Symbol** klicken. Fehlt es: Command Palette (`Ctrl+Shift+P`) →
   „Codex: Open Codex Sidebar".
3. „Sign in with ChatGPT" wählen und im Browser anmelden – oder du bist es schon, weil die Extension die
   Anmeldung der CLI mitbenutzt.
4. Frage stellen; die Extension nimmt offene Dateien und markierten Text als Kontext mit und zeigt Änderungen als
   Diff im Editor.

Findet die Extension in einem WSL-Fenster kein Codex, prüfst du im VS-Code-Terminal:

```bash
which codex
```

Kommt nichts zurück, Codex wie oben in Ubuntu installieren (nicht auf Windows) und das Fenster neu laden.
Projekte gehören unter `~/code`, nicht nach `/mnt/c` – sonst wird Codex wie alles andere langsam.

## Vergleich: Claude Code vs. Codex

| | Claude Code | Codex CLI |
|---|---|---|
| Anbieter, Konto | Anthropic; Claude Pro, Max, Team, Enterprise oder Console-Key | OpenAI; ChatGPT mit bezahltem Plan oder API-Key |
| Login | `claude` starten → Browser; später `/login` | `codex` starten → „Sign in with ChatGPT" → Browser; `codex login`, `codex login status` |
| Start, Alias | `claude`, `cc` | `codex`, `cx` |
| Sitzung fortsetzen | `claude --continue` (`ccc`), `claude --resume` | `codex resume` |
| Einzelaufgabe ohne Sitzung | `claude -p "..."` | `codex exec "..."` |
| Konfigurationsdatei | `~/.claude/settings.json` → `claude/settings.json` (JSON, Symlink ins Repo) | `~/.codex/config.toml`, einmalige Kopie von `codex/config.toml` (TOML) |
| Anweisungen fürs Projekt | `CLAUDE.md` (erzeugt `/init`), zusätzlich `.claude/rules/` | `AGENTS.md` (erzeugt `/init`) |
| Persönliche Anweisungen für alle Projekte | `~/.claude/CLAUDE.md` → `claude/CLAUDE.md`, `~/.claude/rules/` → `claude/rules/` | Nicht Teil unseres Repos; wir pflegen Anweisungen nur für Claude |
| Berechtigungen | Modus (`Shift+Tab`), Regeln in `settings.json`, optional Sandbox | `/permissions`, `sandbox_mode` und `approval_policy` in `config.toml` |
| Modell wählen | `/model` | `/model` |
| Verbrauch | `/usage`, `/status` | `/status` |
| Aktualisieren | `claude update` (auch automatisch im Hintergrund) | Installer-Einzeiler oder `codex update` |
| VS-Code-Extension | `anthropic.claude-code`, Spark-Symbol | `openai.chatgpt`, Codex-Symbol |
| Windows-App | Claude-Desktop-App (Reiter „Code", WSL-Sitzung) | ChatGPT-App (Store) |
| In `update-all` | ja | ja |

Praktisch: Claude Code kann eine vorhandene `AGENTS.md` als Projektanweisung lesen, wenn es keine `CLAUDE.md`
gibt, und `/init` in Claude Code bietet an, eine gefundene Codex-Konfiguration mit `/import` zu übernehmen.
Umgekehrt hat Codex einen `/import`-Befehl für Claude-Code-Einstellungen. Du musst also nichts doppelt schreiben,
wenn du ein Projekt mit beiden bearbeitest – eine `CLAUDE.md` genügt in der Regel.

## Tipp: dieselbe Aufgabe beiden geben

Bei einer schwierigen Aufgabe (Architekturentscheid, hartnäckiger Bug, Performance) lohnt es sich, beide
Assistenten unabhängig arbeiten zu lassen und die Ergebnisse zu vergleichen. Sauber geht das mit zwei Branches:

```bash
git switch -c versuch-claude
```

Aufgabe in `claude` lösen lassen, Ergebnis committen. Dann zurück und ein zweiter Branch:

```bash
git switch main && git switch -c versuch-codex
```

Denselben Prompt in `codex` eingeben, Ergebnis committen. Vergleichen:

```bash
git diff versuch-claude versuch-codex --stat
```

```bash
uv run pytest
```

Danach den besseren Branch mergen, den anderen löschen – oder Claude bitten, beide Lösungen sachlich zu
bewerten (unsere `claude/CLAUDE.md` verlangt genau das). Oft ist die beste Lösung eine Mischung.

Ohne Branches geht es auch leichter: Frage zuerst Claude Code, dann kopierst du Frage und Antwort in die
ChatGPT-App mit dem Zusatz „Ein anderer Assistent schlägt Folgendes vor – was übersieht er?".

## Datenschutz

Beide Assistenten schicken deinen Code, deine Prompts und die Ausgaben der ausgeführten Befehle an den jeweiligen
Anbieter, um Antworten zu erzeugen. Deshalb gilt für Claude Code und Codex gleichermassen:

- **Keine Geheimnisse in den Projektordner.** API-Keys, Passwörter und Tokens gehören in `.env` (steht in
  `.gitignore`) oder in `~/.zshrc.local`. Unsere `claude/settings.json` sperrt `.env`, `~/.ssh` und
  `~/.claude.json` für Claude; bei Codex begrenzt `sandbox_mode = "workspace-write"` den Zugriff auf den
  Projektordner – eine `.env` im Projektordner ist für Codex aber lesbar. Also nicht hinlegen, was nicht gelesen
  werden darf.
- **Keine Kundendaten, keine personenbezogenen Rohdaten.** Für Studienprojekte mit echten Daten (HSLU, Firmen)
  zuerst klären, ob die Daten an einen US-Anbieter dürfen. Im Zweifel mit anonymisierten Stichproben arbeiten und
  Rohdaten ausserhalb des Projektordners halten.
- **Ausgaben prüfen.** Ein Assistent kann beim Ausführen von Befehlen Inhalte aus Dateien lesen, die du nicht
  gemeint hast (Logs, Datenbank-Dumps). Der Diff und die Befehlsliste in der Rückfrage zeigen, was passiert;
  darum lassen wir beide im Standardmodus fragen.
- **Konto-Einstellungen.** Ob deine Gespräche zum Training verwendet werden dürfen, stellst du in den
  Konto-Einstellungen von Anthropic bzw. OpenAI ein – nicht in diesem Repo.
- **Was im Repo ist, ist öffentlich lesbar, sobald das Repo öffentlich ist.** `claude/CLAUDE.md` und
  `codex/config.toml` enthalten darum nur Arbeitsweise und Konfiguration, nie Zugangsdaten.

## Weiterführend

- Codex CLI, Installation und Login: <https://learn.chatgpt.com/docs/codex/cli> und <https://learn.chatgpt.com/docs/auth>
- `codex exec` für Skripte: <https://learn.chatgpt.com/docs/non-interactive-mode>
- Konfigurationsreferenz für `config.toml`: <https://developers.openai.com/codex/config-reference>
- VS-Code-Extension: <https://marketplace.visualstudio.com/items?itemName=openai.chatgpt>
- Claude Code als Gegenstück: [04-claude-code.md](04-claude-code.md)
