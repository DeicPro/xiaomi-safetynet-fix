#!/system/bin/sh
# Please don't hardcode /magisk/modname/... ; instead, please use $MODDIR/...
# This will make your scripts compatible even if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode
# More info in the main Magisk thread
exec &> $MODDIR/post-fs-data.log

set -x

get_prop() {
    cat /system/build.prop | sed -n "s/^$1=//p"
}

set_prop() {
    [ "`get_prop ro.product.name`" == "$1" ] || [ "`get_prop ro.product.device`" == "$1" ] || [ "`get_prop ro.build.product`" == "$1" ] && {
        cat > $MODDIR/system.prop <<EOF
# This file will be read by resetprop
# Example: Change dpi
# ro.sf.lcd_density=320
ro.build.description=$1-user $2 $3 $4 release-keys
ro.build.fingerprint=Xiaomi/$1/$1:$2/$3/$4:user/release-keys
EOF
        exit
    }
}

# Redmi Note 2
set_prop "hermes" "5.0.2" "LRX22G" "V8.2.1.0.LHMCNDL"

# Redmi Note 3
set_prop "hennessy" "5.0.2" "LRX22G" "V8.2.1.0.LHNCNDL"

# Redmi Note 3 Pro
set_prop "kenzo" "6.0.1" "MMB29M" "V8.2.1.0.MHOCNDL"

# Redmi Note 4
set_prop "nikel" "6.0" "MRA58K" "V8.2.2.0.MBFCNDL"

# Mi 5
set_prop "gemini" "7.0" "NRD90M" "V8.2.2.0.NAACNEB"

# Mi 5s
set_prop "capricorn" "6.0.1" "MXB48T" "V8.2.4.0.MAGCNDL"

#Mi 5s Plus
set_prop "natrium" "6.0.1" "MXB48T" "V8.2.4.0.MBGCNDL"

# Mi Mix
set_prop "lithium" "6.0.1" "MXB48T" "V8.2.3.0.MAHCNDL"
