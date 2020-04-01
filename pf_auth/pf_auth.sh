#!/usr/bin/env sh

THIS_DIR="$(cd "$(/usr/bin/dirname "$0")" || exit 1; /bin/pwd)"

FILTER=${FILTER:-"$THIS_DIR/filter_ipaddr.py"}
PYTHON=${PYTHON:-"/usr/local/bin/python3"}

NUMBER=${NUMBER:-"5"}
EXPIRE=${EXPIRE:-"86400"}
PF_TBL=${PF_TBL:-"tbl_block"}

# writes message to stderr
_msg() { >&2 echo "$*"; }

# shows error message and quits
_fatal() { _msg "$*"; exit 1; }

# shows usage information and quits
_usage() {
    _msg "usage: $0 [-n] [-e] [-t] [-h] auth [auth [...]]"
    _msg "  -n  addresses with min. occurrences"
    _msg "  -e  pf expire time in seconds"
    _msg "  -t  pf table name"
    _msg "  -h  show this help and quit"
    _msg "auth  path to auth.log file(s)"
    [ -n "$*" ] && _fatal "$*"
    exit 0
}

# parse arguments
while getopts ":t:e:n:h" OPT "$@"; do
    case $OPT in
        n)  NUMBER="$OPTARG"                    ;;
        e)  EXPIRE="$OPTARG"                    ;;
        t)  PF_TBL="$OPTARG"                    ;;
        h)  _usage                              ;;
        :)  _usage "-$OPTARG needs an argument" ;;
        \?) _usage "invalid option: -$OPTARG"   ;;
    esac
done
shift $(( OPTIND - 1 ))

AUTH_LOGS="$*"


# check if pf is available - e.g. while booting
[ ! -e "/dev/pf" ] && _fatal "pf is not available"

# check if log files were provided
[ -z "$AUTH_LOGS" ] && _fatal "please specify log file(s)"

# check if we may access the log files
for AUTH_LOG in $AUTH_LOGS; do
    [ ! -r "$AUTH_LOG" ] && _fatal "log file not accessible" "$AUTH_LOG"
done


# show only relevant parts of pf output
_report() {
    while IFS= read -r LINE; do
        case $LINE in
            'No ALTQ'*)                 ;;
            'ALTQ related'*)            ;;
            '0/'*'addresses'*) return   ;;
            *) _msg "$LINE"             ;;
        esac
    done
}

# grep all failed sshd connections from the logs
# collect all addresses that occur more than $NUMBER times
# and add them to the table
for AUTH_LOG in $AUTH_LOGS; do
    /usr/bin/grep -ie 'sshd.*\(failed\|invalid\)' "$AUTH_LOG" |
    $PYTHON "$FILTER" -a "$NUMBER" |
    /sbin/pfctl -t "$PF_TBL" -vvT add -f - 2>&1 | _report
done

# remove expired entries
/sbin/pfctl -t "$PF_TBL" -vvT expire "$EXPIRE" 2>&1 | _report

exit 0
