#!/usr/bin/env sh

THIS_DIR="$(cd "$(/usr/bin/dirname "$0")" || exit 1; /bin/pwd)"

# either that if wrapper is in same folder or full path
SCRIPT=${SCRIPT:-"$THIS_DIR/file_mail.sh"}

# sender mail address
MAIL_FROM="server@example.org"
# recipient mail address
MAIL_RCPT="somebody@example.org"
# mail subject
MAIL_SUBJ="newsys mail"
# compressed file format (raw bz gz xz z)
COMPRESSION="bz"
# defer log collecting for some seconds
DEFER=0
# full path to log file
LOG_FILE="/var/log/daemon.log.0.bz2"

# trigger sending mail
$SCRIPT \
    -f "$MAIL_FROM" \
    -t "$MAIL_RCPT" \
    -s "$MAIL_SUBJ" \
    -c "$COMPRESSION" \
    -d "$DEFER" \
    "$LOG_FILE"
exit $?
