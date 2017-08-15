#!/system/bin/sh
MODDIR=${0%/*}

exec &> /cache/universal-safetynet-fix.log

LOGFILE=/cache/magisk.log

function log_print() {
    echo "$1"
    echo "$1" >> $LOGFILE
    log -p i -t Magisk "$1"
}

set -x

function background() {
    log_print "*** [Universal Hide] Checking information"

    set +x; while :; do
        [ "$(getprop sys.boot_completed)" == "1" ] && {
            set -x; break; }
        sleep 1
    done

    setprop "persist.usnf.version" "$($BBX grep version= $MODDIR/module.prop | $BBX sed 's/version=//')"

    [ "$(getprop magisk.version)" == "12.0" ] && {
        MAGISK_VERSION=12
        HIDELIST_FILE=/magisk/.core/magiskhide/hidelist; }

    [ "$(magisk -v 2>/dev/null | grep '13..*:MAGISK')" ] && {
        MAGISK_VERSION=13
        HIDELIST_FILE=/magisk/.core/hidelist; }

    mkdir -p /data/magisk
    cp -af $MODDIR/busybox /data/magisk/busybox || {
        log_print "*** [Universal Hide] Built-in Busybox was not properly copied"
        exit; }

    [ "$MAGISK_VERSION" == "12" ] && cp -af $MODDIR/magiskhide /magisk/.core

    get_pid() { $BBX pgrep $1 | $BBX head -n 1; }

    INIT_PID=$(get_pid "init")

    $BBX readlink /proc/$INIT_PID/ns/mnt || {
        log_print "*** [Universal Hide] Fail: mount namespace is not supported in your kernel"
        exit; }

    ZYGOTE_PID=$(get_pid "-x zygote")
    ZYGOTE_MNT=$($BBX readlink /proc/$ZYGOTE_PID/ns/mnt | $BBX sed 's/.*\[/\Zygote.*/' | $BBX sed 's/\]//')

    [ "$($BBX grep -i ${ZYGOTE_MNT} /cache/magisk.log | $BBX head -n 1)" ] && MAGISKHIDE=1 || MAGISKHIDE=0

    [ "$(getprop persist.usnf.universalhide)" == "1" ] && MAGISKHIDE=0

