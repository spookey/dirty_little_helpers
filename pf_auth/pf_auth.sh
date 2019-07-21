#!/usr/bin/env sh

THIS_DIR="$(cd "$(/usr/bin/dirname "$0")" || exit 1; /bin/pwd)"

PF_TBL=${PF_TBL:-"tbl_sshauth_block"}
FILTER=${FILTER:-"$THIS_DIR/filter_ipaddr.py"}
PYTHON=${PYTHON:-"/usr/local/bin/python2"}
AUTH_LOG=${AUTH_LOG:-"/var/log/auth.log"}

# check if pf is available - e.g. while booting
if [ ! -e "/dev/pf" ]; then
    >&2 echo "pf is not available!"
    exit 1
fi

# check if we can access the auth.log
if [ ! -r "$AUTH_LOG" ]; then
    >&2 echo "auth.log not accessible: $AUTH_LOG"
    exit 1
fi

# grep all failed sshd connections from the auth log
# collect all addresses that occur more than five times
# and add them to the table
for ADDR in $(
        /usr/bin/grep sshd "$AUTH_LOG" |
        /usr/bin/grep failed |
        $PYTHON "$FILTER" -aaaaa
); do
    /sbin/pfctl -t "$PF_TBL" -T add "$ADDR"
done

# remove entries older than 1 day
/sbin/pfctl -t "$PF_TBL" -T expire 86400

exit 0
