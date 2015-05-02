#!/bin/sh

. /lib/functions.sh

mikrotik_nand_do_upgrade_stage2() {
    local mtd_kernel="$(find_mtd_part 'kernel')"
    local mtd_rootfs="$(find_mtd_part 'rootfs')"
    local mnt_kernel=/mnt/mnt
    local mnt_rootfs=/mnt

    echo "Erasing filesystem..."
    mtd erase kernel 2>/dev/null >/dev/null
    mtd erase rootfs 2>/dev/null >/dev/null

    mount -t yaffs2 "$mtd_rootfs" "$mnt_rootfs"

    echo "Preparing filesystem..."
    ( cd /mnt; tar xpz -f "$1" )

    mount -t yaffs2 "$mtd_kernel" "$mnt_kernel"

    echo "Copying kernel..."
    cp $mnt_rootfs/kernel $mnt_kernel/kernel

    echo "Copying old configuration..."
    cp /tmp/sysupgrade.tgz /mnt/

    # make sure everything is written before we unmount the partitions
    echo "chmod ugo+x /" > /mnt/etc/uci-defaults/set_root_permission
    sync
    ls $mnt_kernel >/dev/null
    ls $mnt_rootfs >/dev/null

    echo "Unmounting partitions..."
    umount $mnt_kernel
    umount $mnt_rootfs

    sleep 3
    echo b > /proc/sysrq-trigger
}

# called by "sysupgrade nand"
nand_upgrade_stage2() {
    touch /tmp/sysupgrade

    killall -9 telnetd
    killall -9 dropbear
    killall -9 ash

    kill_remaining TERM
    sleep 3
    kill_remaining KILL

    sleep 1

    run_ramfs ". /lib/functions.sh; include /lib/upgrade; mikrotik_nand_do_upgrade_stage2 $2"
}

mikrotik_pre_upgrade_hook() {
    # pass the path to the image
    path="$ARGV"

    # make sure CONF_TAR doesn't exist if the user doesn't want to save configuration
    [ "$SAVE_CONFIG" != 1 -a -f "$CONF_TAR" ] &&
        rm $CONF_TAR

    cp /sbin/upgraded /tmp/upgraded
    chmod 755 /tmp/upgraded

    v "Calling procd's nandupgrade with path = $path"
    ubus call system nandupgrade "{\"path\": \"$path\" }"

    # will never be reached
    exit 0
}
append sysupgrade_pre_upgrade mikrotik_pre_upgrade_hook
