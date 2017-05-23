#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode
# More info in the main Magisk thread
exec &> $MODDIR/xiaomi-safetynet-fix.log

set -x

LOGFILE="/cache/magisk.log"

log_print() {
    echo "$1"
    echo "$1" >> $LOGFILE
    log -p i -t Magisk "$1"
}

if [ -f "/magisk/.core/bin/resetprop" ]; then RESETPROP="/magisk/.core/bin/resetprop"
elif [ -f "/data/magisk/resetprop" ]; then RESETPROP="/data/magisk/resetprop"
elif [ -f "/sbin/resetprop" ]; then RESETPROP="/sbin/resetprop"
else exit 1; fi

set_prop() {
    if [ "$4" ]; then MODEL="$4"; else MODEL="$DEVICE"; fi
    $RESETPROP -v -n "ro.build.fingerprint" "Xiaomi/$MODEL/$DEVICE:$1/$2/$3:user/release-keys"
    $RESETPROP -v -n "ro.bootimage.build.fingerprint" "Xiaomi/$MODEL/$DEVICE:$1/$2/$3:user/release-keys"
    script_end &
    exit
}

grep_logcat() {
    set +x
    while :; do logcat -d | grep "$1" && break; sleep 1; done
    set -x
}

script_end() {
    while :; do [ "$(getprop persist.magisk.hide)" == "1" ] && \
    break || setprop "persist.magisk.hide" "1"; sleep 1; done
    set +x
    while :; do [ "$(getprop sys.boot_completed)" == "1" ] && \
    [ "$(getprop init.svc.magisk_service)" == "stopped" ] && break; sleep 1; done
    set -x
    getprop
    sleep 1
    cat $LOGFILE
    echo "Waiting for Magisk Manager SafetyNet check..."
    grep_logcat "MANAGER: SN: Google API Connected"
    grep_logcat "MANAGER: SN: Check with nonce"
    grep_logcat "MANAGER: SN: Response"
    grep_logcat "MANAGER: StatusFragment: SafetyNet UI refresh triggered"
    echo "Waiting for MagiskHide unmount..."
    while :; do grep "MagiskHide: Unmounted (/sbin)" "$LOGFILE" && \
    grep "MagiskHide: Unmounted (/magisk)" "$LOGFILE" && break; sleep 1; done
    sleep 1
    MAGISKHIDE_LOG=$(grep -n -x "* Starting MagiskHide" "$LOGFILE")
    /data/magisk/busybox tail +${MAGISKHIDE_LOG%%:*} "$LOGFILE"
}

#logcat -b events -v raw -t 10

DEVICE=$(cat /system/build.prop | sed -n "s/^ro.product.device=//p")

case $DEVICE in
# Redmi Note 2
    hermes) set_prop "5.0.2" "LRX22G" "V8.2.1.0.LHMCNDL";;
# Redmi Note 3 MTK
    hennesy) set_prop "5.0.2" "LRX22G" "V8.2.1.0.LHNCNDL";;
# Redmi Note 3 Qualcomm
    kenzo) set_prop "6.0.1" "MMB29M" "V8.2.1.0.MHOCNDL";;
# Redmi Note 4 MTK
    nikel) set_prop "6.0" "MRA58K" "V8.2.2.0.MBFCNDL";;
# Mi 5
    gemini) set_prop "6.0.1" "MXB48T" "V8.1.2.0.MAAMIDI";;
# Mi 5s
    capricorn) set_prop "6.0.1" "MXB48T" "V8.2.4.0.MAGCNDL";;
# Mi 5s Plus
    natrium) set_prop "6.0.1" "MXB48T" "V8.2.4.0.MBGCNDL";;
# Mi MIX
    lithium) set_prop "6.0.1" "MXB48T" "V8.2.3.0.MAHCNDL";;
# Mi Max
    hydrogen)set_prop "6.0.1" "MMB29M" "V8.2.3.0.MBCCNDL";;
# Mi Max Prime
    helium) set_prop "6.0.1" "MMB29M" "V8.2.3.0.MBDCNDL";;
# Redmi 3S/Prime/3X
    land) set_prop "6.0.1" "MMB29M" "V8.1.5.0.MALCNDI";;
# Mi 4c
    libra) set_prop "5.1.1" "LMY47V" "V8.2.1.0.LXKCNDL";;
# Mi 5c
    meri) set_prop "6.0" "MRA58K" "V8.1.15.0.MCJCNDI";;
# Redmi Note 3 Special Edition
    kate) set_prop "6.0.1" "MMB29M" "V8.1.3.0.MHRMIDI";;
# Mi Note 2
    scorpio) set_prop "6.0.1" "MXB48T" "V8.2.5.0.MADCNDL";;
# Redmi Note 4X
    mido) set_prop "6.0.1" "MMB29M" "V8.2.18.0.MCFCNDL";;
# Redmi 2 Prime
    wt88047) set_prop "5.1.1" "LMY47V" "V8.2.5.0.LHJCNDL";;
# Redmi 2/4G
    HM2014811) set_prop "4.4.4" "KTU84P" "V8.2.3.0.KHJCNDL" "2014811";;
# Redmi 3/Prime
    ido) set_prop "5.1.1" "LMY47V" "V8.1.3.0.LAIMIDI";;
# Mi 4i
    ferrari) set_prop "5.0.2" "LRX22G" "V8.1.5.0.LXIMIDI";;
# Redmi 4
    prada) set_prop "6.0.1" "MMB29M" "V8.1.5.0.MCECNDI";;
# Redmi 4 Prime
    markw) set_prop "6.0.1" "MMB29M" "V8.2.4.0.MBEMIDL";;
# Redmi 4A
    rolex) set_prop "6.0.1" "MMB29M" "V8.1.4.0.MCCMIDI";;
# Mi Pad
    mocha) set_prop "4.4.4" "KTU84P" "V8.2.2.0.KXFCNDL";;
# Mi Note
    virgo) set_prop "6.0.1" "MMB29M" "V8.1.4.0.MXEMIDI";;
# Mi 3/Mi 4
    cancro) set_prop "6.0.1" "MMB29M" "V8.1.6.0.MXDMIDI";;
# Mi 2/2S
    aries) set_prop "5.0.2" "LRX22G" "V8.1.3.0.LXAMIDI";;
# Mi Pad 2
    latte) set_prop "5.1" "LMY47I" "V8.2.2.0.LACCNDL";;
# Mi Pad 3
    cappu) set_prop "7.0" "NRD90M" "V8.2.8.0.NCICNEB";;
# Mi 6
    sagit) set_prop "7.1.1" "NMF26X" "V8.2.17.0.NCACNEC";;
# Mi Note Pro
    leo) "7.0" "NRD90M" "V8.2.3.0.NXHCNEC";;
# Redmi 1
    HM2013023) "4.4.2" "HM2013023" "V7.3.1.0.KHBCNDD" "2013023";;
# Redmi 1S
    armani) "4.4.4" "KTU84P" "V8.2.1.0.KHCMIDL";;
    *) echo "$DEVICE is not supported too"
esac
