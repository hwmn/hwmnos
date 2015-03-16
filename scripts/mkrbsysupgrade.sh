#!/bin/sh

ROOTFS_TARGZ=openwrt-ar71xx-mikrotik-DefaultNoWifi-rootfs.tar.gz
KERNEL_ELF=openwrt-ar71xx-mikrotik-vmlinux-lzma.elf

SYSUPGRADE_TARGZ=$(echo "$ROOTFS_TARGZ" | sed s#rootfs#sysupgrade#)
SYSUPGRADE_TAR=$(echo "$SYSUPGRADE_TARGZ" | sed s#.gz##)

[ -f "$ROOTFS_TARGZ" -a -f "$KERNEL_ELF" ] || {
	echo "Running in wrong directory. Please ensure "
}

cp "$ROOTFS_TARGZ" "$SYSUPGRADE_TARGZ"
cp "$KERNEL_ELF" kernel

gunzip "$SYSUPGRADE_TARGZ"
tar rf "$SYSUPGRADE_TAR" --numeric-owner --owner=0 --group=0 ./kernel
gzip "$SYSUPGRADE_TAR"

rm kernel
