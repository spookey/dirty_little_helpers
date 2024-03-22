#!/usr/bin/env sh

THIS_DIR="$(cd "$(/usr/bin/dirname "$0")" || exit 1; /bin/pwd)"

STAMP=$(/bin/date -Iseconds)

TARGET=${TARGET:="$THIS_DIR/pipe.log"}
STATUS=${STATUS:="23"}
EMIT=
NULL=
DROP=

# output
_msg() { >&2 echo "$*"; }
_fatal() { _msg "$*"; exit 1; }

# shows usage information and quits
_usage() {
    _msg "usage: $0 [-t path] [-r number] [-e] [-n] [-d] [-h]"
    _msg "  -t      specify backlog file target"
    _msg "  -r      specify error code after emit (should be < 255!)"
    _msg "  -e      emit log contents (instead of trying to collect)"
    _msg "  -n      skip if there is nothing worth emitting"
    _msg "  -d      drop log contents from target (after emit or skip)"
    _msg "  -h      show this help and exit"
    _msg
    _msg "collecting:"
    _msg "  /some/command 2>&1 | $0 -t /some/where.log"
    _msg
    [ -n "$*" ] && _fatal "$*"
    exit 0
}

# parse arguments
while getopts ":t:r:endh" OPT "$@"; do
    case $OPT in
        t)  TARGET="$OPTARG"                        ;;
        r)  STATUS="$OPTARG"                        ;;
        e)  EMIT=1                                  ;;
        n)  NULL=1                                  ;;
        d)  DROP=1                                  ;;
        h)  _usage                                  ;;
        :)  _usage "-$OPTARG" "needs an argument"   ;;
        \?) _usage "invalid option" "-$OPTARG"      ;;
    esac
done

# make sure status code is indeed a number
case $STATUS in
    ''|*[!0-9]*)    _usage "-r must be a number"   ;;
esac

# create backlog file
_clear() { :> "$TARGET"; }
[ ! -f "$TARGET" ] && _clear


# output content of the backlog file
if [ $EMIT ]; then
    CONTENT="$(/bin/cat "$TARGET")"

    # exit gracefully if no content and requested to do so
    if [ -z "$(echo "$CONTENT" | /usr/bin/xargs)" ]; then
        if [ $NULL ]; then
            exit 0
        fi
    fi

    printf "[[[ %s ]]]\n\n%s\n" "$STAMP" "$CONTENT"
    [ $DROP ] && _clear
    exit "$STATUS"
fi


# collect new content for the backlog file
CONTENT=""
while IFS= read -r LINE; do
    CONTENT="$(printf "%s\n%s" "$CONTENT" "$LINE")"
done

if [ -n "$(echo "$CONTENT" | /usr/bin/xargs)" ]; then
    printf "[   %s   ]\n%s\n\n" "$STAMP" "$CONTENT" >> "$TARGET"
fi

exit 0
