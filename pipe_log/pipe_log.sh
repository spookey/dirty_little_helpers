#!/usr/bin/env sh

THIS_DIR="$(cd "$(/usr/bin/dirname "$0")" || exit 1; /bin/pwd)"

STAMP=$(/bin/date '+%Y-%m-%d %H-%M-%S')

TARGET="$THIS_DIR/pipe.log"
EMIT=
DROP=

_usage() {
    echo "usage: $0 [-t] [-e] [-d] [-h]"
    echo "  -t      specify backlog file target"
    echo "  -e      emit log contents"
    echo "  -d      drop log contents (after emitting)"
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

while getopts ":t:edh" OPT "$@"; do
    case $OPT in
        t)  TARGET="$OPTARG"                        ;;
        e)  EMIT=1                                  ;;
        d)  DROP=1                                  ;;
        h)  _usage                                  ;;
        :)  _usage "-$OPTARG" "needs an argument"   ;;
        \?) _usage "invalid option" "-$OPTARG"      ;;
    esac
done

_clear() { :> "$TARGET"; }
[ ! -f "$TARGET" ] && _clear


if [ $EMIT ]; then
    printf "[[[ %s ]]]\n\n%s\n" "$STAMP" "$(/bin/cat "$TARGET")"
    [ $DROP ] && _clear
    exit 23
fi


CONTENT=""

while IFS= read -r LINE; do
    CONTENT="$(printf "%s\n%s" "$CONTENT" "$LINE")"
done
if [ -n "$(echo "$CONTENT" | /usr/bin/xargs)" ]; then
    printf "[   %s   ]\n%s\n\n" "$STAMP" "$CONTENT" >> "$TARGET"
fi

exit 0
