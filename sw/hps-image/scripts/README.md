# Scripts

This directory is for reproducible helper scripts only.

Examples of the kinds of scripts that belong here:

- fetch a pinned Buildroot release
- prepare a local build directory
- assemble boot artifacts for an SD card
- export a host-side SDK for cross-compiling HPS applications
- document or automate flashing steps

For the current rootfs-first path, scripts may also require a locally provided
reference image from the Terasic Rev. D "CD-ROM" package. That vendor image is
an external prerequisite and should not be committed here.

Do not commit giant generated outputs here.
