#!/usr/bin/env bash
#
# install.sh – Haupt-Installer für die Entwicklungsumgebung (WSL 2 + Ubuntu).
#
# Richtet in 12 Schritten ein: apt-Pakete, zsh + oh-my-zsh, Python (pyenv + uv + ruff),
# Node (nvm), Claude Code (primär) und Codex CLI (optional), VS-Code-Extensions,
# Symlinks auf die Konfigurationsdateien dieses Repos sowie /etc/wsl.conf.
#
# Das Skript ist idempotent: ein zweiter Lauf ändert nichts und meldet
# "übersprungen (bereits vorhanden)". Alle schreibenden Aktionen laufen über
# run() bzw. run_sh(), damit --dry-run sie nur anzeigt, statt sie auszuführen.
#
# Hilfe:      ./install.sh --help
# Trockenlauf: ./install.sh --dry-run -y
#
set -euo pipefail
IFS=$'\n\t'

# ------------------------------------------------------------------------------
# Konstanten und Standardwerte
# ------------------------------------------------------------------------------
# Repo-Ordner pfadunabhängig ermitteln (funktioniert auch über Symlinks).
DOTFILES_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
readonly DOTFILES_DIR
readonly TOTAL_STEPS=12

# nvm-Version: neueste Veröffentlichung laut https://github.com/nvm-sh/nvm/releases
# (geprüft am 2026-09-23). Die nvm-README empfiehlt, eine feste Version zu verwenden.
readonly NVM_VERSION="v0.40.8"

# Über Umgebungsvariablen anpassbar:
PYTHON_VERSION="${PYTHON_VERSION:-3.12}"   # Präfix genügt, pyenv nimmt die neueste 3.12.x
GIT_NAME="${GIT_NAME:-}"                   # für -y; sonst wird gefragt
GIT_EMAIL="${GIT_EMAIL:-}"                 # für -y; sonst wird gefragt
BACKUP_DIR="${DOTFILES_BACKUP_DIR:-$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)}"

# Werkzeuge, die dieses Skript installiert, sofort im PATH haben (ohne Shell-Neustart).
export PYENV_ROOT="$HOME/.pyenv"
export NVM_DIR="$HOME/.nvm"
export PATH="$HOME/.local/bin:$PYENV_ROOT/bin:$PATH"

# Flags
ASSUME_YES=0
LINKS_ONLY=0
SKIP_APT=0
SKIP_PYTHON=0
SKIP_NODE=0
SKIP_AI=0
SKIP_VSCODE=0
SKIP_WSLCONF=0
NO_CODEX=0
DRY_RUN=0

# Laufzeit-Zustand
# $USER ist nicht überall gesetzt (z. B. su/docker exec) – aus id ableiten, sonst bricht set -u ab.
: "${USER:=$(id -un)}"
IS_WSL=0
WANT_CODEX=1
WANT_WSLCONF=1
BACKUP_USED=0
WSLCONF_WRITTEN=0
CHSH_DONE=0
SUDO_KEEPALIVE_PID=""
CURRENT_STEP=""
DELIBERATE_EXIT=0
DONE=()
SKIPPED=()
NEXT_STEPS=()
APT_MISSING=()

# ------------------------------------------------------------------------------
# Ausgabe-Helfer (Farben nur, wenn stdout ein Terminal ist)
# ------------------------------------------------------------------------------
if [[ -t 1 ]]; then
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_BLUE=$'\033[34m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_RESET=$'\033[0m'
else
  C_RED="" C_GREEN="" C_YELLOW="" C_BLUE="" C_BOLD="" C_DIM="" C_RESET=""
fi

info() { local IFS=' '; printf '%s==>%s %s\n' "$C_BLUE" "$C_RESET" "$*"; }
ok()   { local IFS=' '; printf '%s✅ %s%s\n' "$C_GREEN" "$*" "$C_RESET"; }
warn() { local IFS=' '; printf '%s⚠️  %s%s\n' "$C_YELLOW" "$*" "$C_RESET"; }
err()  { local IFS=' '; printf '%s❌ %s%s\n' "$C_RED" "$*" "$C_RESET" >&2; }

# step "N/12 Titel" – Überschrift eines Schritts
step() {
  local IFS=' '
  local num="${1%% *}" title="${1#* }"
  CURRENT_STEP="$1"
  printf '\n%s──── Schritt %s: %s ────%s\n' "$C_BOLD" "$num" "$title" "$C_RESET"
}

# Ein ganzer Schritt wird wegen eines Flags übersprungen.
skip_step() {
  info "übersprungen ($1)"
  SKIPPED+=("${CURRENT_STEP#* } – $1")
}

mark_done()    { DONE+=("$1"); }
mark_skipped() { SKIPPED+=("$1"); }

# Kontrollierter Abbruch mit Meldung (ohne die generische Fehlermeldung des EXIT-Traps).
die() {
  err "$@"
  DELIBERATE_EXIT=1
  exit 1
}

on_exit() {
  local rc=$?
  if [[ -n $SUDO_KEEPALIVE_PID ]]; then
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
  fi
  if [[ $rc -ne 0 && $DELIBERATE_EXIT -eq 0 ]]; then
    if [[ $rc -eq 130 ]]; then
      err "Abgebrochen (Ctrl+C) in Schritt ${CURRENT_STEP:-Start}."
    else
      err "Abgebrochen mit Fehlercode $rc in Schritt ${CURRENT_STEP:-Start}."
    fi
    err "Der Installer ist idempotent – einfach erneut ausführen, er macht dort weiter, wo etwas fehlt."
  fi
}
trap on_exit EXIT

# ------------------------------------------------------------------------------
# Ausführungs-Helfer (respektieren --dry-run)
# ------------------------------------------------------------------------------
# run BEFEHL ARG... – führt einen einzelnen Befehl aus (oder zeigt ihn nur an).
run() {
  local IFS=' '
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '%s[dry-run]%s %s\n' "$C_DIM" "$C_RESET" "$*"
    return 0
  fi
  "$@"
}

# run_sh "PIPELINE" – für Befehle mit Pipes/Umleitungen (curl ... | bash). Läuft in einer
# frischen bash ohne set -e/-u, weil Fremdskripte (nvm.sh, Installer) das nicht vertragen.
run_sh() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '%s[dry-run]%s %s\n' "$C_DIM" "$C_RESET" "$1"
    return 0
  fi
  # pipefail: ein fehlgeschlagenes curl in "curl ... | bash" muss den ganzen Befehl scheitern lassen.
  bash -o pipefail -c "$1"
}

