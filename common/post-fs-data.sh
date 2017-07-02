#!/system/bin/sh
MODDIR=${0%/*}

exec &> /cache/universal-safetynet-fix.log

echo "*** Universal SafetyNet Fix > Running module" >> /cache/magisk.log

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

    get_pid() { $BBX pgrep $1 | $BBX head -n 1; }

    INIT_PID=$(get_pid "init")
    ZYGOTE_PID=$(get_pid "-x zygote")
    ZYGOTE64_PID=$(get_pid "-x zygote64")

    for GET_MNT in "$INIT_PID" "$ZYGOTE_PID" "$ZYGOTE64_PID"; do
        $BBX readlink /proc/"${GET_MNT}"/ns/mnt || {
            echo "*** Universal SafetyNet Fix > Fail: mount namespaces are not supported in your kernel" >> /cache/magisk.log
            exit; }
    done

    ZYGOTE_MNT=$($BBX readlink /proc/"$ZYGOTE_PID"/ns/mnt | $BBX sed 's/.*\[/\Zygote.*/' | $BBX sed 's/\]//')

    while :; do
        [ "$($BBX grep -i ${ZYGOTE_MNT} '/cache/magisk.log' | $BBX head -n 1)" ] && {
            MAGISKHIDE="1"; break; }
            [ "$(magisk -v 2>/dev/null | grep '13.0(.*):MAGISK')" ] && {
                magiskhide --disable && sleep 2
                magiskhide --enable && sleep 2; }
            [ "$MAGISKHIDE_RETRY" == "4" ] && break || MAGISKHIDE_RETRY=$((${MAGISKHIDE_RETRY}+1))
    done

    echo "*** Universal SafetyNet Fix > Running Universal Hide" >> /cache/magisk.log

    [ "$(getprop magisk.version)" == "12.0" ] && {
        $BBX nsenter --target="$INIT_PID" --mount=/proc/"${INIT_PID}"/ns/mnt -- /system/bin/sh -c 'echo' && NSENTER_SH="/system/bin/sh" || NSENTER_SH="$BBX sh"
        $BBX kill -9 $($BBX pgrep com.google.android.gms.unstable)
        logcat -c && logcat -b events -v raw -s am_proc_start | while read LOG_PROC; do
            for HIDELIST in $(cat /magisk/.core/magiskhide/hidelist); do
                [ "$(echo $LOG_PROC | $BBX grep $HIDELIST | $BBX head -n 1)" ] && APP_PID=$(echo $LOG_PROC | $BBX grep $HIDELIST | $BBX head -n 1 | $BBX awk '{ print substr($0,4) }' | $BBX sed 's/,.*//')
            done
            [ "$APP_PID" ] && {
                if [ "$MAGISKHIDE" == "1" ]; then
                    $BBX nsenter --target="$APP_PID" --mount=/proc/"${APP_PID}"/ns/mnt -- $NSENTER_SH -c 'BBX="/data/magisk/busybox"; DUMMY_SYSTEM=$($BBX find /dev/magisk/dummy/system 2>/dev/null); $BBX umount -l /dev/magisk/mirror/system $DUMMY_SYSTEM 2>/dev/null'
                else
                    $BBX nsenter --target="$APP_PID" --mount=/proc/"${APP_PID}"/ns/mnt -- $NSENTER_SH -c 'BBX="/data/magisk/busybox"; MNT_DUMMY=$(cd /dev/magisk/mnt/dummy 2>/dev/null && $BBX find system/*); MNT_MIRROR=$(cd /dev/magisk/mnt/mirror 2>/dev/null && $BBX find system/*); MNT_SYSTEM=$(cd /dev/magisk/mnt 2>/dev/null && $BBX find system/*); DUMMY_SYSTEM=$($BBX find /dev/magisk/dummy/system 2>/dev/null); $BBX umount -l $MNT_DUMMY $MNT_MIRROR $MNT_SYSTEM $DUMMY_SYSTEM /dev/magisk/mirror/system /dev/block/loop* /sbin /system/xbin 2>/dev/null'
                fi
                unset APP_PID; logcat -c; }
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
