# Boot Chain Reuse

Status: initial recommendation

This note records the current best recommendation for the first custom-image
attempt based on the known-good SD image and the observed live boot flow.

## Short Version

For the first custom image, we should try to reuse more than we replace.

Recommended first-pass approach:

- preserve the tiny raw `mmcblk0p3` partition
- preserve the FAT boot-partition model
- preserve early bootloader behavior initially
- replace the root filesystem first
- replace kernel/DTB only after the rootfs workflow is comfortable

## Component-By-Component Recommendation

### SPL / Preloader

Recommendation:

- reuse initially

Reasoning:

- the small raw `0xa2` partition looks bootloader-related
- early boot is the least pleasant part of the stack to debug
- nothing we have seen yet says early boot is the current bottleneck

Risk if replaced too early:

- we turn a manageable Linux-image update into a full SoCFPGA boot-chain
  bring-up project immediately

### U-Boot

Recommendation:

- reuse initially

Reasoning:

- it is already successfully loading `zImage` and `socfpga.dtb`
- it does not appear to depend on a complicated `u-boot.scr`
- current boot behavior is simple and predictable

Risk if replaced too early:

- we introduce extra uncertainty before we have even solved the rootfs/tooling
  problem that motivated this effort

### Kernel

Recommendation:

- probably reuse for the very first custom-rootfs experiment
- revisit replacement soon after that

Reasoning:

- reusing the current kernel can reduce the number of moving parts in the first
  test
- however, the current kernel is very old and should not be the long-term plan

Best use:

- keep only long enough to prove that a new rootfs boots and is usable

### DTB

Recommendation:

- initially keep the current DTB alongside the current kernel strategy

Reasoning:

- kernel and DTB are usually safest to treat as a pair during early migration
- once we replace one, we should be ready to verify the other carefully

### Root Filesystem

Recommendation:

- replace first

Reasoning:

- the rootfs is where the current pain is: package management, compiler
  availability, developer utilities, and maintainability
- the live image uses conventional SysV init and standard networking config, so
  replacing it is more approachable than replacing early boot

## Most Likely First Boot Experiment

The first low-risk experiment should be:

1. keep partition layout compatible with the known-good image
2. keep `mmcblk0p3`
3. keep the FAT boot partition structure
4. boot using the current kernel/DTB expectations
5. replace the `mmcblk0p2` rootfs contents with a Buildroot-produced rootfs

If that works, we gain:

- a modern userland
- a useful package/tool baseline
- a reproducible build story

without immediately owning the whole SoCFPGA boot stack.

## When To Escalate

We should consider replacing more of the stack if:

- the old kernel is too incompatible with the new rootfs
- required FPGA bridge or driver features are missing
- we need a cleaner long-term maintenance path than the vendor kernel provides

At that point, the next step should likely be:

- replace kernel and DTB together

not:

- replace SPL/preloader first
