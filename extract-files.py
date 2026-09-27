#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import (
    blob_fixup,
    blob_fixups_user_type,
)
from extract_utils.fixups_lib import (
    lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import (
    ExtractUtils,
    ExtractUtilsModule,
)

namespace_imports = [
    'device/oneplus/sm8450-common',
    'hardware/qcom-caf/sm8450-6.6',
    'hardware/qcom-caf/wlan',
    'hardware/oplus',
    'hardware/pixelworks/interfaces',
    'vendor/qcom/opensource/commonsys/display',
    'vendor/qcom/opensource/commonsys-intf/display',
    'vendor/qcom/opensource/dataservices',
]


def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_{partition}' if partition == 'vendor' else None

lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
    (
        'com.qualcomm.qti.dpm.api@1.0',
        'libmmosal',
        'vendor.qti.ImsRtpService-V1-ndk',
        'vendor.qti.diaghal-V1-ndk',
        'vendor.qti.diaghal@1.0',
        'vendor.qti.hardware.dpmaidlservice-V1-ndk',
        'vendor.qti.hardware.dpmservice@1.0',
        'vendor.qti.hardware.dpmservice@1.1',
        'vendor.qti.hardware.qccsyshal@1.0',
        'vendor.qti.hardware.qccsyshal@1.1',
        'vendor.qti.hardware.qccvndhal@1.0',
        'vendor.qti.hardware.wifidisplaysession@1.0',
        'vendor.qti.hardware.wifidisplaysession_aidl-V1-ndk',
        'vendor.qti.imsrtpservice@3.0',
        'vendor.qti.qccsyshal_aidl-V1-ndk',
        'vendor.qti.qccvndhal_aidl-V1-ndk',
    ): lib_fixup_vendor_suffix,
}

