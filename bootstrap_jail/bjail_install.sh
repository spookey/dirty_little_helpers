#!/usr/bin/env sh

JAIL_NAME=${JAIL_NAME:-""}
TEMP_PATH=${TEMP_PATH:-"/var/tmp"}
ZONE_INFO=${ZONE_INFO:-""}
RESOLV_CONF=${RESOLV_CONF:-""}
EXTRACT=
RUN_RCONF=
RUN_PERIODIC=
RUN_MOTD=
RUN_FSTAB=

# output
_msg() { >&2 echo "$*"; }
_fatal() { _msg "$*"; exit 1; }

# shows usage information and quits
_usage() {
    _msg "usage: $0 [-n name] [-z zone] [-d resolv] [-x] [-r] [-p] [-t] [-m] [-h] path"
    _msg "  path        jail path"
    _msg "  -n name     jail name if different from 'basename <path>'"
    _msg "              (only required for motd or /etc/fstab.<jail>)"
    _msg ""
    _msg "  -z zone     symlink <zone> target to etc/localtime"
    _msg "              (usr/home is linked to home if target exists)"
    _msg "  -d resolv   copy content from <resolv> to etc/resolv.conf"
    _msg ""
    _msg "  -x          download and extract ${TEMP_PATH}/base.txz"
    _msg ""
    _msg "  -r          prepare etc/rc.conf"
    _msg "  -p          prepare etc/periodic.conf"
    _msg "  -t          prepare host /etc/fstab.<jail>"
    _msg "              (ensures tmpfs and usr/src nullfs)"
    _msg "  -m          write etc/motd.template"

    _msg "  -h          show this help and exit"
    [ -n "$*" ] && _fatal "$*"
    exit 0
}

# parse arguments
while getopts ":n:z:d:xrptmh" OPT "$@"; do
    case $OPT in
        n)  JAIL_NAME="$OPTARG"                     ;;
        z)  ZONE_INFO="$OPTARG"                     ;;
        d)  RESOLV_CONF="$OPTARG"                   ;;
        x)  EXTRACT=1                               ;;
        r)  RUN_RCONF=1                             ;;
        p)  RUN_PERIODIC=1                          ;;
        t)  RUN_FSTAB=1                             ;;
        m)  RUN_MOTD=1                              ;;
        h)  _usage                                  ;;
        :)  _usage "-$OPTARG" "needs an argument"   ;;
        \?) _usage "invalid option" "-$OPTARG"      ;;
    esac
done
shift $(( OPTIND - 1 ))

JAIL_PATH="$1"; shift

# validate input
[ -z "$JAIL_PATH" ] && _usage "jail path missing"
[ -z "$TEMP_PATH" ] && _usage "temp path missing"

JAIL_PATH="$(/bin/realpath "$JAIL_PATH")"
[ -z "$JAIL_NAME" ] && JAIL_NAME="$(/usr/bin/basename "$JAIL_PATH")"

[ "$(/sbin/zfs get -Ho value type "$JAIL_PATH" 2> /dev/null)" != "filesystem" ] \
    && _fatal "invalid path" "$JAIL_PATH"
[ ! -d "$TEMP_PATH" ] && _fatal "missing temp" "$TEMP_PATH"

