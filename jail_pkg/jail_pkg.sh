#!/usr/bin/env sh

msg_head() {
    echo "###"
    echo "# $1"
}
msg_code() {
    echo "# $2 -> $1"
    echo "###"
    echo
}

action() {
    NAME="$1"; shift
    msg_head "$NAME"
    /usr/sbin/pkg "$@"
    msg_code "$?" "$NAME"
}

action "host" "$@"
for NAME in $(/usr/sbin/jls -q name); do
    action "$NAME" -j "$NAME" "$@"
done

exit 0
