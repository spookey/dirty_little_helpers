#!/usr/bin/env sh

THIS_DIR="$(cd "$(/usr/bin/dirname "$0")" || exit 1; /bin/pwd)"

# either that if wrapper is in same folder or full path
SCRIPT=${SCRIPT:-"$THIS_DIR/newsys_mail.sh"}

# sender mail address
export FROM="server@example.org"
# recipient mail address
export RCPT="somebody@example.org"
# mail subject
export SUBJ="newsys mail"
# defer log collecting some seconds
export PAUSE=0

# full path to file to be sent
$SCRIPT "/var/log/daemon.log.0.bz2"
exit $?