[ $EXTRACT ] && {
    [ -f "$JAIL_PATH/COPYRIGHT" ] && _fatal "already installed" "$JAIL_PATH"

    RELEASE=$(/usr/bin/uname -r | /usr/bin/sed  s/-p[0-9]*//)
    REMOTE="https://download.freebsd.org/releases/$(/usr/bin/uname -m)/$RELEASE"

    FEST="$TEMP_PATH/${RELEASE}_MANIFEST"
    BASE="$TEMP_PATH/${RELEASE}_base.txz"
    [ ! -f "$FEST" ] && /usr/bin/fetch -o "$FEST" "$REMOTE/MANIFEST"
    [ ! -f "$BASE" ] && /usr/bin/fetch -o "$BASE" "$REMOTE/base.txz"

    SHA_SUM="$(/sbin/sha256 -q "$BASE")"
    ! /usr/bin/grep "$SHA_SUM" "$FEST" && _fatal "not in manifest" "$SHA_SUM"

    _msg "extract" "$BASE" "to" "$JAIL_PATH"
    /usr/bin/tar -C "$JAIL_PATH" -xf "$BASE"
}

[ ! -f "$JAIL_PATH/COPYRIGHT" ] && _fatal "not installed" "$JAIL_PATH"

[ -z "$ZONE_INFO" ] && [ -e "/etc/localtime" ] && ZONE_INFO="/etc/localtime"
[ -z "$ZONE_INFO" ] && _usage "zone info missing"

[ ! -e "$JAIL_PATH/etc/localtime" ] && {
    ZONE_INFO="$(/bin/realpath "$ZONE_INFO")"

    _msg "linking localtime to" "$ZONE_INFO"
    ln -s "$ZONE_INFO" "$JAIL_PATH/etc/localtime"
}

[ ! -e "$JAIL_PATH/home" ] && [ -d "$JAIL_PATH/usr/home" ] && {
    _msg "linking home directories"
    ln -s "/usr/home" "$JAIL_PATH/home"
}

[ -f "$RESOLV_CONF" ] && {
    _msg "create resolv from" "$RESOLV_CONF"
    cat "$RESOLV_CONF" > "$JAIL_PATH/etc/resolv.conf"
}

_contain() {
    _msg "check" "$1" "for" "$2"
    [ "$(/usr/bin/grep -o "$2" "$1" 2> /dev/null)" != "$2" ] && return 1
    return 0
}

[ $RUN_RCONF ] && {
    RCONF="$JAIL_PATH/etc/rc.conf"

    _contain "$RCONF" "clear_tmp_enable" \
        || printf 'clear_tmp_enable="YES"\n' >> "$RCONF"
    # no ports for syslogd
    _contain "$RCONF" "syslogd_flags" \
        || printf 'syslogd_flags="-ss"\n' >> "$RCONF"
    # cron jitter
    _contain "$RCONF" "cron_flags" \
        || printf 'cron_flags="-J 60"\n' >> "$RCONF"
    # disable sendmail
    _contain "$RCONF" "sendmail_enable" \
        || printf 'sendmail_enable="NO"\n' >> "$RCONF"
    _contain "$RCONF" "sendmail_submit_enable" \
        || printf 'sendmail_submit_enable="NO"\n' >> "$RCONF"
    _contain "$RCONF" "sendmail_outbound_enable" \
        || printf 'sendmail_outbound_enable="NO"\n' >> "$RCONF"
    _contain "$RCONF" "sendmail_msp_queue_enable" \
        || printf 'sendmail_msp_queue_enable="NO"\n' >> "$RCONF"

    _msg "current" "$RCONF"
    cat "$RCONF"
}

[ $RUN_PERIODIC ] && {
    PERIODIC="$JAIL_PATH/etc/periodic.conf"

    for SPAN in "daily" "weekly" "monthly"; do
    _contain "$PERIODIC" "${SPAN}_output" \
        || printf '%s_output="/var/log/%s.log"\n' "$SPAN" "$SPAN" >> "$PERIODIC"
    _contain "$PERIODIC" "${SPAN}_show_badconfig" \
        || printf '%s_show_badconfig="YES"\n' "$SPAN" >> "$PERIODIC"
    _contain "$PERIODIC" "${SPAN}_status_security_output" \
        || printf '%s_status_security_output="/var/log/%s.log"\n' "$SPAN" "$SPAN" >> "$PERIODIC"
    done

    _contain "$PERIODIC" "security_show_badconfig" \
        || printf 'security_show_badconfig="YES"\n' >> "$PERIODIC"

    _msg "current" "$PERIODIC"
    cat "$PERIODIC"
}

[ $RUN_FSTAB ] && {
    FSTAB="/etc/fstab.$JAIL_NAME"
    TMP="$JAIL_PATH/tmp"
    SRC="$JAIL_PATH/usr/src"

    _contain "$FSTAB" "$TMP" \
        || printf 'tmpfs\t\t\t\t\t%s\t\t\ttmpfs\trw,mode=1777\t0\t0\n' "$TMP" >> "$FSTAB"

    [ -f "/usr/src/COPYRIGHT" ] && {
    _contain "$FSTAB" "$SRC" \
        || printf '/usr/src\t\t\t\t%s\t\t\tnullfs\tro\t\t0\t0\n' "$SRC" >> "$FSTAB"
    }

    _msg "current" "$FSTAB"
    cat "$FSTAB"
}

[ $RUN_MOTD ] && {
    TMPL="$JAIL_PATH/etc/motd.template"
    TOTAL_LEN="$(printf "%s" "$JAIL_NAME" | /usr/bin/wc -m | /usr/bin/xargs)"
    HEAD_LINE=""; POS=0;
    while [ "$POS" -lt "$TOTAL_LEN" ]; do
        HEAD_LINE="$HEAD_LINE="; POS=$((POS+1));
    done

    cat << OMFG > "$TMPL"
+=$HEAD_LINE======+
| $JAIL_NAME jail |
+=$HEAD_LINE======+
OMFG
    _msg "current" "$TMPL"
    cat "$TMPL"
}
