#!/usr/bin/env sh

FROM=${FROM:-""}
RCPT=${RCPT:-""}
SUBJ=${SUBJ:-""}
PAUSE=${PAUSE:-"0"}

TIME=$(/bin/date -Iseconds)

# output
_msg() { >&2 echo "$*"; }
_fatal() { _msg "$*"; exit 1; }

# shows usage information and quits
_usage() {
    _msg "usage: $0 [-f from] [-r recipient] [-s subject] [-p num] [-h] log"
    _msg "  -f      specify sender mail address"
    _msg "  -r      specify recipient mail address"
    _msg "  -s      specify mail subject"
    _msg "  -p      defer log collecting some seconds"
    _msg "  -h      show this help and exit"
    _msg " log      full path to the (compressed) log file"
    [ -n "$*" ] && _fatal "$*"
    exit 0
}

# parse arguments
while getopts ":f:r:s:p:h" OPT "$@"; do
    case $OPT in
        f)  FROM="$OPTARG"                          ;;
        r)  RCPT="$OPTARG"                          ;;
        s)  SUBJ="$OPTARG"                          ;;
        p)  PAUSE="$OPTARG"                         ;;
        h)  _usage                                  ;;
        :)  _usage "-$OPTARG" "needs an argument"   ;;
        \?) _usage "invalid option" "-$OPTARG"      ;;
    esac
done
shift $(( OPTIND - 1 ))

LOG_FILE="$1"

# validate input
[ -z "$FROM" ] && _usage "sender mail address missing"
[ -z "$RCPT" ] && _usage "recipient mail address missing"
[ -z "$SUBJ" ] && _usage "mail subject missing"
case "$PAUSE" in
    ''|*[!0-9]*)  _usage "pause must be a number"   ;;
esac
[ -z "$LOG_FILE" ] && _usage "log file missing"
[ ! -f "$LOG_FILE" ] && _fatal "log file" "$LOG_FILE" "does not exist"

# give newsyslog some time to rotate
sleep "$PAUSE"

# collect log file content
CONTENT=$(/usr/bin/zcat "$LOG_FILE")
# skip on empty content
[ -z "$CONTENT" ] && exit 0

# compose and send mail
{
    echo "From: $FROM"
    echo "To: $RCPT"
    echo "Subject: $SUBJ $TIME"
    echo "Content-Type: text/html"
    echo
    echo "<div>$LOG_FILE</div>"
    echo "<div><pre>$CONTENT</pre></div>"
} | /usr/sbin/sendmail -t
exit $?
