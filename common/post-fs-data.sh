#!/system/bin/sh
MODDIR=${0%/*}

exec &> "${MODDIR}"/post-fs-data.log

echo "*** Universal SafetyNet Fix > START"

set -x

function background() {
    set +x; while :; do
        [ "$(getprop sys.boot_completed)" == "1" ] && [ "$(getprop init.svc.magisk_service)" == "stopped" ] && {
            set -x; break; }
        sleep 1
    done

    get_pid() { ps | grep -w "$1" | grep -v grep | awk '{ print $1 }' | head -n 1; }

    get_mnt() {
        for GET_MNT in "$@"; do
            readlink /proc/"${GET_MNT}"/ns/mnt
        done
    }

    while :; do
        [ "$(grep -i 'Zygote.*ns=' '/cache/magisk.log' | head -n 1)" ] && break
        INIT_PID=$(get_pid "init")
        ZYGOTE_PID=$(get_pid "zygote")
        ZYGOTE64_PID=$(get_pid "zygote64")
        [ "$(get_mnt $INIT_PID $ZYGOTE_PID $ZYGOTE64_PID)" ] && {
            [ "$(getprop magisk.version)" == "12.0" ] && {
                su -c /magisk/.core/magiskhide/disable && sleep 2
                su -c /magisk/.core/magiskhide/enable && sleep 2; }
            [ "$(magisk -v | grep '13.0(.*):MAGISK' 2>/dev/null)" ] && {
                magiskhide --disable && sleep 2
                magiskhide --enable && sleep 2; }
            [ "$MAGISKHIDE_RETRY" == "4" ] && break || MAGISKHIDE_RETRY=$(($MAGISKHIDE_RETRY+1)); }
    done

    set +x

    echo "*** Universal SafetyNet Fix > END"

    cat "${MODDIR}"/post-fs-data.log >> /cache/magisk.log

    echo "*** Universal SafetyNet Fix > Running system mirror & dummy hide"

    [ "$(getprop magisk.version)" == "12.0" ] && {
        logcat -c && logcat -b events -v raw -s am_proc_start | while read LOG_PROC; do
            [ "$(echo $LOG_PROC | grep com.google.android.gms.unstable | head -n 1)" ] && SAFETYNET_PID=$(echo $LOG_PROC | grep com.google.android.gms.unstable | head -n 1 | awk '{ print substr($0,4) }' | sed 's/,.*//')
            [ "$SAFETYNET_PID" ] && {
                nsenter --target=$SAFETYNET_PID --mount=/proc/${SAFETYNET_PID}/ns/mnt -- /system/bin/sh -c 'for MOUNTPOINT in "/dev/magisk/mirror/system" "/dev/magisk/dummy/system/xbin" "/dev/magisk/dummy/system/*/*"; do /data/magisk/busybox umount -l $MOUNTPOINT; done'
                unset SAFETYNET_PID; logcat -c; }
        done; }
}

cp -af "${MODDIR}"/busybox /data/magisk/busybox

[ -d "/magisk/.core/magiskhide" ] && {
    cp -af "${MODDIR}"/magiskhide /magisk/.core/magiskhide; }

for APPLET in "ps" "awk" "head" "readlink" "sed" "nsenter"; do
    alias "$APPLET"="/data/magisk/busybox $APPLET"
done

RESETPROP="resetprop -v -n"

if [ -f "/sbin/magisk" ]; then RESETPROP="/sbin/magisk $RESETPROP"
elif [ -f "/data/magisk/magisk" ]; then RESETPROP="/data/magisk/magisk $RESETPROP"
elif [ -f "/magisk/.core/bin/resetprop" ]; then RESETPROP="/magisk/.core/bin/$RESETPROP"
elif [ -f "/data/magisk/resetprop" ]; then RESETPROP="/data/magisk/$RESETPROP"; fi

$RESETPROP "ro.build.fingerprint" "Xiaomi/sagit/sagit:7.1.1/NMF26X/V8.2.17.0.NCACNEC:user/release-keys"
$RESETPROP "ro.bootimage.build.fingerprint" "Xiaomi/sagit/sagit:7.1.1/NMF26X/V8.2.17.0.NCACNEC:user/release-keys"
$RESETPROP "ro.build.type" "user"
$RESETPROP "ro.build.tags" "release-keys"
$RESETPROP "ro.build.selinux" "0"
$RESETPROP "selinux.reload_policy" "1"
$RESETPROP "persist.magisk.hide" "1"

background &

exit