# sudo einmal vorab entsperren und im Hintergrund wach halten (nur wenn nötig, nie im dry-run).
need_sudo() {
  [[ $DRY_RUN -eq 1 ]] && return 0
  [[ -n $SUDO_KEEPALIVE_PID ]] && return 0
  info "Für apt bzw. /etc/wsl.conf wird sudo benötigt – bitte dein Linux-Passwort eingeben."
  sudo -v
  (
    while kill -0 "$$" 2>/dev/null; do
      sudo -n true 2>/dev/null || true
      sleep 50
    done
  ) &
  SUDO_KEEPALIVE_PID=$!
}

# Zeilen einer Paketliste liefern: Kommentare (#) und Leerzeilen entfernt, Leerraum getrimmt.
read_list() {
  [[ -f $1 ]] || return 0
  sed -e 's/#.*$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e '/^$/d' "$1" | tr -d '\r'
}

# Elternordner eines Pfads anlegen, falls er fehlt (über run, damit --dry-run greift).
ensure_parent_dir() {
  local parent
  parent="$(dirname "$1")"
  if [[ ! -d $parent ]]; then
    run mkdir -p "$parent"
  fi
}

# Leerraum am Anfang/Ende einer Eingabe entfernen.
trim() {
  local s="$1"
  s="${s#"${s%%[![:space:]]*}"}"
  s="${s%"${s##*[![:space:]]}"}"
  printf '%s' "$s"
}

# ask VARIABLE "Frage" "Vorgabe" – Textfrage; mit -y wird die Vorgabe genommen.
ask() {
  local var="$1" prompt="$2" default="${3:-}" answer
  if [[ $ASSUME_YES -eq 1 ]]; then
    printf -v "$var" '%s' "$default"
    return 0
  fi
  while true; do
    if [[ -n $default ]]; then
      read -r -p "$prompt [$default]: " answer || die "Eingabe abgebrochen."
    else
      read -r -p "$prompt: " answer || die "Eingabe abgebrochen."
    fi
    answer="$(trim "${answer:-$default}")"
    if [[ -n $answer ]]; then
      break
    fi
    warn "Bitte einen Wert eingeben (Pflichtfeld)."
  done
  printf -v "$var" '%s' "$answer"
}

# ask_yes_no "Frage" j|n – Ja/Nein-Frage; Rückgabe 0 = Ja. Mit -y gilt die Vorgabe.
ask_yes_no() {
  local prompt="$1" default="${2:-j}" answer hint="[J/n]"
  [[ $default == n ]] && hint="[j/N]"
  if [[ $ASSUME_YES -eq 1 ]]; then
    [[ $default == j ]]
    return
  fi
  read -r -p "$prompt $hint " answer || die "Eingabe abgebrochen."
  answer="$(trim "${answer:-$default}")"
  [[ $answer =~ ^[jJyY] ]]
}

# ------------------------------------------------------------------------------
# Hilfe
# ------------------------------------------------------------------------------
usage() {
  cat <<EOF
${C_BOLD}dotfiles – install.sh${C_RESET}
Richtet die komplette Entwicklungsumgebung unter WSL 2 / Ubuntu ein (idempotent).

${C_BOLD}Verwendung:${C_RESET}
  ./install.sh [Optionen]

${C_BOLD}Optionen (kombinierbar):${C_RESET}
  -y, --yes         keine Rückfragen, Standardantworten verwenden
  --links-only      nur Symlinks/Kopien setzen (Schritt 10), nichts installieren
  --skip-apt        Schritt 3 (apt-Pakete, GitHub-CLI-Repo) überspringen
  --skip-python     Schritt 5 (pyenv, Python $PYTHON_VERSION) überspringen
  --skip-node       Schritt 7 (nvm, Node LTS) überspringen
  --skip-ai         Schritt 8 (Claude Code, Codex CLI) überspringen
  --skip-vscode     Schritt 9 (VS-Code-Extensions) überspringen
  --skip-wslconf    Schritt 11 (/etc/wsl.conf) überspringen
  --no-codex        Codex CLI nicht installieren (Standard: fragen, Vorgabe Ja)
  --dry-run         alle Aktionen nur anzeigen ([dry-run] ...), nichts ausführen;
                    braucht weder sudo noch Netz und schreibt nichts
  -h, --help        diese Hilfe anzeigen

${C_BOLD}Umgebungsvariablen:${C_RESET}
  GIT_NAME, GIT_EMAIL    Git-Identität für ~/.gitconfig.local (nützlich mit -y)
  PYTHON_VERSION         Python-Version für pyenv (Standard: 3.12 = neueste 3.12.x)
  DOTFILES_BACKUP_DIR    Ablage für ersetzte Dateien (Standard: ~/.dotfiles-backup/<Datum-Zeit>)

${C_BOLD}Die 12 Schritte:${C_RESET}
   1 Vorprüfungen            7 Node via nvm (LTS)
   2 Fragen                  8 Claude Code (+ optional Codex CLI)
   3 apt-Pakete              9 VS-Code-Extensions (WSL-Seite)
   4 zsh + oh-my-zsh        10 Symlinks auf die Repo-Dateien (Backup vorhandener Dateien)
   5 Python (pyenv)         11 /etc/wsl.conf (systemd, Standardbenutzer)
   6 uv + Tools (ruff, ...) 12 Zusammenfassung und nächste Schritte

${C_BOLD}Beispiele:${C_RESET}
  ./install.sh                         # interaktiv, alles
  ./install.sh -y                      # ohne Rückfragen
  ./install.sh --links-only -y         # nur Konfigurationsdateien neu verlinken
  ./install.sh --dry-run -y            # zeigen, was passieren würde
  GIT_NAME="Max Muster" GIT_EMAIL="max@example.com" ./install.sh -y

Repo: $DOTFILES_DIR
EOF
}

# ------------------------------------------------------------------------------
# Argumente
# ------------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes)        ASSUME_YES=1 ;;
    --links-only)    LINKS_ONLY=1 ;;
    --skip-apt)      SKIP_APT=1 ;;
    --skip-python)   SKIP_PYTHON=1 ;;
    --skip-node)     SKIP_NODE=1 ;;
    --skip-ai)       SKIP_AI=1 ;;
    --skip-vscode)   SKIP_VSCODE=1 ;;
    --skip-wslconf)  SKIP_WSLCONF=1 ;;
    --no-codex)      NO_CODEX=1; WANT_CODEX=0 ;;
    --dry-run)       DRY_RUN=1 ;;
    -h|--help)       usage; DELIBERATE_EXIT=1; exit 0 ;;
    *)
      err "Unbekannte Option: $1"
      usage >&2
      DELIBERATE_EXIT=1
      exit 2
      ;;
  esac
  shift
