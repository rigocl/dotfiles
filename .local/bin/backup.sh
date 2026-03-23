#!/bin/bash
# Backup script for home directory to Synology NAS
#
# To force a re-run (e.g., after skipping or for testing):
#   rm ~/.local/state/backup-last-run

set -euo pipefail

BACKUP_DEST="/mnt/nas/backup/rigo-arch"
LOG_FILE="$BACKUP_DEST/backup.log"
STATE_FILE="$HOME/.local/state/backup-last-run"
LOCK_FILE="$HOME/.local/state/backup.lock"
IDLE_THRESHOLD=300000  # 5 minutes in milliseconds

# Ensure required directories exist
mkdir -p "$(dirname "$STATE_FILE")"

# Prevent duplicate runs
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "Backup already running, exiting"
    exit 0
fi

# Skip if already backed up today
TODAY=$(date '+%Y-%m-%d')
if [ -f "$STATE_FILE" ] && [ "$(cat "$STATE_FILE")" = "$TODAY" ]; then
    exit 0
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

notify() {
    # Get display and dbus session for notifications from systemd
    export DISPLAY="${DISPLAY:-:0}"
    export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/$(id -u)/bus}"
    notify-send -a "Backup" "$1" "$2"
}

# Check idle time (skip if user is active)
IDLE_TIME=$(xprintidle 2>/dev/null || echo "999999999")
if [ "$IDLE_TIME" -lt "$IDLE_THRESHOLD" ]; then
    log "User is active (idle: ${IDLE_TIME}ms), skipping backup"
    exit 0
fi

# Check if NAS is mounted
if ! mountpoint -q /mnt/nas; then
    log "ERROR: NAS not mounted at /mnt/nas"
    notify "Backup Failed" "NAS not mounted at /mnt/nas"
    exit 1
fi

# Ensure backup destination exists
mkdir -p "$BACKUP_DEST"

notify "Backup Started" "Backing up /home to NAS..."
log "Starting backup..."

# Generate package list
pacman -Qe > ~/package-list.txt
log "Package list saved"

# Sync home directory
rsync -avhz --delete --partial \
    --exclude='.cache' \
    --exclude='.config/chromium' \
    --exclude='.config/discord' \
    --exclude='.local/share/baloo' \
    --exclude='.local/share/claude' \
    --exclude='.local/share/lutris' \
    --exclude='.local/share/nvim' \
    --exclude='.local/share/Steam' \
    --exclude='.local/share/Trash' \
    --exclude='.mozilla/firefox/Crash Reports' \
    --exclude='.mozilla/firefox/Pending Pings' \
    --exclude='.mozilla/firefox/*/storage' \
    --exclude='.mozilla/firefox/*/gmp-*' \
    --exclude='.mozilla/firefox/*/datareporting' \
    --exclude='.mozilla/firefox/*/security_state' \
    --exclude='.var/app' \
    --exclude='Games' \
    /home/ "$BACKUP_DEST/home/" || {
    rc=$?
    # Exit code 23 = partial transfer (symlinks failed on NAS) - acceptable
    if [ $rc -ne 23 ]; then
        log "ERROR: rsync failed with code $rc"
        exit $rc
    fi
    log "Warning: some symlinks could not be copied (NAS limitation)"
}

log "Backup completed successfully"
notify "Backup Complete" "Logs: $LOG_FILE"

# Mark today as done
echo "$TODAY" > "$STATE_FILE"
