#!/usr/bin/env sh

THIS_DIR="$(cd "$(/usr/bin/dirname "$0")" || exit 1; /bin/pwd)"

TARGET="$THIS_DIR/pipe.log"
[ -n "$1" ] && TARGET="$1"
[ ! -f "$TARGET" ] && :> "$TARGET"

STAMP=$(date '+%Y-%m-%d %H-%M-%S')

if [ -t 0 ]; then
    printf ">>> %s <<<\n" "$STAMP"
    while IFS= read -r LINE; do
        printf "%s\n" "$LINE"
    done < "$TARGET"
    :> "$TARGET"
else
    {
        printf ">   %s   <\n" "$STAMP"
        while IFS= read -r LINE; do
            printf "%s\n" "$LINE"
        done
        printf "\n"
    } >> "$TARGET"
fi

exit 0