blob_fixups: blob_fixups_user_type = {
    'odm/bin/hw/vendor.oplus.hardware.biometrics.fingerprint@2.1-service_uff': blob_fixup()
        .add_needed('libshims_aidl_fingerprint_v3.oplus.so'),
    (
        'odm/bin/touchDaemon',
        'odm/bin/hw/vendor.oplus.hardware.biometrics.fingerprint@2.1-service_uff',
    ): blob_fixup()
        .replace_needed('libtinyxml2.so', 'libtinyxml2-v34.so'),
    'product/etc/sysconfig/com.android.hotwordenrollment.common.util.xml': blob_fixup()
        .regex_replace('/my_product', '/product'),
    'system/framework/WfdCommon.jar': blob_fixup()
        .apktool_patch('blob-patches/WfdCommon.patch'),
    'system_ext/bin/horae': blob_fixup()
        .replace_needed('libprotobuf-cpp-lite.so', 'libprotobuf-cpp-lite-21.7.so'),
    (
        'system_ext/etc/seccomp_policy/tcmd.policy',
        'vendor/etc/seccomp_policy/syshealthmon.policy'
    ): blob_fixup()
        .add_line_if_missing('lseek: 1'),
    'system_ext/lib64/libwfdservice.so': blob_fixup()
        .replace_needed('android.media.audio.common.types-V4-cpp.so', 'android.media.audio.common.types-V5-cpp.so'),
    (
        'vendor/bin/hw/vendor.qti.media.c2@1.0-service',
        'vendor/bin/hw/vendor.qti.media.c2audio@1.0-service',
    ): blob_fixup()
        .binary_regex_replace(b'\x00\x21\x80\x52', b'\x00\x24\x80\x52'),
    'vendor/etc/clstc_config_library.xml': blob_fixup()
        .regex_replace(r'\n.*OPLUS_FEATURE_DSIPLAY[\s\S]*?OPLUS_FEATURE_DSIPLAY.*\n', ''),
    # Renumber the waipio QoS bandwidth limits for the pdx257 QoS parser.
    'vendor/etc/display/DPU8__.xml': blob_fixup()
        .regex_replace(r'\n[ \t]*<Param6[2-6]>[^<]*</Param6[2-6]>', '')
        .regex_replace(
            r'(<Param61>[^<]*</Param61>)',
            r'\1\n  <Param70>18200000</Param70>\n  <Param71>13600000</Param71>'
            r'\n  <Param72>18200000</Param72>\n  <Param73>13600000</Param73>'
            r'\n  <Param76>3900</Param76>\n  <Param77>3900</Param77>',
        ),
    'vendor/etc/seccomp_policy/gnss@2.0-qsap-location.policy': blob_fixup()
        .add_line_if_missing('sched_get_priority_min: 1')
        .add_line_if_missing('sched_get_priority_max: 1'),
    'vendor/lib64/libdisplayqos.so': blob_fixup()
        .binary_regex_replace(b'\x68\x00\xb0\x52', b'\x28\x00\xb0\x52') # hw version 0x80030000 -> 0x80010000
        .binary_regex_replace(rb'DPU830\.xml', b'DPU8__.xml'),
    (
        'vendor/lib64/libhwcsensor.so',
        'vendor/lib64/libsdmclient.so',
    ): blob_fixup()
        .replace_needed('vendor.qti.hardware.display.config-V11-ndk.so', 'vendor.qti.hardware.display.config-V12-ndk.so'),
    (
        'vendor/lib64/libloc_api_v02.so',
        'vendor/lib64/libloc_core.so',
    ): blob_fixup()
        .add_needed('libbase.so'),
    'odm/bin/hw/vendor.oplus.hardware.charger-V10-service': blob_fixup()
        .add_needed('libbase_shim.so'),
    'odm/lib64/mediadrm/libwvdrmengine.so': blob_fixup()
        .add_needed('libcrypto_shim.so'),
    'system_ext/lib64/libwfdnative.so': blob_fixup()
        .add_needed('libinput_shim.so'),
    'system_ext/lib64/vendor.qti.hardware.qccsyshal@1.2-halimpl.so': blob_fixup()
        .replace_needed('libprotobuf-cpp-full.so', 'libprotobuf-cpp-full-21.7.so'),
    'vendor/bin/qguard': blob_fixup()
        .add_needed('libbase_shim.so'),
    ('vendor/etc/media_codecs_cape_vendor.xml', 'vendor/etc/media_codecs_taro_vendor.xml'): blob_fixup()
        .regex_replace('.*media_codecs_(google_audio|google_c2|google_telephony|vendor_audio).*\n', ''),
    'vendor/etc/msm_irqbalance.conf': blob_fixup()
        .regex_replace('IGNORED_IRQ=27,23,38$', 'IGNORED_IRQ=27,23,38,115,332'),
    ('vendor/bin/hw/android.hardware.gnss-aidl-service-qti', 'vendor/lib64/hw/android.hardware.gnss-aidl-impl-qti.so', 'vendor/lib64/libgarden.so', 'vendor/lib64/libgarden_haltests_e2e.so'): blob_fixup()
        .replace_needed('android.hardware.gnss-V1-ndk_platform.so', 'android.hardware.gnss-V1-ndk.so'),
    ('vendor/bin/hw/android.hardware.identity-service-qti', 'vendor/lib64/libqtiidentitycredential.so'): blob_fixup()
        .replace_needed('android.hardware.identity-V3-ndk_platform.so', 'android.hardware.identity-V3-ndk.so')
        .replace_needed('android.hardware.keymaster-V3-ndk_platform.so', 'android.hardware.keymaster-V3-ndk.so'),
    ('vendor/bin/hw/android.hardware.security.keymint-service-qti', 'vendor/lib64/libqtikeymint.so'): blob_fixup()
        .replace_needed('android.hardware.security.keymint-V1-ndk_platform.so', 'android.hardware.security.keymint-V1-ndk.so')
        .replace_needed('android.hardware.security.secureclock-V1-ndk_platform.so', 'android.hardware.security.secureclock-V1-ndk.so')
        .replace_needed('android.hardware.security.sharedsecret-V1-ndk_platform.so', 'android.hardware.security.sharedsecret-V1-ndk.so')
        .add_needed('android.hardware.security.rkp-V1-ndk.so'),
    ('vendor/lib64/libqcrilNr.so', 'vendor/lib64/libril-db.so'): blob_fixup()
        .binary_regex_replace(rb'persist\.vendor\.radio\.poweron_opt', rb'persist.vendor.radio.poweron_ign'),
    'vendor/lib64/hw/vulkan.adreno.so': blob_fixup()
        .binary_regex_replace( # BV CP_WAIT_TIMESTAMP onchip 1 -> CP_NOP
              b'\x03\x80\x94\x70\x12\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00',
              b'\x03\x80\x10\x70\x12\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00',
        )
        .binary_regex_replace( # BV CP_WAIT_TIMESTAMP onchip 3 -> CP_NOP
              b'\x03\x80\x94\x70\x12\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00\x00',
              b'\x03\x80\x10\x70\x12\x00\x00\x00\x03\x00\x00\x00\x00\x00\x00\x00',
        ),
    'vendor/lib64/vendor.libdpmframework.so': blob_fixup()
        .add_needed('libhidlbase_shim.so'),
}  # fmt: skip

module = ExtractUtilsModule(
    'sm8450-common',
    'oneplus',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
)

module.add_proprietary_file('proprietary-files-phone.txt').add_copy_files_guard(
    'TARGET_IS_TABLET', 'true', invert=True
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
