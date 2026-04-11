# Rootfs Observations

Status: initial offline inspection complete

These notes come from offline inspection of the ext3 rootfs partition extracted
from `SoCKit_SD_revD.img` and cross-checks against the running board.

## Why This Matters

This helps answer a key migration question:

- is the old image doing anything unusual that would make a first custom image
  difficult?

So far, the answer appears to be "not especially."

## Basic Shape

The root filesystem looks like a fairly conventional embedded Linux layout:

- `/etc/inittab`
- `/etc/init.d/`
- `/etc/rcS.d/`
- `/etc/rc5.d/`
- `/etc/network/interfaces`
- `/boot/`

This is encouraging because it means a Buildroot-generated system using similar
conventions should not feel fundamentally alien to the existing workflow.

## Init Model

The image uses standard SysV-style init with:

- `id:5:initdefault:`
- `si::sysinit:/etc/init.d/rcS`
- `S:2345:respawn:/sbin/getty 115200 ttyS0`

Important implication:

- the serial login behavior is explicit and easy to reproduce

## Runlevel Behavior

Observed startup links indicate predictable service startup:

- `/etc/rcS.d/` includes `networking`, `mountall.sh`, `hostname.sh`,
  `populate-volatile.sh`, and related base boot scripts
- `/etc/rc5.d/` includes `sshd`, `syslog`, `lighttpd`, and board-specific
  `gsrd_init.sh`

Important implication:

- we do not need to preserve the exact old rootfs just to keep basic boot and
  login behavior working

## Networking

`/etc/network/interfaces` configures:

- `eth0` as DHCP
- `eth1` as DHCP
- `wlan0` as DHCP
- `usb0` as a static gadget-style address

Important implication:

- a first custom image can keep things simple by focusing on DHCP over `eth0`

## `/boot` In The Rootfs

The ext3 rootfs also contains:

- `zImage`
- `zImage-3.9.0`
- `vmlinux-3.9.0`

But the live boot flow actually uses the FAT partition copy of `zImage` and
`socfpga.dtb`, not this rootfs-local `/boot` directory.

Important implication:

- the rootfs can likely be replaced independently of the active FAT boot
  partition contents during early migration steps

## Practical Recommendation

The safest first custom-image experiment is likely:

1. preserve `mmcblk0p3`
2. preserve the FAT boot partition shape and its role
3. generate a replacement root filesystem for `mmcblk0p2`
4. only replace kernel/DTB once the rootfs story is under control

That should minimize the number of unknowns during the first boot attempts.
