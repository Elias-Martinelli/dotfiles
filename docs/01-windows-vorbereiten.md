# Windows vorbereiten: WSL 2, Ubuntu, Terminal und VS Code

Diese Anleitung bringt einen frischen Windows-Rechner so weit, dass darauf ein echtes Linux (Ubuntu 24.04) läuft und du darin arbeiten kannst. Sie ist für jemanden geschrieben, der noch nie ein Terminal benutzt hat. Wenn du dich auskennst, überspring die Kästen „Für Einsteiger" und arbeite nur die Befehle ab. Rechne mit 30 bis 45 Minuten inklusive Neustart.

Am Ende hast du:

- WSL 2 mit Ubuntu 24.04, einem eigenen Linux-Benutzer und aktuellen Paketen
- Windows Terminal als Standard-Terminal mit Ubuntu als Standardprofil
- VS Code auf Windows mit der Extension „WSL", die Projekte in Ubuntu öffnet
- optional Docker Desktop, die Claude-Desktop-App und die ChatGPT-App

Die eigentliche Entwicklungsumgebung (zsh, Python, Git, Claude Code usw.) kommt danach mit [02-installation.md](02-installation.md).

> 💡 **Für Einsteiger:** Ein **Terminal** ist ein Fenster, in das du Befehle als Text eintippst und mit Enter abschickst. Der Computer antwortet ebenfalls als Text. Es sieht altmodisch aus, ist aber der schnellste Weg, Programme zu installieren und zu steuern. In dieser Anleitung stehen alle Befehle in grauen Kästen. Tipp sie genau so ab (oder kopiere sie), drück Enter und lies, was zurückkommt. Es gibt zwei verschiedene Terminals: **PowerShell** gehört zu Windows, **Ubuntu** ist das Linux-Terminal. Bei jedem Befehl steht, in welches der beiden er gehört.

## Was ist WSL?

WSL (Windows Subsystem for Linux) ist eine Funktion von Windows, mit der ein vollständiges Linux direkt neben Windows läuft: ohne zweiten Computer, ohne Dual-Boot und ohne dass du Windows verlässt. Alle Entwicklerwerkzeuge in diesem Repo laufen in diesem Linux (wir nehmen Ubuntu 24.04), während Editor, Browser und Office ganz normal auf Windows bleiben.

## Voraussetzungen

