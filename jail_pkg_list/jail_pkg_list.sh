#!/usr/bin/env sh

TARGET="${TARGET:-"$HOME/pkg_list"}"
BASE="${BASE:-"host"}"


action() {
    NAME="$1"; shift
    LIST="$TARGET/$NAME.txt"
    echo "#> $LIST"
    /usr/sbin/pkg "$@" info -ao > "$LIST"
}


[ ! -d "$TARGET" ] && {
    echo "## Creating folder" "$TARGET"
    /bin/mkdir -p "$TARGET"
}

action "$BASE"
for NAME in $(/usr/sbin/jls -q name | /usr/bin/sort); do
    action "$NAME" -j "$NAME"
done

exit 0