done

if [[ $LINKS_ONLY -eq 1 ]]; then
  SKIP_APT=1 SKIP_PYTHON=1 SKIP_NODE=1 SKIP_AI=1 SKIP_VSCODE=1 SKIP_WSLCONF=1
fi

# ------------------------------------------------------------------------------
# Fach-Helfer
# ------------------------------------------------------------------------------
apt_installed() {
  # shellcheck disable=SC2016  # ${Status} ist ein dpkg-Format, kein Shell-Ausdruck
  dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -q 'ok installed'
}

wslconf_has_systemd() {
  grep -Eqs '^[[:space:]]*systemd[[:space:]]*=[[:space:]]*true' /etc/wsl.conf
}

compute_apt_missing() {
  local pkg
  APT_MISSING=()
  local pkgs=()
  mapfile -t pkgs < <(read_list "$DOTFILES_DIR/packages/apt.txt")
  for pkg in "${pkgs[@]}"; do
    apt_installed "$pkg" || APT_MISSING+=("$pkg")
  done
}

# Codex vorhanden? Auch eine npm-Installation im nvm-Ordner zählt (die liegt nicht im PATH des Skripts).
have_codex() {
  command -v codex >/dev/null 2>&1 || compgen -G "${NVM_DIR:-$HOME/.nvm}/versions/node/*/bin/codex" >/dev/null
}

# Pfad relativ zu $HOME mit "~" anzeigen.
pretty() {
  local p="$1"
  if [[ $p == "$HOME"* ]]; then
    printf '~%s' "${p#"$HOME"}"
  else
    printf '%s' "$p"
  fi
}

# Bestehende Datei/Ordner in den Backup-Ordner verschieben (Pfadstruktur unterhalb ~ erhalten).
backup_path() {
  local src="$1" rel dest
  rel="${src#"$HOME"/}"
  [[ $rel == "$src" ]] && rel="${src#/}"
  dest="$BACKUP_DIR/$rel"
  ensure_parent_dir "$dest"
  run mv "$src" "$dest"
  BACKUP_USED=1
  info "gesichert: $(pretty "$src") -> $(pretty "$dest")"
}

# link_file QUELLE ZIEL – Symlink mit Backup-Semantik:
#   Ziel ist Symlink auf die Quelle      -> übersprungen
#   Ziel ist Symlink woandershin/tot     -> ersetzen
#   Ziel ist echte Datei/Ordner          -> ins Backup verschieben, dann verlinken
link_file() {
  local src="$1" dst="$2" src_real dst_real
  if [[ ! -e $src ]]; then
    warn "Quelle fehlt im Repo: ${src#"$DOTFILES_DIR"/} – $(pretty "$dst") wird nicht verlinkt"
    return 0
  fi
  src_real="$(readlink -f "$src")"
  if [[ -L $dst ]]; then
    dst_real="$(readlink -f "$dst" 2>/dev/null || true)"
    if [[ $dst_real == "$src_real" ]]; then
      ok "übersprungen (bereits verlinkt): $(pretty "$dst")"
      return 0
    fi
    info "ersetze Symlink $(pretty "$dst") (zeigte auf: $(readlink "$dst"))"
    run ln -sfn "$src" "$dst"
    ok "verlinkt: $(pretty "$dst") -> ${src#"$DOTFILES_DIR"/}"
    mark_done "verlinkt: $(pretty "$dst")"
    return 0
  fi
  if [[ -e $dst ]]; then
    backup_path "$dst"
  fi
  ensure_parent_dir "$dst"
  run ln -sfn "$src" "$dst"
  ok "verlinkt: $(pretty "$dst") -> ${src#"$DOTFILES_DIR"/}"
  mark_done "verlinkt: $(pretty "$dst")"
}

# copy_if_missing QUELLE ZIEL – Kopie (kein Link) anlegen, wenn das Ziel noch nicht existiert.
copy_if_missing() {
  local src="$1" dst="$2"
  if [[ -e $dst || -L $dst ]]; then
    ok "übersprungen (bereits vorhanden): $(pretty "$dst")"
    return 0
  fi
  if [[ ! -f $src ]]; then
    warn "Quelle fehlt im Repo: ${src#"$DOTFILES_DIR"/} – $(pretty "$dst") wird nicht erzeugt"
    return 0
  fi
  ensure_parent_dir "$dst"
  run cp "$src" "$dst"
  ok "erzeugt (Kopie): $(pretty "$dst") aus ${src#"$DOTFILES_DIR"/}"
  mark_done "erzeugt: $(pretty "$dst")"
}

# ~/.gitconfig.local aus der Vorlage erzeugen und Name/E-Mail einsetzen. Nie überschreiben.
create_gitconfig_local() {
  local src="$DOTFILES_DIR/git/gitconfig.local.example" dst="$HOME/.gitconfig.local" content
  if [[ -e $dst || -L $dst ]]; then
    ok "übersprungen (bereits vorhanden): ~/.gitconfig.local"
    return 0
  fi
  if [[ ! -f $src ]]; then
    warn "Quelle fehlt im Repo: git/gitconfig.local.example – ~/.gitconfig.local wird nicht erzeugt"
    return 0
  fi
  if [[ -z $GIT_NAME || -z $GIT_EMAIL ]]; then
    warn "Git-Name/E-Mail unbekannt – ~/.gitconfig.local wird nicht erzeugt."
    NEXT_STEPS+=("Git-Identität setzen: GIT_NAME=\"Dein Name\" GIT_EMAIL=\"du@example.com\" ./install.sh --links-only -y")
    return 0
  fi
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '%s[dry-run]%s erzeuge ~/.gitconfig.local aus git/gitconfig.local.example (Name: %s, E-Mail: %s)\n' \
      "$C_DIM" "$C_RESET" "$GIT_NAME" "$GIT_EMAIL"
    return 0
  fi
  content="$(<"$src")"
  content="${content//__GIT_NAME__/$GIT_NAME}"
  content="${content//__GIT_EMAIL__/$GIT_EMAIL}"
  printf '%s\n' "$content" > "$dst"
  ok "erzeugt: ~/.gitconfig.local (Name: $GIT_NAME, E-Mail: $GIT_EMAIL)"
  mark_done "erzeugt: ~/.gitconfig.local"
}

# ==============================================================================
# Schritt 1/12 – Vorprüfungen
# ==============================================================================
step "1/$TOTAL_STEPS Vorprüfungen"