| Voraussetzung | So prüfst du es |
|---|---|
| Windows 10 ab Version 2004 (Build 19041) oder Windows 11 | Windows-Taste + R drücken, `winver` eintippen, Enter. Im Fenster steht Version und Build. |
| Virtualisierung im BIOS/UEFI eingeschaltet | Task-Manager öffnen (Ctrl + Shift + Esc), Reiter „Leistung" (Performance), links „CPU" anklicken. Rechts unten muss „Virtualisierung: Aktiviert" stehen. Steht dort „Deaktiviert", siehe [Stolpersteine](#häufige-stolpersteine). |
| Administratorrechte auf dem PC | Du kannst Programme installieren, ohne dass ein anderer Benutzer sein Passwort eingeben muss. |
| Internet und rund 10 GB freier Platz auf `C:` | Ubuntu, VS Code und Docker Desktop zusammen brauchen einige Gigabyte. |
| Ein GitHub-Konto (gratis) | Auf <https://github.com> registrieren. Brauchst du ab [02-installation.md](02-installation.md). |
| Ein Claude-Konto mit Pro- oder Max-Abo | Claude Code (unser wichtigster KI-Assistent) läuft nicht mit dem Gratis-Plan. Konto auf <https://claude.ai> anlegen; das Abo kannst du auch später abschliessen. |
| Optional: ein bezahltes ChatGPT-Konto | Nur nötig für die Codex CLI aus [05-chatgpt-codex.md](05-chatgpt-codex.md). |

> 💡 **Für Einsteiger:** Die Bezeichnungen in dieser Anleitung folgen einem deutschen Windows. Ist dein Windows auf Englisch, steht die englische Bezeichnung jeweils in Klammern.

## Überblick: zwei Wege

| | Weg 1: automatisch | Weg 2: manuell |
|---|---|---|
| Was | Das PowerShell-Skript `windows/setup.ps1` aus diesem Repo installiert alles auf der Windows-Seite. | Du führst jeden Schritt selbst aus. |
| Für wen | Elias; Einsteiger, die eine Person zum Nachfragen haben. | Einsteiger, die verstehen wollen, was passiert; alle, bei denen das Skript hakt. |
| Dauer | 10 bis 15 Minuten plus Neustart | 30 bis 45 Minuten plus Neustart |

Beide Wege enden beim Abschnitt [Ubuntu zum ersten Mal starten](#2-ubuntu-öffnen-und-benutzer-anlegen). Lies die manuellen Schritte auch dann einmal durch, wenn du das Skript nimmst, damit du weisst, was es tut.

## Weg 1: Automatisch mit windows/setup.ps1

### PowerShell als Administrator öffnen

1. Windows-Taste drücken und `PowerShell` tippen.
2. Auf den Treffer „Windows PowerShell" **rechtsklicken** und „Als Administrator ausführen" (Run as administrator) wählen.
3. Die Sicherheitsabfrage „Möchten Sie zulassen, dass durch diese App Änderungen an Ihrem Gerät vorgenommen werden?" mit „Ja" bestätigen.

Es öffnet sich ein blaues Fenster, in dessen Titel „Administrator: Windows PowerShell" steht. Die Zeile, in der du tippst, beginnt mit `PS C:\...>`.

### Skript auf den Rechner holen

Variante ZIP (funktioniert bei einem öffentlichen Repo immer; ist das Repo privat, musst du im Browser bei GitHub angemeldet sein und Zugriff darauf haben – sonst zeigt GitHub „404"): Öffne <https://github.com/Elias-Martinelli/dotfiles> im Browser, klicke auf den grünen Knopf „Code" und dann „Download ZIP". Rechtsklick auf die heruntergeladene Datei `dotfiles-main.zip` im Ordner „Downloads" und „Alle extrahieren…" (Extract All…). Wechsle dann in der PowerShell in den Unterordner `windows`:

```powershell
cd $env:USERPROFILE\Downloads\dotfiles-main\dotfiles-main\windows
```

Sollte die PowerShell melden, dass der Pfad nicht existiert, schau im Explorer nach, wie der entpackte Ordner genau heisst, und passe den Befehl an.

### Skript ausführen

Variante A (nach dem ZIP-Download, im Ordner `windows`):

```powershell
Set-ExecutionPolicy -Scope Process Bypass; .\setup.ps1
```

Variante B (nur wenn das Repo auf GitHub öffentlich ist; ohne ZIP): Dieser Einzeiler lädt das Skript und führt es **sofort** aus. Danach ist dieser Schritt erledigt, `.\setup.ps1` entfällt. Parameter wie `-SkipDocker` gehen so nicht; brauchst du sie, nimm Variante A.

```powershell
irm https://raw.githubusercontent.com/Elias-Martinelli/dotfiles/main/windows/setup.ps1 | iex
```

`Set-ExecutionPolicy -Scope Process Bypass` erlaubt nur in diesem einen Fenster das Ausführen des Skripts; nach dem Schliessen gilt wieder die Windows-Voreinstellung.

Das Skript kennt diese Parameter (alle optional, kombinierbar), zum Beispiel `.\setup.ps1 -SkipDocker -SkipChatGPT`:

| Parameter | Wirkung |
|---|---|
| `-SkipDocker` | Docker Desktop nicht installieren |
| `-SkipClaudeApp` | Claude-Desktop-App nicht installieren |
| `-SkipChatGPT` | ChatGPT-App und die VS-Code-Extension `openai.chatgpt` nicht installieren |
| `-SkipWsl` | WSL nicht anfassen: kein Installieren oder Aktualisieren, kein Ubuntu 24.04, keine `.wslconfig` (wenn alles schon läuft) |
| `-DryRun` | Nur anzeigen, was das Skript tun würde, nichts verändern |

Das Skript arbeitet sechs Schritte ab; jeder beginnt mit einer Überschrift wie `1/6 Vorpruefungen`:

1. **Vorprüfungen:** Läuft es als Administrator? Ist `winget` (der Windows-Paketmanager) vorhanden? Fehlt `winget`, installiere im Microsoft Store die App „App-Installer" (App Installer) und starte das Skript erneut.
2. **WSL 2 und Ubuntu 24.04:** installiert beides, falls noch nicht vorhanden, bzw. aktualisiert WSL (`wsl --update`).
3. **Programme per winget:** Windows Terminal, VS Code, PowerShell 7 und optional Docker Desktop. Was schon installiert ist, wird übersprungen.
4. **KI-Apps:** Claude-Desktop-App und ChatGPT-App (aus dem Microsoft Store).
5. **VS-Code-Extensions (Windows-Seite):** `ms-vscode-remote.remote-wsl`, `anthropic.claude-code` und `openai.chatgpt`.
6. **.wslconfig:** legt `C:\Users\<DeinName>\.wslconfig` aus `windows/wslconfig.example` an (halber Arbeitsspeicher und halbe CPU-Kerne für Linux), falls die Datei noch nicht existiert. Danach zeigt das Skript eine Zusammenfassung und die nächsten Schritte.

⚠️ Wenn WSL neu installiert wurde, verlangt das Skript einen **Neustart**. Starte Windows neu, öffne die PowerShell wieder als Administrator, wechsle in denselben Ordner und führe `.\setup.ps1` nochmals aus. Es überspringt alles, was schon erledigt ist, und macht beim Rest weiter.

Danach geht es weiter bei [Ubuntu öffnen und Benutzer anlegen](#2-ubuntu-öffnen-und-benutzer-anlegen). Die Schritte 5 bis 8 von Weg 2 sind für dich grösstenteils schon erledigt. Lies dort trotzdem den Abschnitt zum Standardprofil im Windows Terminal (Schritt 5), führe in Schritt 6 den ersten Start mit `code .` aus Ubuntu aus (das kann das Skript nicht für dich tun) und schalte in Schritt 7 die Docker-WSL-Integration ein, falls du Docker installiert hast.

## Weg 2: Manuell

### 1. WSL und Ubuntu installieren

Öffne PowerShell als Administrator (siehe oben) und tippe:

```powershell
wsl --install -d Ubuntu-24.04
```

Windows schaltet die nötigen Funktionen frei („Virtual Machine Platform", „Windows Subsystem for Linux"), lädt den Linux-Kernel und Ubuntu 24.04 herunter. Das dauert einige Minuten. Am Ende steht sinngemäss, dass ein Neustart nötig ist. Starte den Rechner neu.

Zwei Sonderfälle:

- Erscheint statt einer Installation nur ein langer Hilfetext, ist WSL schon installiert. Zeig dir die verfügbaren Distributionen an und installiere Ubuntu gezielt:

  ```powershell
  wsl --list --online
  ```

  ```powershell
  wsl --install -d Ubuntu-24.04
  ```

- Bleibt der Download bei „0.0%" hängen, lade Ubuntu direkt aus dem Internet statt aus dem Store:

  ```powershell
  wsl --install --web-download -d Ubuntu-24.04
  ```

> 💡 **Für Einsteiger:** `wsl` ist das Windows-Programm, das Linux verwaltet. `--install` heisst „installieren", `-d Ubuntu-24.04` wählt die Linux-Variante („Distribution"). Ubuntu ist die verbreitetste Variante und die, für die dieses Repo gebaut ist.

### 2. Ubuntu öffnen und Benutzer anlegen

Nach dem Neustart öffnet sich meist von selbst ein Fenster „Ubuntu 24.04 LTS". Falls nicht: Windows-Taste drücken, `Ubuntu` tippen und den Treffer anklicken.

Das Fenster zeigt zuerst „Installing, this may take a few minutes...". Danach fragt es nach einem Benutzernamen:

1. `Enter new UNIX username:` – tippe einen Namen **in Kleinbuchstaben, ohne Leerzeichen und ohne Umlaute**, zum Beispiel `elias` oder `peter`. Der Name hat nichts mit deinem Windows-Benutzer zu tun. Merk ihn dir, er taucht später in Pfaden wie `/home/elias` auf.
2. `New password:` – tippe ein Passwort. ⚠️ **Beim Tippen erscheint nichts**, nicht einmal Sternchen. Das ist normal und gewollt. Tipp blind und drück Enter.
3. `Retype new password:` – dasselbe Passwort nochmals.

Dann erscheint eine Zeile wie `elias@DEIN-PC:~$` mit einem blinkenden Cursor. Das ist die **Eingabeaufforderung** (Prompt): Ubuntu wartet auf Befehle. Dieses Passwort brauchst du künftig immer, wenn ein Befehl mit `sudo` beginnt. Schreib es dir auf; wie du es zurücksetzt, steht in den [Stolpersteinen](#häufige-stolpersteine).

> 💡 **Für Einsteiger:** `sudo` vor einem Befehl heisst „führe das als Administrator aus". Ubuntu fragt dann nach deinem Linux-Passwort (wieder blind). Innerhalb einiger Minuten fragt es nicht erneut.

### 3. Ubuntu aktualisieren

Im Ubuntu-Fenster:

```bash
sudo apt update && sudo apt upgrade -y
```

Ubuntu fragt nach deinem Passwort, lädt dann die Paketlisten und installiert alle verfügbaren Aktualisierungen. Es rauschen viele Zeilen durch; das ist in Ordnung. Fertig ist es, wenn wieder der Prompt `elias@DEIN-PC:~$` erscheint.

### 4. WSL aktualisieren und prüfen

Zurück in der PowerShell (muss dafür nicht Administrator sein):

```powershell
wsl --update
```

```powershell
wsl --version
```

Die erste Zeile der Ausgabe zeigt die WSL-Version (`WSL-Version: 2.x.y`). Dann:

```powershell
wsl -l -v
```

Erwartete Ausgabe (der Stern markiert die Standard-Distribution):

```text
  NAME            STATE           VERSION
* Ubuntu-24.04    Running         2
```

Steht unter VERSION eine `1`, stelle auf WSL 2 um:

```powershell
wsl --set-version Ubuntu-24.04 2
```

Heisst deine Distribution hier nur `Ubuntu` (das passiert, wenn sie ohne `-d Ubuntu-24.04` installiert wurde, zum Beispiel auf Elias' Rechner), dann verwende in allen weiteren Befehlen und Pfaden `Ubuntu` statt `Ubuntu-24.04`.

### 5. Windows Terminal einrichten

Windows 11 bringt Windows Terminal mit. Unter Windows 10 installierst du es aus dem Microsoft Store („Windows Terminal") oder in der PowerShell:

```powershell
winget install -e --id Microsoft.WindowsTerminal --accept-package-agreements --accept-source-agreements
```

Windows Terminal ist ein Fenster mit Reitern, in dem PowerShell, Ubuntu und andere Terminals nebeneinander laufen. Es legt für Ubuntu automatisch ein Profil an. Zwei Einstellungen lohnen sich:

1. Windows Terminal öffnen (Windows-Taste, `Terminal` tippen). Einstellungen öffnen mit Ctrl + , (Komma) oder über den Pfeil ˅ neben dem Plus-Reiter → „Einstellungen" (Settings).
2. Links „Start" (Startup) wählen.
3. „Standardprofil" (Default profile) auf `Ubuntu-24.04` stellen. Damit öffnet jeder neue Reiter direkt Ubuntu.
4. „Standardterminalanwendung" (Default terminal application) auf „Windows Terminal" stellen. Damit landet auch ein Doppelklick auf Ubuntu im Startmenü im Windows Terminal statt in einem alten Konsolenfenster.
5. Unten rechts „Speichern" (Save).

Praktisch: Windows Terminal mit Rechtsklick an die Taskleiste anheften. Neuer Reiter: Ctrl + Shift + T. Kopieren und Einfügen funktionieren mit Ctrl + C und Ctrl + V (im Ubuntu-Reiter auch Ctrl + Shift + C / Ctrl + Shift + V).

### 6. VS Code installieren und mit WSL verbinden

VS Code ist der Editor. Er läuft auf **Windows**, öffnet aber Dateien und Terminals in Ubuntu. Installiere VS Code darum auf Windows, **nicht** in Ubuntu.

1. <https://code.visualstudio.com/> öffnen, „Download for Windows" klicken, Installer starten.
2. Beim Schritt „Zusätzliche Aufgaben auswählen" (Select Additional Tasks) muss „Zu PATH hinzufügen" (Add to PATH) angehakt sein. Es ist standardmässig an. Ohne dieses Häkchen kennt Ubuntu später den Befehl `code` nicht.
3. VS Code starten. Links in der Leiste das Symbol mit den vier Quadraten anklicken (Extensions, Ctrl + Shift + X), oben `WSL` eintippen und bei der Extension „WSL" von Microsoft (ID `ms-vscode-remote.remote-wsl`) auf „Install" klicken.

Hast du Weg 1 genommen, hat `setup.ps1` die Extension bereits installiert.

Jetzt der erste Start aus Ubuntu. Im Ubuntu-Terminal:

```bash
mkdir -p ~/code && cd ~/code
```

```bash
code .
```

Beim ersten Mal steht im Terminal, dass der „VS Code Server" in Ubuntu installiert wird; das dauert eine halbe Minute. Dann öffnet sich ein VS-Code-Fenster mit dem Ordner `code`. Unten links im Fenster steht in einem grünen Feld `WSL: Ubuntu-24.04`. Genau das willst du sehen: VS Code arbeitet jetzt in Ubuntu.

> 💡 **Für Einsteiger:** `mkdir -p ~/code` legt den Ordner `code` in deinem Linux-Zuhause an (`~` ist die Abkürzung für `/home/<dein-name>`). `cd ~/code` wechselt hinein. `code .` heisst „öffne VS Code mit dem aktuellen Ordner" (der Punkt steht für „hier"). Ab jetzt öffnest du jedes Projekt so: im Terminal in den Projektordner wechseln, `code .` tippen.

Deine persönlichen VS-Code-Einstellungen auf der Windows-Seite (Farbschema, Tastenkürzel, Windows-Extensions) liegen **nicht** im dotfiles-Repo. Damit sie auf einem neuen Rechner wieder da sind, schalte **Settings Sync** ein: unten links auf das Personen-Symbol (Accounts) klicken → „Backup and Sync Settings…" → mit deinem GitHub-Konto anmelden. Die Einstellungen für die Arbeit in Ubuntu (Ruff, Python, Formatierung) kommen dagegen aus `vscode/settings.json` im Repo.

Meldet Ubuntu `code: command not found`, schliesse alle Terminalfenster, führe in der PowerShell `wsl --shutdown` aus und öffne Ubuntu neu. Ubuntu übernimmt Windows-Programme in seinen Suchpfad, das klappt aber erst nach einem Neustart von WSL. Weitere Hilfe in [99-troubleshooting.md](99-troubleshooting.md).

### 7. Docker Desktop (optional)

Docker Desktop brauchst du nur, wenn du mit Containern arbeitest (Datenbanken, Webanwendungen). Einsteiger können diesen Schritt auslassen und später nachholen.

Voraussetzungen laut Docker: Windows 11 ab 23H2 oder Windows 10 ab 22H2 (Pro, Enterprise oder Education), WSL ab Version 2.1.5, 8 GB RAM. Anleitung und Download: <https://docs.docker.com/desktop/setup/install/windows-install/>.

1. `Docker Desktop Installer.exe` starten. Wenn gefragt wird, „Use WSL 2 instead of Hyper-V" anhaken.
2. Docker Desktop startet nach der Installation **nicht** von selbst. Windows-Taste, `Docker` tippen, „Docker Desktop" öffnen. Der Erststart dauert etwa eine Minute; das Konto-Login kannst du überspringen.
3. WSL-Integration einschalten: Zahnrad oben rechts (Settings) → „Resources" → „WSL integration" → Schalter bei `Ubuntu-24.04` einschalten → „Apply & restart".

Prüfen im Ubuntu-Terminal:

```bash
docker --version
```

Erwartete Ausgabe: `Docker version 2x.y.z, build ...`. Der Befehl `docker` in Ubuntu funktioniert **nur, solange Docker Desktop auf Windows läuft**. Ist es geschlossen, meldet Ubuntu `docker: command not found`, und beim Öffnen eines Terminals kann eine harmlose Meldung mit `_docker` erscheinen. Beides ist in [99-troubleshooting.md](99-troubleshooting.md) erklärt.

Weg 1 installiert Docker Desktop per `winget` (Paket `Docker.DockerDesktop`), die WSL-Integration schaltest du trotzdem von Hand ein.

### 8. Claude-Desktop-App und ChatGPT-App (optional)

Beide Apps sind Ergänzungen zu den Terminal-Werkzeugen, die in [02-installation.md](02-installation.md) installiert werden. Sie brauchen dieselben Konten.

- **Claude-Desktop-App:** <https://claude.com/download> öffnen, „Windows" wählen, Installer ausführen, mit dem Claude-Konto anmelden. Die App kann Claude Code in einem eigenen Reiter starten und auf Projekte in Ubuntu zugreifen; Details in [04-claude-code.md](04-claude-code.md). Weg 1 installiert sie per `winget` (Paket `Anthropic.Claude`).
- **ChatGPT-App:** Microsoft Store öffnen (Windows-Taste, `Store` tippen), nach `ChatGPT` suchen und die App des Herausgebers OpenAI installieren. Alternativ genügt <https://chatgpt.com> im Browser. Wofür ChatGPT neben Claude nützlich ist, steht in [05-chatgpt-codex.md](05-chatgpt-codex.md).

### 9. Weitere Windows-Programme (optional)

Das sind die übrigen Programme von Elias' Rechner. Für die Entwicklungsumgebung braucht es sie nicht; Einsteiger können den Abschnitt überspringen. Installieren kannst du jedes einzeln in der PowerShell:

| Programm | Wozu | Befehl |
|---|---|---|
| Git für Windows | Git direkt unter Windows (in Ubuntu nicht nötig) | `winget install -e --id Git.Git --accept-package-agreements --accept-source-agreements` |
| GitHub Desktop | Git mit grafischer Oberfläche | `winget install -e --id GitHub.GitHubDesktop --accept-package-agreements --accept-source-agreements` |
| Notepad++ | Schneller Texteditor | `winget install -e --id Notepad++.Notepad++ --accept-package-agreements --accept-source-agreements` |
| 7-Zip | Archive entpacken (zip, 7z, tar) | `winget install -e --id 7zip.7zip --accept-package-agreements --accept-source-agreements` |
| DataGrip | Datenbank-Werkzeug von JetBrains (Lizenz nötig, für Studierende gratis) | `winget install -e --id JetBrains.DataGrip --accept-package-agreements --accept-source-agreements` |
| Zotero | Literaturverwaltung | `winget install -e --id DigitalScholar.Zotero --accept-package-agreements --accept-source-agreements` |
| Ollama | KI-Modelle lokal ausführen | `winget install -e --id Ollama.Ollama --accept-package-agreements --accept-source-agreements` |

## Dateien: Wo liegt was?

Windows und Ubuntu haben getrennte Dateisysteme, sehen sich aber gegenseitig:

| Von | Nach | Pfad |
|---|---|---|
| Ubuntu | Windows-Laufwerk `C:` | `/mnt/c`, zum Beispiel `/mnt/c/Users/<WindowsName>/Downloads` |
| Windows-Explorer | Ubuntu-Zuhause | `\\wsl.localhost\Ubuntu-24.04\home\<name>` in die Adresszeile eintippen. Unter Windows 11 gibt es im Explorer links zusätzlich den Eintrag „Linux". |
| Ubuntu-Terminal | aktuellen Ordner im Explorer öffnen | `explorer.exe .` (Punkt nicht vergessen) |

**Faustregel: Projekte immer im Linux-Zuhause ablegen**, also unter `~/code/...`, niemals unter `/mnt/c/...`. Zugriffe über die Grenze hinweg sind viel langsamer; Git, Python, VS Code und Claude Code arbeiten dann spürbar zäh oder finden Dateien nicht. Von Windows aus erreichst du die Projekte jederzeit über den Netzwerkpfad oben.

> 💡 **Für Einsteiger:** Stell dir Ubuntu wie einen zweiten Computer im selben Gehäuse vor, der einen Netzwerkordner freigibt. Was du in Ubuntu speicherst, liegt in `\\wsl.localhost\...`; was du in Windows speicherst, sieht Ubuntu unter `/mnt/c`. Für alles, was mit Programmieren zu tun hat, arbeitest du auf der Ubuntu-Seite.

## Häufige Stolpersteine

**Virtualisierung deaktiviert, Fehler `0x80370102` („The virtual machine could not be started because a required feature is not installed").**
Ursache: Im BIOS/UEFI ist die Virtualisierung aus, oder die Windows-Funktion „VM-Plattform" (Virtual Machine Platform) fehlt. Lösung: Rechner neu starten und mit der vom Hersteller genannten Taste (oft F2, F10, Entf oder Esc) ins BIOS/UEFI. Dort die Option „Intel Virtualization Technology" / „VT-x" bzw. bei AMD „SVM Mode" auf „Enabled" stellen, speichern, neu starten. Ändere im BIOS nichts anderes. Anschliessend in Windows: Windows-Taste, `Windows-Features aktivieren oder deaktivieren` tippen, „VM-Plattform" und „Windows-Subsystem für Linux" anhaken, OK, neu starten. Danach den Installationsbefehl wiederholen.

**`WslRegisterDistribution failed with error: 0x8007019e`, `0x80070003` oder `0x80370102`.**
Ursache: Die WSL-Funktion ist nicht eingeschaltet, der Neustart nach der Installation fehlt oder die Virtualisierung ist aus. Lösung: Neustart nachholen, dann in der Admin-PowerShell `wsl --update` und erneut `wsl --install -d Ubuntu-24.04`. Bleibt der Fehler, wie im Punkt oben die Virtualisierung und die Windows-Funktionen prüfen.

**Passwort vergessen.**
In der PowerShell Ubuntu als `root` (Linux-Administrator) starten, dort das Passwort deines Benutzers neu setzen und `root` wieder verlassen:

```powershell
wsl -d Ubuntu-24.04 -u root
```

```bash
passwd elias
```

```bash
exit
```

Ersetze `elias` durch deinen Linux-Benutzernamen. `passwd` fragt zweimal nach dem neuen Passwort (blind).

**Die Distribution heisst nur „Ubuntu".**
`wsl -l -v` zeigt den echten Namen. Verwende ihn überall, wo hier `Ubuntu-24.04` steht, auch im Explorer-Pfad `\\wsl.localhost\Ubuntu\home\<name>`.

**Ubuntu-Fenster geht sofort wieder zu oder zeigt einen Fehler mit `Wsl/Service/...`.**
In der PowerShell `wsl --shutdown`, dann `wsl --update`, dann Ubuntu erneut öffnen. Hilft das nicht, Windows neu starten. Weitere Fälle in [99-troubleshooting.md](99-troubleshooting.md).

**`wsl --install` zeigt nur die Hilfe.**
WSL ist schon da. Weiter mit `wsl --list --online` und `wsl --install -d Ubuntu-24.04` wie in Schritt 1 beschrieben.

## Checkliste

Hake ab, bevor du mit [02-installation.md](02-installation.md) weitermachst:

- [ ] `wsl -l -v` in der PowerShell zeigt `Ubuntu-24.04` (oder `Ubuntu`) mit VERSION `2`.
- [ ] Ubuntu öffnet sich aus dem Startmenü und zeigt den Prompt `<name>@<pc>:~$`.
- [ ] Du kennst deinen Linux-Benutzernamen und dein Linux-Passwort.
- [ ] `sudo apt update && sudo apt upgrade -y` ist einmal komplett durchgelaufen.
- [ ] Windows Terminal öffnet standardmässig Ubuntu.
- [ ] VS Code ist auf Windows installiert, die Extension „WSL" ist drin, und `code .` aus Ubuntu öffnet ein Fenster mit `WSL: Ubuntu-24.04` unten links.
- [ ] Optional: Docker Desktop läuft, WSL-Integration für Ubuntu ist an, `docker --version` antwortet.
- [ ] Optional: Claude-Desktop-App und ChatGPT-App sind installiert.
- [ ] Du hast ein GitHub-Konto und ein Claude-Konto (Pro oder Max).

## Weiter geht es

Mit [02-installation.md](02-installation.md): Dort installierst du mit einem einzigen Befehl die komplette Entwicklungsumgebung in Ubuntu.
