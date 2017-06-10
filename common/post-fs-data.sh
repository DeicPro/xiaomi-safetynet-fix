#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode
# More info in the main Magisk thread
LOGFILE="/cache/magisk.log"

exec &>> $LOGFILE

echo "### Universal SafetyNet Fix ###"

set -x

get_logs() {
    set +x; while :; do [ "$(getprop sys.boot_completed)" == "1" ] && \
    [ "$(getprop init.svc.magisk_service)" == "stopped" ] && { set -x; break; }; sleep 1; done
    getprop
    sleep 1
    cat $LOGFILE
    check_safetynet &
    check_unmount
}

grep_logcat() {
    set +x; while :; do logcat -b events -v raw -d | grep "$1" && { set -x; break; }; sleep 1; done
}

check_safetynet() {
    echo "Waiting for Magisk Manager SafetyNet check..."
    grep_logcat "MANAGER: SN: Google API Connected"
    grep_logcat "MANAGER: SN: Check with nonce"
    grep_logcat "MANAGER: SN: Response"
}

check_unmount() {
    echo "Waiting for MagiskHide unmount..."
    set +x; while :; do grep "MagiskHide: Unmounted (/sbin)" "$LOGFILE" && \
    grep "MagiskHide: Unmounted (/magisk)" "$LOGFILE" && { set -x; break; }; sleep 1; done
    sleep 1
    MAGISKHIDE_LOG=$(grep -n -x "* Starting MagiskHide" "$LOGFILE")
    ${BUSYBOX}tail +${MAGISKHIDE_LOG%%:*} "$LOGFILE"
}

#wget --post-data "api_option=paste&api_dev_key=2dc5d9876384c0232c6ce30ae0558479&api_paste_code=$(cat $log)&api_paste_name=$log" http://pastebin.com/api/api_post.php > /dev/null 2>&1
#$(cat /system/build.prop | sed -n "s/^$1=//p")
#while :; do [ "$(getprop persist.magisk.hide)" == "1" ] && \
#break || setprop "persist.magisk.hide" "1"; sleep 1; done

if [ -d "/data/data/com.topjohnwu.magisk/busybox" ]; then BUSYBOX="/data/data/com.topjohnwu.magisk/busybox/"
elif [ -f "/data/data/com.topjohnwu.magisk/busybox/busybox" ]; then BUSYBOX="/data/data/com.topjohnwu.magisk/busybox/busybox "
elif [ -f "/data/app/com.topjohnwu.magisk-*/lib/*/libbusybox.so" ]; then BUSYBOX="/data/app/com.topjohnwu.magisk-*/lib/*/libbusybox.so "
elif [ -d "/dev/busybox" ]; then BUSYBOX="/dev/busybox/"
elif [ -f "/data/magisk/resetprop" ]; then BUSYBOX="/data/magisk/busybox "
fi

RESETPROP="resetprop -v -n"

if [ -f "/sbin/magisk" ]; then RESETPROP="/sbin/magisk $RESETPROP"
elif [ -f "/data/magisk/magisk" ]; then RESETPROP="/data/magisk/magisk $RESETPROP"
elif [ -f "/magisk/.core/bin/resetprop" ]; then RESETPROP="/magisk/.core/bin/$RESETPROP"
elif [ -f "/data/magisk/resetprop" ]; then RESETPROP="/data/magisk/$RESETPROP"
fi

$RESETPROP "ro.build.fingerprint" "Xiaomi/sagit/sagit:7.1.1/NMF26X/V8.2.17.0.NCACNEC:user/release-keys"
$RESETPROP "ro.bootimage.build.fingerprint" "Xiaomi/sagit/sagit:7.1.1/NMF26X/V8.2.17.0.NCACNEC:user/release-keys"
$RESETPROP "ro.build.type" "user"
$RESETPROP "ro.build.tags" "release-keys"
$RESETPROP "ro.build.selinux" "0"
$RESETPROP "selinux.reload_policy" "1"
$RESETPROP "persist.magisk.hide" "1"

#get_logs &

set +x

echo "### END ###"

exit
