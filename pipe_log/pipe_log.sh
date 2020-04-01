#!/usr/bin/env sh

THIS_DIR="$(cd "$(/usr/bin/dirname "$0")" || exit 1; /bin/pwd)"

STAMP=$(/bin/date '+%Y-%m-%d %H:%M:%S')

TARGET="$THIS_DIR/pipe.log"
STATUS=23
EMIT=
NULL=
DROP=

_usage() {
    echo "usage: $0 [-t ...] [-r ...] [-e] [-n] [-d] [-h]"
    echo "  -t      specify backlog file target"
    echo "  -r      specify error code after emit (should be < 255!)"
    echo "  -e      emit log contents (instead of trying to collect)"
    echo "  -n      skip if there is nothing worth emitting"
    echo "  -d      drop log contents from target (after emit or skip)"
    echo "  -h      show this help and exit"
    echo
    echo "collecting:"
    echo "  /some/command 2>&1 | $0 -t /some/where.log"
    echo
    if [ -n "$*" ]; then
        echo "ERROR:"
        echo "$*"
        exit 1
    fi
    exit 0
}

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

case $STATUS in
    ''|*[!0-9]*)    _usage "-r must be a number"   ;;
esac


_clear() { :> "$TARGET"; }
[ ! -f "$TARGET" ] && _clear


if [ $EMIT ]; then
    CONTENT="$(/bin/cat "$TARGET")"

    if [ -z "$(echo "$CONTENT" | /usr/bin/xargs)" ]; then
        if [ $NULL ]; then
            exit 0
        fi
    fi

    printf "[[[ %s ]]]\n\n%s\n" "$STAMP" "$CONTENT"
    [ $DROP ] && _clear
    exit "$STATUS"
fi


CONTENT=""
while IFS= read -r LINE; do
    CONTENT="$(printf "%s\n%s" "$CONTENT" "$LINE")"
done

if [ -n "$(echo "$CONTENT" | /usr/bin/xargs)" ]; then
    printf "[   %s   ]\n%s\n\n" "$STAMP" "$CONTENT" >> "$TARGET"
fi

exit 0
