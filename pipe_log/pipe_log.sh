#!/usr/bin/env sh

THIS_DIR="$(cd "$(/usr/bin/dirname "$0")" || exit 1; /bin/pwd)"

TARGET="$THIS_DIR/pipe.log"
[ -n "$1" ] && TARGET="$1"
[ ! -f "$TARGET" ] && :> "$TARGET"

STAMP=$(/bin/date '+%Y-%m-%d %H-%M-%S')


if [ -t 0 ]; then
    >&2 printf ">>> %s <<<\n\n%s\n" "$STAMP" "$(/bin/cat "$TARGET")"
    :> "$TARGET"
    exit 23
fi


CONTENT=""

while IFS= read -r LINE; do
    CONTENT="$(printf "%s\n%s" "$CONTENT" "$LINE")"
done
if [ -n "$(echo "$CONTENT" | /usr/bin/xargs)" ]; then
    printf ">   %s   <\n%s\n\n" "$STAMP" "$CONTENT" >> "$TARGET"
fi

exit 0
