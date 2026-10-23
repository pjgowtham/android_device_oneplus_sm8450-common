# WAIPIO kernel 6.6 integration

Ferrari opts into this configuration with `TARGET_USES_KERNEL_6_6 := true`
before including BoardConfigCommon.mk. The other devices retain their
existing kernel selection until their board overlays are ported.

The Android build uses its existing Make/Kbuild integration, with sources
in kernel/oneplus/sm8750, sm8750-modules and sm8750-devicetrees. It does
not require a Bazel workspace. All three repositories must contain the
WAIPIO/Ferrari bring-up commits. The kernel's vendor DTS link selects the
relocated devicetrees repository.

Ferrari selects WAIPIO v1/v2 bases for dtb.img and its combined board,
audio, display and camera overlay for dtbo.img. Do not add the old split
techpack overlays to the new combined overlay.

The module lists use the 6.6 declared output names, with the kernel's
first-stage inventory for vendor boot and extra display/touch/charger
modules available in recovery. Module dependencies are collected from
the built modules. These lists are build inputs, not artifacts from a
successful full Bazel or Android image build. Missing modules and unknown
symbols remain build errors; they are not ignored.

Validation during integration: Android variable evaluation, merged kernel
configuration and native `dtbs` compilation. A full Android kernel/module
build and a Ferrari boot test are still required.