if [[ $DRY_RUN -eq 1 ]]; then
  info "Trockenlauf (--dry-run): es wird nichts installiert, geschrieben oder heruntergeladen."
fi

# Betriebssystem
OS_ID=""
if [[ -r /etc/os-release ]]; then
  OS_ID="$(. /etc/os-release && printf '%s' "${ID:-}")"
fi
case "$OS_ID" in
  ubuntu|debian)
    ok "Betriebssystem: $(. /etc/os-release && printf '%s' "${PRETTY_NAME:-$OS_ID}")"
    ;;
  *)
    die "Dieses Skript ist für Ubuntu/Debian gedacht (gefunden: '${OS_ID:-unbekannt}'). Bitte unter WSL mit Ubuntu 24.04 ausführen."
    ;;
esac

# Nicht als root
if [[ $EUID -eq 0 ]]; then
  die "Bitte nicht als root ausführen. Starte das Skript als normaler Benutzer – sudo wird bei Bedarf abgefragt."
fi

# WSL?
# WSL erkennen: Umgebungsvariable oder Interop-Eintrag (fehlt in Docker-Containern, die nur den WSL-Kernel teilen).
if [[ -n ${WSL_DISTRO_NAME:-} || -e /proc/sys/fs/binfmt_misc/WSLInterop ]] \
  || { grep -qi microsoft /proc/version 2>/dev/null && [[ ! -f /.dockerenv ]]; }; then
  IS_WSL=1
  ok "WSL erkannt"
else
  warn "Kein WSL erkannt – der Installer läuft weiter, /etc/wsl.conf wird übersprungen."
fi

# curl und git
for tool in curl git; do
  if command -v "$tool" >/dev/null 2>&1; then
    ok "$tool vorhanden"
  elif [[ $DRY_RUN -eq 1 ]]; then
    warn "$tool fehlt (im echten Lauf: zuerst bootstrap.sh ausführen oder 'sudo apt-get install -y git curl ca-certificates')"
  else
    die "$tool fehlt. Bitte zuerst bootstrap.sh ausführen oder: sudo apt-get install -y git curl ca-certificates"
  fi
done

info "Repo-Ordner: $(pretty "$DOTFILES_DIR")"

# ==============================================================================
# Schritt 2/12 – Fragen (alle vor den langen Installationen)
# ==============================================================================
step "2/$TOTAL_STEPS Fragen"

if [[ $ASSUME_YES -eq 0 && ! -t 0 ]]; then
  warn "Keine interaktive Eingabe möglich (stdin ist kein Terminal) – Standardantworten wie bei -y."
  ASSUME_YES=1
fi

# Git-Identität: Vorgabe aus der bestehenden globalen Git-Konfiguration lesen –
# BEVOR ~/.gitconfig in Schritt 10 neu verlinkt wird.
if [[ -z $GIT_NAME ]]; then
  GIT_NAME="$(git config --global user.name 2>/dev/null || true)"
fi
if [[ -z $GIT_EMAIL ]]; then
  GIT_EMAIL="$(git config --global user.email 2>/dev/null || true)"
fi

if [[ -e $HOME/.gitconfig.local || -L $HOME/.gitconfig.local ]]; then
  ok "Datei ~/.gitconfig.local existiert bereits – keine Frage nach Name/E-Mail"
else
  if [[ $ASSUME_YES -eq 0 ]]; then
    info "Diese Angaben landen in ~/.gitconfig.local (Autor deiner Commits)."
  fi
  ask GIT_NAME "Dein Name für Git" "$GIT_NAME"
  while true; do
    ask GIT_EMAIL "Deine E-Mail für Git" "$GIT_EMAIL"
    if [[ $ASSUME_YES -eq 1 || $GIT_EMAIL == *@* ]]; then
      break
    fi
    warn "Das sieht nicht nach einer E-Mail-Adresse aus – bitte erneut eingeben."
    GIT_EMAIL=""
  done
  if [[ -n $GIT_NAME && -n $GIT_EMAIL ]]; then
    ok "Git-Identität: $GIT_NAME <$GIT_EMAIL>"
  else
    warn "Git-Identität unbekannt (setze GIT_NAME/GIT_EMAIL oder starte ohne -y)."
  fi
fi

# Codex CLI?
if [[ $SKIP_AI -eq 0 && $NO_CODEX -eq 0 ]]; then
  if have_codex; then
    WANT_CODEX=1
    ok "Codex CLI ist bereits installiert – keine Frage"
  elif ask_yes_no "Codex CLI (ChatGPT) zusätzlich zu Claude Code installieren?" j; then
    WANT_CODEX=1
    ok "Codex CLI: ja"
  else
    WANT_CODEX=0
    info "Codex CLI: nein"
  fi
fi
# Ohne Schritt 8 (--skip-ai, --links-only) wird Codex in diesem Lauf nicht installiert:
# dann zählt in Schritt 10 und 12 nur, ob codex bereits vorhanden ist.
if [[ $SKIP_AI -eq 1 ]]; then
  WANT_CODEX=0
fi

# /etc/wsl.conf?
if [[ $IS_WSL -eq 1 && $SKIP_WSLCONF -eq 0 ]]; then
  if wslconf_has_systemd; then
    WANT_WSLCONF=0
    ok "/etc/wsl.conf enthält bereits systemd=true – keine Frage"
  elif ask_yes_no "/etc/wsl.conf schreiben (systemd aktivieren, Standardbenutzer $USER setzen)?" j; then
    WANT_WSLCONF=1
    ok "wsl.conf: ja"
  else
    WANT_WSLCONF=0
    info "wsl.conf: nein"
  fi
else
  WANT_WSLCONF=0
fi

# sudo jetzt entsperren, damit alle Passwortabfragen zusammen am Anfang kommen.
if [[ $SKIP_APT -eq 0 ]]; then
  compute_apt_missing
