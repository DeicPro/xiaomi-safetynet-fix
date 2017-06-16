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

    sleep 5

    [ "$(getprop magisk.version)" == "12.0" ] && {
        mv /dev/magisk /dev/magisk_system
        rm -f /dev/magisk_system/mirror/vendor
        ln -s /dev/magisk_system/mirror/system/vendor /dev/magisk_system/mirror/vendor
        while :; do
            [ "$(grep 'Zygote.*ns=mnt:\[.*\]' '/cache/magisk.log')" ] && break || {
                su -c /magisk/.core/magiskhide/disable; sleep 1
                su -c /magisk/.core/magiskhide/enable; }
            sleep 3
        done; }

    [ "$(magisk -v | grep '13.0(.*):MAGISK')" ] && {
        while :; do
            [ "$(grep 'proc_monitor:.*zygote.*ns=mnt:\[.*\]' '/cache/magisk.log')" ] && break || {
                magiskhide --disable; sleep 1
                magiskhide --enable; }
            sleep 3
        done; }

    set +x

    echo "*** Universal SafetyNet Fix > END"

    cat "${MODDIR}"/post-fs-data.log >> /cache/magisk.log
}

if [ -d "/data/data/com.topjohnwu.magisk/busybox" ]; then BUSYBOX="/data/data/com.topjohnwu.magisk/busybox/"
elif [ -f "/data/data/com.topjohnwu.magisk/busybox/busybox" ]; then BUSYBOX="/data/data/com.topjohnwu.magisk/busybox/busybox "
elif [ -f "/data/app/com.topjohnwu.magisk-*/lib/*/libbusybox.so" ]; then BUSYBOX="/data/app/com.topjohnwu.magisk-*/lib/*/libbusybox.so "
elif [ -d "/dev/busybox" ]; then BUSYBOX="/dev/busybox/"
elif [ -f "/data/magisk/resetprop" ]; then BUSYBOX="/data/magisk/busybox "; fi

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
