#!/usr/bin/env sh

TARGET="${TARGET:-"/root/pkg_list"}"

msg_head() {
    echo "###"
    echo "# $*"
}
msg_code() {
    echo "# $2 -> $1"
    echo "###"
    echo
}

action() {
    NAME="$1"; shift
    msg_head "$NAME"
    LIST="$TARGET/$NAME.txt"
    /usr/sbin/pkg "$@" info -ao > "$LIST"
    msg_code "$?" "$LIST"
}


[ ! -d "$TARGET" ] && {
    msg_head "Creating folder" "$TARGET"
    mkdir -p "$TARGET"
    msg_code "$?" "$TARGET"
}

action "host"
for NAME in $(/usr/sbin/jls -q name); do
    action "$NAME" -j "$NAME"
done

exit 0