fi
if [[ ( $SKIP_APT -eq 0 && ${#APT_MISSING[@]} -gt 0 ) || $WANT_WSLCONF -eq 1 ]]; then
  need_sudo
fi

if [[ $ASSUME_YES -eq 1 ]]; then
  info "Keine weiteren Rückfragen (-y bzw. nicht interaktiv)."
fi

# ==============================================================================
# Schritt 3/12 – apt-Pakete
# ==============================================================================
step "3/$TOTAL_STEPS apt-Pakete"

if [[ $SKIP_APT -eq 1 ]]; then
  skip_step "$([[ $LINKS_ONLY -eq 1 ]] && printf -- '--links-only' || printf -- '--skip-apt')"
elif [[ ! -f $DOTFILES_DIR/packages/apt.txt ]]; then
  warn "packages/apt.txt fehlt im Repo – keine apt-Pakete installiert."
elif [[ ${#APT_MISSING[@]} -eq 0 ]]; then
  ok "übersprungen (bereits vorhanden): alle Pakete aus packages/apt.txt sind installiert"
  mark_skipped "apt-Pakete (alle vorhanden)"
else
  # GitHub-CLI-Apt-Repo (offizielle Anleitung: github.com/cli/cli/blob/trunk/docs/install_linux.md)
  if grep -rqs 'cli.github.com' /etc/apt/sources.list.d/ /etc/apt/sources.list 2>/dev/null \
    && [[ -s /etc/apt/keyrings/githubcli-archive-keyring.gpg ]]; then
    ok "übersprungen (bereits vorhanden): GitHub-CLI-Apt-Repo"
  else
    info "richte das GitHub-CLI-Apt-Repo ein (für das Paket gh)"
    run sudo mkdir -p -m 755 /etc/apt/keyrings
    run_sh "curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null"
    run sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    run sudo mkdir -p -m 755 /etc/apt/sources.list.d
    run_sh "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null"
    mark_done "GitHub-CLI-Apt-Repo eingerichtet"
  fi

  info "fehlende Pakete (${#APT_MISSING[@]}): $(IFS=' '; printf '%s' "${APT_MISSING[*]}")"
  run sudo apt-get update
  run sudo apt-get install -y "${APT_MISSING[@]}"
  # Ein schon vorhandenes Ubuntu-gh auf die Version aus dem GitHub-Apt-Repo heben (ohne neuere Version: nichts).
  run sudo apt-get install -y --only-upgrade gh
  if [[ $DRY_RUN -eq 0 ]]; then
    ok "apt-Pakete installiert"
  fi
  mark_done "apt-Pakete: $(IFS=' '; printf '%s' "${APT_MISSING[*]}")"
fi

# Locale en_US.UTF-8 erzeugen: zsh/zshrc setzt LANG darauf und fällt sonst still auf C.UTF-8 zurück.
if [[ $SKIP_APT -eq 0 ]]; then
  if [[ -n "$(locale -a 2>/dev/null | grep -iE '^en_US\.utf-?8$' || true)" ]]; then
    ok "übersprungen (bereits vorhanden): Locale en_US.UTF-8"
  elif command -v locale-gen >/dev/null 2>&1 || [[ $DRY_RUN -eq 1 ]]; then
    need_sudo
    run sudo locale-gen en_US.UTF-8
    mark_done "Locale en_US.UTF-8 erzeugt"
  else
    warn "locale-gen fehlt (Paket locales) – Locale en_US.UTF-8 nicht erzeugt; zshrc nutzt C.UTF-8."
  fi
fi

# ==============================================================================
# Schritt 4/12 – zsh + oh-my-zsh
# ==============================================================================
step "4/$TOTAL_STEPS zsh + oh-my-zsh"

if [[ $LINKS_ONLY -eq 1 ]]; then
  skip_step "--links-only"
else
  ZSH_BIN="$(command -v zsh 2>/dev/null || true)"
  if [[ -z $ZSH_BIN && $DRY_RUN -eq 1 ]]; then
    ZSH_BIN="/usr/bin/zsh"   # im Trockenlauf annehmen, dass apt zsh installiert hätte
  fi

  if [[ -z $ZSH_BIN ]]; then
    warn "zsh ist nicht installiert (apt übersprungen?) – oh-my-zsh und chsh werden übersprungen."
  else
    # oh-my-zsh unattended: CHSH=no (Shell wechseln wir selbst), RUNZSH=no (nicht sofort zsh starten),
    # KEEP_ZSHRC=yes (bestehende ~/.zshrc nicht ersetzen – wird in Schritt 10 verlinkt).
    if [[ -d $HOME/.oh-my-zsh ]]; then
      ok "übersprungen (bereits vorhanden): oh-my-zsh"
    else
      info "installiere oh-my-zsh"
      run_sh 'RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"'
      mark_done "oh-my-zsh installiert"
    fi

    # Custom-Plugins
    ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
      plugin_dir="$ZSH_CUSTOM_DIR/plugins/$plugin"
      if [[ -d $plugin_dir ]]; then
        ok "übersprungen (bereits vorhanden): Plugin $plugin"
      else
        info "installiere Plugin $plugin"
        run git clone --depth=1 "https://github.com/zsh-users/$plugin" "$plugin_dir"
        mark_done "zsh-Plugin $plugin"
      fi
    done

    # Login-Shell
    CURRENT_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || true)"
    CURRENT_SHELL="${CURRENT_SHELL:-${SHELL:-}}"
    # kanonisch vergleichen: /bin/zsh und /usr/bin/zsh sind unter Ubuntu dieselbe Datei
    if [[ -n $CURRENT_SHELL && "$(readlink -f "$CURRENT_SHELL" 2>/dev/null || true)" == "$(readlink -f "$ZSH_BIN")" ]]; then
      ok "übersprungen (bereits vorhanden): Login-Shell ist zsh"
    else
      info "setze zsh als Login-Shell (chsh fragt nach deinem Linux-Passwort – unter WSL ohne sudo)"
      if run chsh -s "$ZSH_BIN"; then
        CHSH_DONE=1
        if [[ $DRY_RUN -eq 0 ]]; then
          ok "Login-Shell auf zsh gesetzt (gilt ab dem nächsten Terminal)"
        fi
        mark_done "Login-Shell: zsh"
      else
        warn "chsh fehlgeschlagen – später manuell: chsh -s $ZSH_BIN"
        NEXT_STEPS+=("Login-Shell manuell setzen: chsh -s $ZSH_BIN")
      fi
    fi
  fi
fi

# ==============================================================================
# Schritt 5/12 – Python (pyenv)
# ==============================================================================
step "5/$TOTAL_STEPS Python (pyenv $PYTHON_VERSION)"

if [[ $SKIP_PYTHON -eq 1 ]]; then
  skip_step "$([[ $LINKS_ONLY -eq 1 ]] && printf -- '--links-only' || printf -- '--skip-python')"
else
  if [[ -d $PYENV_ROOT ]]; then
    ok "übersprungen (bereits vorhanden): pyenv in ~/.pyenv"
  else
    info "installiere pyenv (inkl. pyenv-virtualenv) über pyenv.run"
    run_sh "curl -fsSL https://pyenv.run | bash"
    mark_done "pyenv installiert"
  fi

  # pyenv im laufenden Skript aktivieren (Shims), ohne Shell-Neustart.
  # Nicht im Trockenlauf: "pyenv init" führt ein rehash aus und legt ~/.pyenv/shims an.
  if [[ $DRY_RUN -eq 0 ]] && command -v pyenv >/dev/null 2>&1; then
    set +u
    eval "$(pyenv init - bash)"
    set -u
  fi

  # Installierte Version nur abfragen, wenn pyenv samt versions-Ordner schon da ist (reine Leseoperation).
  PY_TARGET=""
  if [[ -d $PYENV_ROOT/versions ]] && command -v pyenv >/dev/null 2>&1; then
    PY_TARGET="$(pyenv latest "$PYTHON_VERSION" 2>/dev/null || true)"
  fi

  if [[ -n $PY_TARGET ]]; then
    ok "übersprungen (bereits vorhanden): Python $PY_TARGET"
  else
    info "kompiliere Python $PYTHON_VERSION – das dauert einige Minuten (Kaffee holen ☕)"
    run pyenv install --skip-existing "$PYTHON_VERSION"
    if [[ $DRY_RUN -eq 1 ]]; then
      PY_TARGET="<neueste $PYTHON_VERSION.x>"
    else
      PY_TARGET="$(pyenv latest "$PYTHON_VERSION")"
    fi
    mark_done "Python $PY_TARGET (pyenv)"
  fi

  PY_GLOBAL=""
  if [[ -d $PYENV_ROOT/versions ]] && command -v pyenv >/dev/null 2>&1; then
    PY_GLOBAL="$(pyenv global 2>/dev/null | head -n1 || true)"
  fi
  if [[ $PY_GLOBAL == "$PY_TARGET" ]]; then
    ok "übersprungen (bereits vorhanden): pyenv global $PY_TARGET"
  else
    run pyenv global "$PY_TARGET"
    if [[ $DRY_RUN -eq 0 ]]; then
      ok "pyenv global -> $PY_TARGET"
    fi
    mark_done "pyenv global $PY_TARGET"
  fi
fi

# ==============================================================================
# Schritt 6/12 – uv + globale Tools
# ==============================================================================
step "6/$TOTAL_STEPS uv + Tools (packages/uv-tools.txt)"

if [[ $LINKS_ONLY -eq 1 ]]; then
  skip_step "--links-only"
else
  if command -v uv >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then
      ok "übersprungen (bereits vorhanden): uv"
    else
      ok "übersprungen (bereits vorhanden): uv $(uv --version 2>/dev/null | cut -d' ' -f2)"
    fi
  else
    # UV_NO_MODIFY_PATH=1: der Installer soll NICHT in unsere zshrc schreiben – sie setzt ~/.local/bin selbst.
    info "installiere uv"
    run_sh "curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh"
    mark_done "uv installiert"
  fi

  UV_TOOLS=()
  mapfile -t UV_TOOLS < <(read_list "$DOTFILES_DIR/packages/uv-tools.txt")
  if [[ ${#UV_TOOLS[@]} -eq 0 ]]; then
    warn "packages/uv-tools.txt fehlt oder ist leer – keine Tools installiert."
  else
    # Ausgabe von "uv tool list": pro Tool eine Zeile "name vX.Y.Z", darunter "- binary"-Zeilen.
    # Im Trockenlauf kein "uv tool list": uv legt dabei ~/.cache/uv an. Dann nur prüfen, ob das Binary im PATH ist.
    UV_INSTALLED=""
    if [[ $DRY_RUN -eq 1 ]]; then
      for tool in "${UV_TOOLS[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
          UV_INSTALLED+="$tool"$'\n'
        fi
      done
    elif command -v uv >/dev/null 2>&1; then
      UV_INSTALLED="$(uv tool list 2>/dev/null | awk '!/^-/ && NF {print $1}' || true)"
    fi
    for tool in "${UV_TOOLS[@]}"; do
      if grep -qx "$tool" <<<"$UV_INSTALLED"; then
        ok "übersprungen (bereits vorhanden): $tool"
      else
        info "installiere $tool"
        run uv tool install "$tool"
        mark_done "uv tool $tool"
      fi
    done
  fi
fi

# ==============================================================================
# Schritt 7/12 – Node via nvm
# ==============================================================================
step "7/$TOTAL_STEPS Node via nvm (LTS)"

if [[ $SKIP_NODE -eq 1 ]]; then
  skip_step "$([[ $LINKS_ONLY -eq 1 ]] && printf -- '--links-only' || printf -- '--skip-node')"
else
  if [[ -s $NVM_DIR/nvm.sh ]]; then
    ok "übersprungen (bereits vorhanden): nvm in ~/.nvm"
  else
    # PROFILE=/dev/null: nvm darf NICHT in unsere zshrc schreiben – der nvm-Block steht dort bereits.
    info "installiere nvm $NVM_VERSION"
    run_sh "curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$NVM_VERSION/install.sh | PROFILE=/dev/null bash"
    mark_done "nvm installiert"
  fi

  # nvm.sh verträgt kein set -u/-e, deshalb laufen nvm-Befehle in einer eigenen bash (run_sh).
  # Im Trockenlauf wird nvm.sh nicht geladen; dann genügt die Alias-Datei als Hinweis auf ein installiertes Node.
  NODE_DEFAULT=""
  if [[ -s $NVM_DIR/nvm.sh ]]; then
    if [[ $DRY_RUN -eq 1 ]]; then
      [[ -f $NVM_DIR/alias/default ]] && NODE_DEFAULT="v(laut ~/.nvm/alias/default)"
    else
      NODE_DEFAULT="$(bash -c ". \"$NVM_DIR/nvm.sh\" >/dev/null 2>&1; nvm version default 2>/dev/null" || true)"
    fi
  fi
  if [[ $NODE_DEFAULT == v* ]]; then
    ok "übersprungen (bereits vorhanden): Node $NODE_DEFAULT (nvm default)"
  else
    info "installiere Node LTS und setze es als Standard"
    run_sh ". \"$NVM_DIR/nvm.sh\" && nvm install --lts && nvm alias default 'lts/*'"
    mark_done "Node LTS (nvm)"
  fi
fi

# ==============================================================================
# Schritt 8/12 – KI-Werkzeuge: Claude Code (primär), Codex CLI (optional)
# ==============================================================================
step "8/$TOTAL_STEPS KI-Werkzeuge (Claude Code, Codex CLI)"

if [[ $SKIP_AI -eq 1 ]]; then
  skip_step "$([[ $LINKS_ONLY -eq 1 ]] && printf -- '--links-only' || printf -- '--skip-ai')"
else
  # Claude Code – native Installation (kein sudo, kein npm nötig), Launcher in ~/.local/bin/claude.
  if command -v claude >/dev/null 2>&1; then
    if [[ $DRY_RUN -eq 1 ]]; then
      ok "übersprungen (bereits vorhanden): Claude Code"
    else
      ok "übersprungen (bereits vorhanden): Claude Code $(claude --version 2>/dev/null | head -n1 || true)"
    fi
  else
    info "installiere Claude Code (nativ)"
    run_sh "curl -fsSL https://claude.ai/install.sh | bash"
    mark_done "Claude Code installiert"
  fi

  # Codex CLI – optional, nie mit sudo.
  if [[ $WANT_CODEX -eq 0 ]]; then
    info "Codex CLI: übersprungen (nicht gewünscht)"
    mark_skipped "Codex CLI (nicht gewünscht)"
  elif have_codex; then
    ok "übersprungen (bereits vorhanden): Codex CLI"
  else
    info "installiere Codex CLI"
    # CODEX_NON_INTERACTIVE=1: sonst fragt der Installer am Ende «Start Codex now?» und wartet.
    if run_sh "curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh"; then
      mark_done "Codex CLI installiert"
    else
      warn "Codex-Installer fehlgeschlagen."
      if [[ -s $NVM_DIR/nvm.sh ]] || command -v npm >/dev/null 2>&1; then
        info "versuche Alternative: npm install -g @openai/codex"
        if run_sh ". \"$NVM_DIR/nvm.sh\" >/dev/null 2>&1; npm install -g @openai/codex"; then
          mark_done "Codex CLI installiert (npm)"
        else
          warn "Auch npm-Installation fehlgeschlagen – später manuell: curl -fsSL https://chatgpt.com/codex/install.sh | sh"
          NEXT_STEPS+=("Codex CLI manuell installieren: curl -fsSL https://chatgpt.com/codex/install.sh | sh")
        fi
      else
        warn "npm nicht verfügbar – später manuell: curl -fsSL https://chatgpt.com/codex/install.sh | sh"
        NEXT_STEPS+=("Codex CLI manuell installieren: curl -fsSL https://chatgpt.com/codex/install.sh | sh")
      fi
    fi
  fi
fi

# ==============================================================================
# Schritt 9/12 – VS-Code-Extensions (WSL-Seite)
# ==============================================================================
step "9/$TOTAL_STEPS VS-Code-Extensions"

if [[ $SKIP_VSCODE -eq 1 ]]; then
  skip_step "$([[ $LINKS_ONLY -eq 1 ]] && printf -- '--links-only' || printf -- '--skip-vscode')"
elif ! command -v code >/dev/null 2>&1; then
  warn "'code' ist in WSL nicht verfügbar. So holst du die Extensions später nach:"
  info "  1. VS Code auf Windows installieren (windows/setup.ps1 oder https://code.visualstudio.com)"
  info "  2. Ein neues WSL-Terminal öffnen und in einem Projektordner 'code .' ausführen (installiert den VS-Code-Server)"
  info "  3. Dann: ./install.sh --skip-apt --skip-python --skip-node --skip-ai"
  mark_skipped "VS-Code-Extensions (code nicht verfügbar)"
  NEXT_STEPS+=("VS-Code-Extensions nachholen: ./install.sh --skip-apt --skip-python --skip-node --skip-ai")
else
  VSCODE_EXTS=()
  mapfile -t VSCODE_EXTS < <(read_list "$DOTFILES_DIR/packages/vscode-extensions.txt")
  if [[ ${#VSCODE_EXTS[@]} -eq 0 ]]; then
    warn "packages/vscode-extensions.txt fehlt oder ist leer – keine Extensions installiert."
  else
    # Im Trockenlauf kein "code --list-extensions": das würde den VS-Code-Server nach ~/.vscode-server laden.
    VSCODE_INSTALLED=""
    if [[ $DRY_RUN -eq 1 ]]; then
      printf '%s[dry-run]%s code --list-extensions\n' "$C_DIM" "$C_RESET"
    else
      VSCODE_INSTALLED="$(code --list-extensions 2>/dev/null || true)"
      VSCODE_INSTALLED="${VSCODE_INSTALLED,,}"
    fi
    for ext in "${VSCODE_EXTS[@]}"; do
      if grep -qx "${ext,,}" <<<"$VSCODE_INSTALLED"; then
        ok "übersprungen (bereits vorhanden): $ext"
      else
        info "installiere Extension $ext"
        if run code --install-extension "$ext" --force; then
          mark_done "VS-Code-Extension $ext"
        else
          warn "Extension $ext konnte nicht installiert werden (ID prüfen, VS Code offen?)"
        fi
      fi
    done
  fi
fi

# ==============================================================================
# Schritt 10/12 – Verknüpfen (auch bei --links-only)
# ==============================================================================
step "10/$TOTAL_STEPS Konfigurationsdateien verknüpfen"

info "ersetzte Dateien landen in: $(pretty "$BACKUP_DIR")"

# zsh
link_file "$DOTFILES_DIR/zsh/zshrc"    "$HOME/.zshrc"
link_file "$DOTFILES_DIR/zsh/zprofile" "$HOME/.zprofile"
link_file "$DOTFILES_DIR/zsh/aliases"  "$HOME/.aliases"
copy_if_missing "$DOTFILES_DIR/zsh/zshrc.local.example" "$HOME/.zshrc.local"

# git
link_file "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
create_gitconfig_local

# ssh
if [[ -f $DOTFILES_DIR/ssh/config ]]; then
  if [[ ! -d $HOME/.ssh ]]; then
    run mkdir -p "$HOME/.ssh"
  fi
  run chmod 700 "$HOME/.ssh"
  run chmod 600 "$DOTFILES_DIR/ssh/config"
fi
link_file "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"

# VS Code (Machine-Settings der WSL-Seite; Ordner existiert erst nach dem ersten Start, wir legen ihn an)
link_file "$DOTFILES_DIR/vscode/settings.json" "$HOME/.vscode-server/data/Machine/settings.json"

# Relikte des alten Le-Wagon-Repos, die dieses Repo nicht mehr mitbringt (keybindings.json, rspec):
# nach einem Umzug des alten Ordners zeigen ihre Symlinks ins Leere. Nur solche toten Links entfernen,
# echte Dateien und funktionierende Links bleiben unangetastet.
for legacy_link in "$HOME/.vscode-server/data/Machine/keybindings.json" "$HOME/.rspec"; do
  if [[ -L $legacy_link && ! -e $legacy_link ]]; then
    info "entferne toten Relikt-Link $(pretty "$legacy_link") (zeigte auf: $(readlink "$legacy_link"))"
    run rm -f "$legacy_link"
    mark_done "entfernt: $(pretty "$legacy_link")"
  fi
done

# Claude Code
link_file "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
link_file "$DOTFILES_DIR/claude/CLAUDE.md"     "$HOME/.claude/CLAUDE.md"
link_file "$DOTFILES_DIR/claude/rules"         "$HOME/.claude/rules"

# Codex (nur wenn gewünscht oder bereits installiert)
if [[ $WANT_CODEX -eq 1 ]] || have_codex; then
  link_file "$DOTFILES_DIR/codex/config.toml" "$HOME/.codex/config.toml"
else
  info "Codex nicht gewünscht – ~/.codex/config.toml wird nicht verlinkt"
fi

# ==============================================================================
# Schritt 11/12 – /etc/wsl.conf
# ==============================================================================
step "11/$TOTAL_STEPS /etc/wsl.conf"

if [[ $SKIP_WSLCONF -eq 1 ]]; then
  skip_step "$([[ $LINKS_ONLY -eq 1 ]] && printf -- '--links-only' || printf -- '--skip-wslconf')"
elif [[ $IS_WSL -eq 0 ]]; then
  info "kein WSL – übersprungen"
  mark_skipped "/etc/wsl.conf (kein WSL)"
elif wslconf_has_systemd; then
  ok "übersprungen (bereits vorhanden): /etc/wsl.conf enthält systemd=true"
elif [[ $WANT_WSLCONF -eq 0 ]]; then
  info "übersprungen (nicht gewünscht)"
  mark_skipped "/etc/wsl.conf (nicht gewünscht)"
elif [[ ! -f $DOTFILES_DIR/wsl/wsl.conf ]]; then
  warn "wsl/wsl.conf fehlt im Repo – /etc/wsl.conf wird nicht geschrieben."
else
  need_sudo
  WSL_USER="${USER:-$(id -un)}"
  if [[ -f /etc/wsl.conf ]]; then
    info "sichere bestehende /etc/wsl.conf nach /etc/wsl.conf.bak"
    run sudo cp /etc/wsl.conf /etc/wsl.conf.bak
  fi
  info "schreibe /etc/wsl.conf (systemd=true, default=$WSL_USER)"
  run_sh "sed 's/__USER__/$WSL_USER/g' \"$DOTFILES_DIR/wsl/wsl.conf\" | sudo tee /etc/wsl.conf >/dev/null"
  WSLCONF_WRITTEN=1
  if [[ $DRY_RUN -eq 0 ]]; then
    ok "/etc/wsl.conf geschrieben"
  fi
  mark_done "/etc/wsl.conf"
  warn "Damit die Änderung wirkt: in PowerShell 'wsl --shutdown' ausführen, dann WSL neu öffnen."
fi

# ==============================================================================
# Schritt 12/12 – Zusammenfassung
# ==============================================================================
step "12/$TOTAL_STEPS Zusammenfassung"

if [[ $DRY_RUN -eq 1 ]]; then
  info "Trockenlauf beendet – es wurde nichts verändert. Ohne --dry-run würden die oben gezeigten Aktionen ausgeführt."
fi

if [[ ${#DONE[@]} -gt 0 ]]; then
  printf '\n%sInstalliert / geändert%s:\n' "$C_BOLD" "$C_RESET"
  for item in "${DONE[@]}"; do
    printf '  • %s\n' "$item"
  done
else
  printf '\n%sInstalliert / geändert%s: nichts – alles war bereits vorhanden.\n' "$C_BOLD" "$C_RESET"
fi

if [[ ${#SKIPPED[@]} -gt 0 ]]; then
  printf '\n%sÜbersprungen%s:\n' "$C_BOLD" "$C_RESET"
  for item in "${SKIPPED[@]}"; do
    printf '  • %s\n' "$item"
  done
fi

if [[ $BACKUP_USED -eq 1 && $DRY_RUN -eq 1 ]]; then
  printf '\n%sBackup%s: ersetzte Dateien würden nach %s verschoben (Trockenlauf, nichts verschoben).\n' \
    "$C_BOLD" "$C_RESET" "$(pretty "$BACKUP_DIR")"
elif [[ $BACKUP_USED -eq 1 ]]; then
  printf '\n%sBackup%s: ersetzte Dateien liegen in %s\n' "$C_BOLD" "$C_RESET" "$(pretty "$BACKUP_DIR")"
  printf '  Wenn alles läuft, kannst du den Ordner löschen.\n'
fi

printf '\n%sNächste Schritte%s:\n' "$C_BOLD" "$C_RESET"
n=1
next() { printf '  %d. %s\n' "$n" "$1"; n=$((n + 1)); }
if [[ $WSLCONF_WRITTEN -eq 1 ]]; then
  next "In PowerShell 'wsl --shutdown' ausführen und WSL neu öffnen (aktiviert systemd)."
fi
if [[ $CHSH_DONE -eq 1 ]]; then
  next "Terminal schliessen und neu öffnen (neue Login-Shell zsh), oder sofort: exec zsh"
else
  next "Terminal neu öffnen oder 'exec zsh' ausführen, damit zshrc, PATH und Aliasse aktiv sind."
fi
next "GitHub anmelden: gh auth login  (GitHub.com, HTTPS, Login with a web browser) – danach: gh auth setup-git"
next "Claude Code anmelden: 'claude' starten, Browser-Login abschliessen; prüfen mit: claude doctor"
if [[ $WANT_CODEX -eq 1 ]]; then
  next "Codex CLI anmelden: 'codex' starten und 'Sign in with ChatGPT' wählen."
fi
next "Ein Projekt in VS Code öffnen: cd ~/code/<projekt> && code .  (installiert beim ersten Mal den VS-Code-Server)"
next "Prüfen: zsh --version, pyenv version, uv --version, ruff --version, node --version, claude --version, gh --version"
for item in "${NEXT_STEPS[@]}"; do
  next "$item"
done
printf '\nDokumentation: %s/docs/  (02-installation.md erklärt jeden Schritt)\n' "$(pretty "$DOTFILES_DIR")"
printf '%s✅ Fertig.%s\n' "$C_GREEN" "$C_RESET"
