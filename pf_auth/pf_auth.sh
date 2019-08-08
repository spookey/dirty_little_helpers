#!/usr/bin/env sh

THIS_DIR="$(cd "$(/usr/bin/dirname "$0")" || exit 1; /bin/pwd)"

PF_TBL=${PF_TBL:-"tbl_sshauth_block"}
FILTER=${FILTER:-"$THIS_DIR/filter_ipaddr.py"}
PYTHON=${PYTHON:-"/usr/local/bin/python2"}
EXPIRE=${EXPIRE:-"86400"}

AUTH_LOGS="$*"

# shows error message and quits
_fatal() { >&2 echo "$*"; exit 1; }

# check if pf is available - e.g. while booting
[ ! -e "/dev/pf" ] && _fatal "pf is not available"

# check if log files were provided
[ -z "$AUTH_LOGS" ] && _fatal "please specify log file(s)"

# check if we may access the log files
for AUTH_LOG in $AUTH_LOGS; do
    [ ! -r "$AUTH_LOG" ] && _fatal "log file not accessible" "$AUTH_LOG"
done

# grep all failed sshd connections from the logs
# collect all addresses that occur more than five times
# and add them to the table
for AUTH_LOG in $AUTH_LOGS; do
    /usr/bin/grep -ie 'sshd.*failed' "$AUTH_LOG" |
    $PYTHON "$FILTER" -a 5 |
    /sbin/pfctl -q -t "$PF_TBL" -T add -f -
done

# remove old entries
/sbin/pfctl -q -t "$PF_TBL" -T expire "$EXPIRE"

exit 0
