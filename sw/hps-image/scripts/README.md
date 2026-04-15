# Scripts

This directory is for reproducible helper scripts only.

The primary HPS image entry point is now:

- `build-full-stack.sh`: build the repo-owned SoCKit SD image end to end

The older `build-rootfs-first.sh` path is still available as a fallback when we
need to compare against the more conservative vendor-boot-chain approach.

Examples of the kinds of scripts that belong here:

- fetch a pinned Buildroot release
- prepare a local build directory
- assemble boot artifacts for an SD card
- export a host-side SDK for cross-compiling HPS applications
- document or automate flashing steps

Only the fallback rootfs-first path requires a locally provided reference image
from the Terasic Rev. D "CD-ROM" package. The primary full-stack workflow is
intended to build a complete SD image from repo-managed artifacts.

Do not commit giant generated outputs here.
