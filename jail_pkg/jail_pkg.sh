#!/usr/bin/env sh

ARGS="$*"

msg_head() {
    echo "###"
    echo "# $1"
}
msg_code() {
    echo "# $2 -> $1"
    echo "###"
}

action() {
    JAIL="$1"
    if [ -z "$JAIL" ]; then
        msg_head "host"
        /usr/sbin/pkg "$ARGS"
        msg_code "$?" "host"
    else
        msg_head "$JAIL"
        /usr/sbin/pkg -j "$JAIL" "$ARGS"
        msg_code "$?" "$JAIL"
    fi
}

action
for JAIL_NAME in $(/usr/sbin/jls -q name); do
    action "$JAIL_NAME"
done

exit 0
