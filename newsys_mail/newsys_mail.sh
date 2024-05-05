#!/usr/bin/env sh

MAIL_FROM=${MAIL_FROM:-"$(/usr/bin/id -un)"}
MAIL_RCPT=${MAIL_RCPT:-""}
MAIL_SUBJ=${MAIL_SUBJ:-""}
COMPRESSION=${COMPRESSION:="raw"}
DEFER=${DEFER:-0}

STAMP=$(/bin/date -Iseconds)

# output
_msg() { >&2 echo "$*"; }
_fatal() { _msg "$*"; exit 1; }

# shows usage information and quits
_usage() {
    _msg "usage: $0 [-f from] [-t to] [-s subject] [-c alg] [-d num] [-h] log"
    _msg "  -f      specify sender mail address"
    _msg "  -t      specify recipient mail address"
    _msg "  -s      specify mail subject"
    _msg "  -c      compression format [r=raw] [bz] [gz] [xz] [z]"
    _msg "  -d      defer log collecting some seconds"
    _msg "  -h      show this help and exit"
    _msg " log      full path to the (compressed) log file"
    [ -n "$*" ] && _fatal "$*"
    exit 0
}

# parse arguments
while getopts ":f:t:s:c:d:h" OPT "$@"; do
    case $OPT in
        f)  MAIL_FROM="$OPTARG"                     ;;
        t)  MAIL_RCPT="$OPTARG"                     ;;
        s)  MAIL_SUBJ="$OPTARG"                     ;;
        c)  COMPRESSION="$OPTARG"                   ;;
        d)  DEFER="$OPTARG"                         ;;
        h)  _usage                                  ;;
        :)  _usage "-$OPTARG" "needs an argument"   ;;
        \?) _usage "invalid option" "-$OPTARG"      ;;
    esac
done
shift $(( OPTIND - 1 ))

LOG_FILE="$1"; shift
ARGS="$*"

# validate input
[ -z "$MAIL_FROM" ] && _usage "sender mail address missing"
[ -z "$MAIL_RCPT" ] && _usage "recipient mail address missing"
[ -z "$MAIL_SUBJ" ] && _usage "mail subject missing"
case "$DEFER" in
    ''|*[!0-9]*)  _usage "defer must be a number"   ;;
esac
[ -z "$LOG_FILE" ] && _usage "log file missing"

# parse reader for compressed format
READER=
case "$COMPRESSION" in
    z)      READER="/usr/bin/zcat"                  ;;
    xz)     READER="/usr/bin/xzcat"                 ;;
    gz)     READER="/usr/bin/gzcat"                 ;;
    bz)     READER="/usr/bin/bzcat"                 ;;
    r|raw)  READER="/bin/cat"                       ;;
    *)      _usage "unknown compression format"     ;;
esac

# give newsyslog some time to rotate
[ "$DEFER" -gt 0 ] && sleep "$DEFER"
# did the pause succeed?
[ ! -f "$LOG_FILE" ] && _fatal "log file" "$LOG_FILE" "does not exist"


# collect log file content
CONTENT=$($READER "$LOG_FILE")
# skip on empty content
[ -z "$CONTENT" ] && exit 0

# compose and send mail
{
    echo "From: $MAIL_FROM"
    echo "To: $MAIL_RCPT"
    echo "Subject: $MAIL_SUBJ $STAMP"
    echo "Content-Type: text/html"
    echo
    echo "<div>$LOG_FILE</div>"
    echo "<div><pre>$CONTENT</pre></div>"
    [ -n "$ARGS" ] && {
        echo
        echo "<div><small>$ARGS</small></div>"
    }
} | /usr/sbin/sendmail -t
exit $?