### Universal Hide ###
    [ "$MAGISK_VERSION" == "12" ] || [ "$MAGISKHIDE" == "0" ] && {
        $RESETPROP --delete "init.svc.magisk_pfs"
        $RESETPROP --delete "init.svc.magisk_pfsd"
        $RESETPROP --delete "init.svc.magisk_service"
        $RESETPROP --delete "persist.magisk.hide"
        $RESETPROP --delete "ro.magisk.disable"
        $RESETPROP --delete "magisk.restart_pfsd"
        [ "$MAGISK_VERSION" == "13" ] && $RESETPROP --delete "persist.magisk.busybox"
        getprop | $BBX grep magisk

        [ -d /sbin_orig ] || {
            log_print "*** [Universal Hide] Moving and re-linking /sbin binaries" >> /cache/magisk.log
            mount -o rw,remount rootfs /
            mv -f /sbin /sbin_mirror
            mkdir /sbin
            mkdir /sbin_orig
            mount -o ro,remount rootfs /
            mkdir -p /dev/sbin_bind
            chmod 755 /dev/sbin_bind
            ln -s /sbin_mirror/* /dev/sbin_bind
            $BBX chcon -h u:object_r:system_file:s0 /dev/sbin_bind /dev/sbin_bind/*
            mount -o bind /dev/sbin_bind /sbin
            mount -o bind /dev/sbin_bind /sbin_orig; }

        $BBX nsenter -F --target=$INIT_PID --mount=/proc/$INIT_PID/ns/mnt -- /system/bin/sh -c exit && NSENTER_SH=/system/bin/sh || NSENTER_SH="$BBX sh"

        $BBX kill -9 $($BBX pgrep com.google.android.gms.unstable)

        log_print "*** [Universal Hide] Starting monitoring process"
        logcat -c; logcat -b events -v raw -s am_proc_start | while read LOG_PROC; do
            for HIDELIST in $(cat $HIDELIST_FILE); do
                [ "$(echo $LOG_PROC | $BBX grep -w $HIDELIST | $BBX head -n 1)" ] && {
                APP_PID=$(echo $LOG_PROC | $BBX grep $HIDELIST | $BBX head -n 1 | $BBX awk '{ print substr($0,4) }' | $BBX sed 's/,.*//')
                APP_INFO=$(echo $LOG_PROC | $BBX grep $HIDELIST | $BBX head -n 1); }
            done
            [ "$APP_PID" ] && {
                [ "$($BBX getenforce)" == "Permissive" ] && {
            log_print "*** [Universal Hide] Hiding SELinux mode"
            chmod 640 /sys/fs/selinux/enforce
            chmod 440 /sys/fs/selinux/policy; }
                log_print "*** [Universal Hide] Unmounting Magisk mount points:"
                log_print "$APP_INFO"
                if [ "$MAGISK_VERSION" == "12" ] && [ "$MAGISKHIDE" == "0" ]; then
                    log_print "*** [Universal Hide] Hiding Magisk props"
                    MAGISK_BBX=$(getprop persist.magisk.busybox)
                    MAGISK_HIDE=$(getprop persist.magisk.hide)
                    $RESETPROP --delete "magisk.version"
                    $RESETPROP --delete "persist.magisk.busybox"
                    $RESETPROP --delete "persist.magisk.hide"
                    rm -f /data/property/persist.magisk.busybox
                    rm -f /data/property/persist.magisk.hide
                    $BBX nsenter -F --target=$APP_PID --mount=/proc/$APP_PID/ns/mnt -- $NSENTER_SH -c '
                        BBX=/data/magisk/busybox
                        DUMMY_SYSTEM=$($BBX find /dev/magisk/dummy/system 2>/dev/null)
                        $BBX umount -l /dev/magisk/mirror/system 2>/dev/null
                        $BBX umount -l $DUMMY_SYSTEM 2>/dev/null
                        $BBX umount -l /dev/magisk/mirror/vendor 2>/dev/null'
                    sleep 3
                    $RESETPROP "magisk.version" "12.0"
                    $RESETPROP "persist.magisk.busybox" "$MAGISK_BBX"
                    $RESETPROP "persist.magisk.hide" "$MAGISK_HIDE"
                    rm -f /data/property/persist.magisk.busybox
                    rm -f /data/property/persist.magisk.hide
                else
                    $BBX nsenter -F --target=$APP_PID --mount=/proc/$APP_PID/ns/mnt -- $NSENTER_SH -c '
                        BBX=/data/magisk/busybox
                        MNT_DUMMY=$(cd /dev/magisk/mnt/dummy 2>/dev/null && $BBX find system/*)
                        MNT_MIRROR=$(cd /dev/magisk/mnt/mirror 2>/dev/null && $BBX find system/*)
                        MNT_SYSTEM=$(cd /dev/magisk/mnt 2>/dev/null && $BBX find system/*)
                        DUMMY_SYSTEM=$($BBX find /dev/magisk/dummy/system 2>/dev/null)
                        DUMMY_VENDOR=$($BBX find /dev/magisk/dummy/vendor 2>/dev/null)
                        DUMMY_TO_SYSTEM=$(cd /dev/magisk/dummy 2>/dev/null && $BBX find system/* | $BBX grep -v "system ")
                        DUMMY_TO_VENDOR=$(cd /dev/magisk/dummy 2>/dev/null && $BBX find vendor/* | $BBX grep -v "vendor ")
                        MODULE=$(cd /magisk && $BBX find */system | $BBX sed "s|.*/system/|/system/|")
                        $BBX umount -l $MNT_DUMMY 2>/dev/null
                        $BBX umount -l $MNT_MIRROR 2>/dev/null
                        $BBX umount -l $MNT_SYSTEM 2>/dev/null
                        $BBX umount -l $DUMMY_SYSTEM 2>/dev/null
                        $BBX umount -l $DUMMY_VENDOR 2>/dev/null
                        $BBX umount -l $DUMMY_TO_SYSTEM 2>/dev/null
                        $BBX umount -l $DUMMY_TO_VENDOR 2>/dev/null
                        $BBX umount -l $MODULE 2>/dev/null
                        $BBX umount -l /dev/magisk/mirror/system 2>/dev/null
                        $BBX umount -l /dev/block/loop* 2>/dev/null
                        $BBX umount -l /sbin 2>/dev/null
                        $BBX umount -l /system/xbin 2>/dev/null
                        $BBX umount -l /dev/magisk/mirror/vendor 2>/dev/null
                        $BBX umount -l /dev/magisk/mirror/bin 2>/dev/null
                        $BBX umount -l /sbin_orig 2>/dev/null
                        $BBX umount -l /dev/magisk/dummy/system/etc/hosts'
                fi
                unset APP_PID; logcat -c; }
        done; }
}

