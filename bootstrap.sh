#!/usr/bin/env bash
#
# bootstrap.sh – Einzeiler-Einstieg für ein frisches WSL/Ubuntu.
#
# Stellt git, curl und ca-certificates sicher, klont das dotfiles-Repo und startet install.sh.
# Alle Argumente werden an install.sh durchgereicht (z. B. -y, --dry-run, --no-codex).
# Achtung: --dry-run wirkt nur auf install.sh – git/curl und das Klonen passieren trotzdem.
#
# Start aus dem Netz (nur wenn das Repo öffentlich ist):
#   bash <(curl -fsSL https://raw.githubusercontent.com/Elias-Martinelli/dotfiles/main/bootstrap.sh)
# oder lokal:
#   ./bootstrap.sh [Optionen für install.sh]
#
# Zielordner über DOTFILES_DIR anpassbar (Standard: ~/code/dotfiles).
#
set -euo pipefail

readonly REPO_SLUG="Elias-Martinelli/dotfiles"
readonly REPO_HTTPS="https://github.com/${REPO_SLUG}.git"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/code/dotfiles}"

info() { printf '==> %s\n' "$*"; }
ok()   { printf '✅ %s\n' "$*"; }
warn() { printf '⚠️  %s\n' "$*"; }
err()  { printf '❌ %s\n' "$*" >&2; }

usage() {
  cat <<EOF
bootstrap.sh – klont das dotfiles-Repo und startet install.sh

Verwendung:
  bash <(curl -fsSL https://raw.githubusercontent.com/${REPO_SLUG}/main/bootstrap.sh) [Optionen]
  ./bootstrap.sh [Optionen]

Alle Optionen werden an install.sh weitergereicht, z. B.:
  -y            keine Rückfragen
  --dry-run     install.sh zeigt nur an, was es tun würde (bootstrap.sh selbst
                installiert git/curl und klont das Repo trotzdem)
  --no-codex    Codex CLI nicht installieren
  (vollständige Liste: ./install.sh --help nach dem Klonen)

Umgebungsvariablen:
  DOTFILES_DIR  Zielordner für das Repo (Standard: ~/code/dotfiles)

Ablauf:
  1. Ubuntu/Debian prüfen, git + curl + ca-certificates per apt installieren, falls sie fehlen
  2. Repo ${REPO_SLUG} klonen (oder aktualisieren, wenn der Ordner schon existiert)
  3. install.sh im Repo starten
EOF
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

# ------------------------------------------------------------------------------
# 1. Vorprüfungen und Grundpakete
# ------------------------------------------------------------------------------
OS_ID=""
if [[ -r /etc/os-release ]]; then
  OS_ID="$(. /etc/os-release && printf '%s' "${ID:-}")"
fi
case "$OS_ID" in
  ubuntu|debian) ok "Betriebssystem: $(. /etc/os-release && printf '%s' "${PRETTY_NAME:-$OS_ID}")" ;;
  *)
    err "Dieses Skript ist für Ubuntu/Debian gedacht (gefunden: '${OS_ID:-unbekannt}')."
    err "Bitte in einem WSL-Terminal mit Ubuntu 24.04 ausführen (siehe docs/01-windows-vorbereiten.md)."
    exit 1
    ;;
esac

if [[ $EUID -eq 0 ]]; then
  err "Bitte nicht als root ausführen – als normaler Benutzer starten, sudo wird bei Bedarf abgefragt."
  exit 1
fi

MISSING=()
for tool in git curl; do
  command -v "$tool" >/dev/null 2>&1 || MISSING+=("$tool")
done
if [[ ! -f /etc/ssl/certs/ca-certificates.crt ]]; then
  MISSING+=("ca-certificates")
fi

if [[ ${#MISSING[@]} -gt 0 ]]; then
  info "Installiere Grundpakete: ${MISSING[*]} (sudo fragt nach deinem Linux-Passwort)"
  sudo apt-get update
  sudo apt-get install -y git curl ca-certificates
  ok "Grundpakete installiert"
else
  ok "git, curl und ca-certificates sind vorhanden"
fi

# ------------------------------------------------------------------------------
# 2. Repo klonen oder aktualisieren
# ------------------------------------------------------------------------------
if [[ -d $DOTFILES_DIR/.git ]]; then
  info "Repo existiert bereits in $DOTFILES_DIR – hole Aktualisierungen (git pull --ff-only)"
  if git -C "$DOTFILES_DIR" pull --ff-only; then
    ok "Repo aktualisiert"
  else
    warn "git pull nicht möglich (lokale Änderungen oder kein Netz) – verwende den vorhandenen Stand."
  fi
elif [[ -e $DOTFILES_DIR ]]; then
  err "$DOTFILES_DIR existiert, ist aber kein Git-Repo. Bitte Ordner verschieben oder DOTFILES_DIR anders setzen."
  exit 1
else
  mkdir -p "$(dirname "$DOTFILES_DIR")"
  CLONED=0
  # Bevorzugt gh (funktioniert auch bei privatem Repo, wenn eingeloggt).
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    info "Klone mit GitHub CLI: gh repo clone $REPO_SLUG $DOTFILES_DIR"
    if gh repo clone "$REPO_SLUG" "$DOTFILES_DIR"; then
      CLONED=1
    else
      warn "gh repo clone fehlgeschlagen – versuche git clone über HTTPS."
    fi
  fi
  if [[ $CLONED -eq 0 ]]; then
    info "Klone $REPO_HTTPS nach $DOTFILES_DIR"
    # GIT_TERMINAL_PROMPT=0: bei privatem Repo nicht nach Benutzername/Passwort fragen, sondern sauber abbrechen.
    if GIT_TERMINAL_PROMPT=0 git clone "$REPO_HTTPS" "$DOTFILES_DIR"; then
      CLONED=1
    fi
  fi
  if [[ $CLONED -eq 0 ]]; then
    err "Klonen fehlgeschlagen. Häufigste Ursache: das Repo $REPO_SLUG ist privat."
    err "Lösungen:"
    err "  a) GitHub CLI installieren und anmelden, dann bootstrap.sh erneut starten:"
    err "       sudo apt-get install -y gh   (oder siehe docs/06-git-github.md)"
    err "       gh auth login"
    err "  b) Das Repo auf GitHub öffentlich machen (Settings -> General -> Danger Zone -> Change visibility)."
    err "  c) Manuell klonen und danach ./install.sh starten:"
    err "       gh repo clone $REPO_SLUG $DOTFILES_DIR && cd $DOTFILES_DIR && ./install.sh"
    exit 1
  fi
  ok "Repo geklont nach $DOTFILES_DIR"
fi

# ------------------------------------------------------------------------------
# 3. install.sh starten (Argumente durchreichen)
# ------------------------------------------------------------------------------
if [[ ! -f $DOTFILES_DIR/install.sh ]]; then
  err "$DOTFILES_DIR/install.sh nicht gefunden – ist das wirklich das dotfiles-Repo?"
  exit 1
fi

info "Starte install.sh $*"
cd "$DOTFILES_DIR"
exec bash "$DOTFILES_DIR/install.sh" "$@"
