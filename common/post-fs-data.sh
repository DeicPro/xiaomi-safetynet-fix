#!/system/bin/sh
MODDIR=${0%/*}

exec &> "${MODDIR}"/post-fs-data.log

echo "*** Universal SafetyNet Fix > START"

set -x

function background() {
    set +x; while :; do
        [ "$(getprop persist.magisk.hide)" == "1" ] && {
            set -x; break; } || {
            setprop "persist.magisk.hide" "1"; sleep 1; }
    done

    set +x; while :; do
        [ "$(getprop sys.boot_completed)" == "1" ] && [ "$(getprop init.svc.magisk_service)" == "stopped" ] && {
            set -x; break; }
        sleep 1
    done

    get_pid() { $BBX ps | $BBX grep -w "$1" | $BBX grep -v grep | $BBX awk '{ print $1 }' | $BBX head -n 1; }

    get_mnt() {
        for GET_MNT in "$@"; do
            $BBX readlink /proc/"${GET_MNT}"/ns/mnt
        done
    }

    while :; do
        [ "$($BBX grep -i 'Zygote.*ns=' '/cache/magisk.log' | $BBX head -n 1)" ] && {
            MAGISKHIDE="1"; break; }
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

    echo "*** Universal SafetyNet Fix > END
*** Universal SafetyNet Fix > Running Magisk Hide (SafetyNet only)"

    cat "${MODDIR}"/post-fs-data.log >> /cache/magisk.log

    set -x

    [ "$(getprop magisk.version)" == "12.0" ] && {
        $BBX kill -9 $($BBX pgrep com.google.android.gms.unstable)
        logcat -c && logcat -b events -v raw -s am_proc_start | while read LOG_PROC; do
            [ "$(echo $LOG_PROC | grep com.google.android.gms.unstable | head -n 1)" ] && SAFETYNET_PID=$(echo $LOG_PROC | $BBX grep com.google.android.gms.unstable | $BBX head -n 1 | $BBX awk '{ print substr($0,4) }' | $BBX sed 's/,.*//')
            [ "$SAFETYNET_PID" ] && {
                if [ "$MAGISKHIDE" == "1" ]; then
                    $BBX nsenter --target=$SAFETYNET_PID --mount=/proc/${SAFETYNET_PID}/ns/mnt -- /system/bin/sh -c 'BBX="/data/magisk/busybox" && $BBX umount -l /dev/magisk/mirror/system /dev/magisk/dummy/system/xbin $($BBX find /dev/magisk/dummy/system/*) 2>/dev/null'
                else
                    $BBX nsenter --target=$SAFETYNET_PID --mount=/proc/${SAFETYNET_PID}/ns/mnt -- /system/bin/sh -c 'BBX="/data/magisk/busybox" && MNT_DUMMY=$(cd /dev/magisk/mnt/dummy && $BBX find system/*) && MNT_MIRROR=$(cd /dev/magisk/mnt/mirror && $BBX find system/*) && MNT_SYSTEM=$(cd /dev/magisk/mnt && $BBX find system/*) && DUMMY_SYSTEM=$($BBX find /dev/magisk/dummy/system) && $BBX umount -l $MNT_DUMMY $MNT_MIRROR $MNT_SYSTEM $DUMMY_SYSTEM /dev/magisk/mirror/system /dev/block/loop* /sbin 2>/dev/null'
                fi
                unset SAFETYNET_PID; logcat -c; }
        done; }
}

BBX="/data/magisk/busybox"

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

background &

exit