BBX=/data/magisk/busybox

RESETPROP="resetprop -v -n"

if [ -f "/sbin/magisk" ]; then RESETPROP="/sbin/magisk $RESETPROP"
elif [ -f "/data/magisk/magisk" ]; then RESETPROP="/data/magisk/magisk $RESETPROP"
elif [ -f "/magisk/.core/bin/resetprop" ]; then RESETPROP=/magisk/.core/bin/$RESETPROP
elif [ -f "/data/magisk/resetprop" ]; then RESETPROP=/data/magisk/$RESETPROP; fi

log_print "*** [Universal Hide] Version: $(getprop persist.usnf.version)"

[ "$(getprop persist.usnf.fingerprint)" == 0 ] || {
    [ "$(getprop persist.usnf.fingerprint)" == 1 ] || [ ! "$(getprop persist.usnf.fingerprint)" ] && FINGERPRINT=Xiaomi/sagit/sagit:7.1.1/NMF26X/V8.2.17.0.NCACNEC:user/release-keys || FINGERPRINT=$(getprop persist.usnf.fingerprint)
    log_print "*** [Universal Hide] Changing build fingerprint value"
    $RESETPROP "ro.build.fingerprint" "$FINGERPRINT"
    $RESETPROP "ro.bootimage.build.fingerprint" "$FINGERPRINT"; }

log_print "*** [Universal Hide] Hiding dangerous props"

VERIFYBOOT=$(getprop ro.boot.verifiedbootstate)
FLASHLOCKED=$(getprop ro.boot.flash.locked)
VERITYMODE=$(getprop ro.boot.veritymode)
KNOX1=$(getprop ro.boot.warranty_bit)
KNOX2=$(getprop ro.warranty_bit)
DEBUGGABLE=$(getprop ro.debuggable)
SECURE=$(getprop ro.secure)
BUILDTYPE=$(getprop ro.build.type)
BUILDTAGS=$(getprop ro.build.tags)
BUILDSELINUX=$(getprop ro.build.selinux)
RELOADPOLICY=$(getprop selinux.reload_policy)

[ "$VERIFYBOOT" ] && [ "$VERIFYBOOT" != "green" ] && $RESETPROP "ro.boot.verifiedbootstate" "green"
[ "$FLASHLOCKED" ] && [ "$FLASHLOCKED" != "1" ] && $RESETPROP "ro.boot.flash.locked" "1"
[ "$VERITYMODE" ] && [ "$VERITYMODE" != "enforcing" ] && $RESETPROP "ro.boot.veritymode" "enforcing"
[ "$KNOX1" ] && [ "$KNOX1" != "0" ] && $RESETPROP "ro.boot.warranty_bit" "0"
[ "$KNOX2" ] && [ "$KNOX2" != "0" ] && $RESETPROP "ro.warranty_bit" "0"
[ "$DEBUGGABLE" ] && [ "$DEBUGGABLE" != "0" ] && $RESETPROP "ro.debuggable" "0"
[ "$SECURE" ] && [ "$SECURE" != "1" ] && $RESETPROP "ro.secure" "1"
[ "$BUILDTYPE" ] && [ "$BUILDTYPE" != "user" ] && $RESETPROP "ro.build.type" "user"
[ "$BUILDTAGS" ] && [ "$BUILDTAGS" != "release-keys" ] && $RESETPROP "ro.build.tags" "release-keys"
[ "$BUILDSELINUX" ] && [ "$BUILDSELINUX" != "0" ] && $RESETPROP "ro.build.selinux" "0"
[ "$RELOADPOLICY" ] && [ "$RELOADPOLICY" != "1" ] && $RESETPROP "selinux.reload_policy" "1"

background &

exit
