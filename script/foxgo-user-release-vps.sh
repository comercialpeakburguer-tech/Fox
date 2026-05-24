#!/usr/bin/env bash
set -Eeuo pipefail

BRANCH="${FOXGO_BRANCH:-foxgo/user-web-v39-sync}"
REPO_URL="${FOXGO_REPO_URL:-https://github.com/comercialpeakburguer-tech/Fox.git}"
WORKDIR="${FOXGO_WORKDIR:-/opt/foxgo/user-app-web}"
WEB_TARGET="${FOXGO_WEB_TARGET:-/var/www/foxgo-user-web}"
APK_TARGET="${FOXGO_APK_TARGET:-/opt/foxgo/releases}"
PROJECT_DIR="$WORKDIR/User app and web"
STAMP="$(date +%Y%m%d-%H%M%S)"

log() { printf '\n\033[1;32m[FOXGO]\033[0m %s\n' "$*"; }
warn() { printf '\n\033[1;33m[FOXGO]\033[0m %s\n' "$*"; }
fail() { printf '\n\033[1;31m[FOXGO]\033[0m %s\n' "$*" >&2; exit 1; }

command -v git >/dev/null 2>&1 || fail "git não encontrado na VPS"
command -v flutter >/dev/null 2>&1 || fail "flutter não encontrado na VPS"

log "Preparando código em $WORKDIR branch $BRANCH"
if [ ! -d "$WORKDIR/.git" ]; then
  mkdir -p "$(dirname "$WORKDIR")"
  git clone --branch "$BRANCH" "$REPO_URL" "$WORKDIR"
else
  cd "$WORKDIR"
  git fetch origin "$BRANCH"
  git checkout "$BRANCH"
  git reset --hard "origin/$BRANCH"
fi

cd "$PROJECT_DIR"

log "Limpando e instalando dependências Flutter"
flutter clean
flutter pub get

log "Validando código Dart"
flutter analyze

log "Gerando APK release"
flutter build apk --release
mkdir -p "$APK_TARGET"
cp -f build/app/outputs/flutter-apk/app-release.apk "$APK_TARGET/fox-go-$STAMP.apk"
cp -f build/app/outputs/flutter-apk/app-release.apk "$APK_TARGET/fox-go-latest.apk"

log "Gerando User Web release"
flutter build web --release

log "Publicando User Web em $WEB_TARGET"
if [ -d "$WEB_TARGET" ] && [ "$(ls -A "$WEB_TARGET" 2>/dev/null || true)" ]; then
  mkdir -p "$WEB_TARGET.backups"
  tar -C "$WEB_TARGET" -czf "$WEB_TARGET.backups/backup-$STAMP.tar.gz" . || true
fi
mkdir -p "$WEB_TARGET"
rsync -a --delete build/web/ "$WEB_TARGET/"

if command -v chown >/dev/null 2>&1; then
  chown -R www-data:www-data "$WEB_TARGET" 2>/dev/null || true
fi

if command -v nginx >/dev/null 2>&1; then
  nginx -t && systemctl reload nginx || warn "Nginx não recarregado; revise nginx -t manualmente"
elif command -v apache2ctl >/dev/null 2>&1; then
  apache2ctl configtest && systemctl reload apache2 || warn "Apache não recarregado; revise apache2ctl configtest manualmente"
fi

log "Release finalizado"
log "APK: $APK_TARGET/fox-go-latest.apk"
log "User Web: $WEB_TARGET"
