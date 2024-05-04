#!/usr/bin/env sh

THIS_DIR="$(cd "$(/usr/bin/dirname "$0")" || exit 1; /bin/pwd)"

FILTER=${FILTER:-"$THIS_DIR/filter_ipaddr.py"}
PYTHON=${PYTHON:-"/usr/local/bin/python3"}

NUMBER=${NUMBER:-"5"}
EXPIRE=${EXPIRE:-"86400"}
PF_TBL=${PF_TBL:-"tbl_block"}

STAMP=$(/bin/date -Iseconds)

# output
_msg() { >&2 echo "$*"; }
_fatal() { _msg "$*"; exit 1; }

# shows usage information and quits
_usage() {
    _msg "usage: $0 [-n number] [-e number] [-t name] [-h] auth [auth [...]]"
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

# make sure parameters are indeed numbers
_numeric() {
    case $2 in
        ''|*[!0-9]*)    _usage "$1 must be a number"   ;;
    esac
}
_numeric "-n" "$NUMBER"
_numeric "-e" "$EXPIRE"

# check if log files were provided
[ -z "$AUTH_LOGS" ] && _usage "please specify log file(s)"

# check if we may access the log files
for AUTH_LOG in $AUTH_LOGS; do
    [ ! -r "$AUTH_LOG" ] && _fatal "log file not accessible" "$AUTH_LOG"
done


# collect only relevant parts of pf output and emit data if any
_report() {
    BUFFER=""
    while IFS= read -r LINE; do
        case $LINE in
            'No ALTQ'*)                                     ;;
            'ALTQ related'*)                                ;;
            '0/'*'addresses'*) return                       ;;
            *) BUFFER=$(printf "%s\n%s" "$BUFFER" "$LINE")  ;;
        esac
    done
    if [ -n "$(echo "$BUFFER" | /usr/bin/xargs)" ]; then
        printf "[ %s ] %s\n%s\n\n" "$STAMP" "$*" "$BUFFER"
    fi
}


# grep all failed sshd connections from the logs
# (see /etc/periodic/security/800.loginfail)
# collect all addresses that occur more than $NUMBER times
# and add them to the table
for AUTH_LOG in $AUTH_LOGS; do
    /usr/bin/grep -Eia "\b(fail(ures?|ed)?|invalid|bad|illegal|auth.*error)\b" "$AUTH_LOG" |
    $PYTHON "$FILTER" --amount "$NUMBER" |
    /sbin/pfctl -t "$PF_TBL" -vvT add -f - 2>&1 |
    _report "$PF_TBL" "add" "$AUTH_LOG"
done

# remove expired entries
/sbin/pfctl -t "$PF_TBL" -vvT expire "$EXPIRE" 2>&1 |
_report "$PF_TBL" "expire" "$EXPIRE"


exit 0
