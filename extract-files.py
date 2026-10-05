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
    'device/oneplus/sm8750-common',
    'hardware/qcom-caf/sm8750',
    'hardware/qcom-caf/wlan',
    'hardware/oplus',
    'vendor/qcom/opensource/commonsys/display',
    'vendor/qcom/opensource/commonsys-intf/display',
    'vendor/qcom/opensource/dataservices',
]


def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_{partition}' if partition == 'vendor' else None

lib_fixups: lib_fixups_user_type = {
    **lib_fixups,
    (
        'vendor.qti.ImsRtpService-V1-ndk',
        'vendor.qti.diaghal-V1-ndk',
        'vendor.qti.hardware.dpmaidlservice-V1-ndk',
        'vendor.qti.hardware.wifidisplaysession_aidl-V1-ndk',
        'vendor.qti.qccsyshal_aidl-V1-ndk',
        'vendor.qti.qccvndhal_aidl-V1-ndk',
    ): lib_fixup_vendor_suffix,
}

blob_fixups: blob_fixups_user_type = {
    'odm/bin/hw/vendor.oplus.hardware.biometrics.fingerprint@2.1-service_uff': blob_fixup()
        .add_needed('libshims_aidl_fingerprint_v3.oplus.so'),
    (
        'odm/bin/touchDaemon',
        'odm/bin/hw/vendor-oplus-hardware-touch-V2-service',
        'odm/bin/hw/vendor.oplus.hardware.biometrics.fingerprint@2.1-service_uff',
        'vendor/lib64/hw/libaudioeffecthal.qti.so',
        'vendor/lib64/soundfx/libquasar.so',
    ): blob_fixup()
        .replace_needed('libtinyxml2.so', 'libtinyxml2-v34.so'),
    'odm/etc/init/init.network.rc': blob_fixup()
        .regex_replace(r'/\* (Huo\.Chen@SYSTEM\.RF, 2024/09/06, Add for ICC) \*/', r'# \1'),
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
    'vendor/bin/system_dlkm_modprobe.sh': blob_fixup()
        .regex_replace(r'.*\bzram or zsmalloc\b.*\n', '')
        .regex_replace(r'-e "zram" -e "zsmalloc"', ''),
    'vendor/bin/vendor_modprobe.sh': blob_fixup()
        .regex_replace(r'\n.*OPLUS_FEATURE_WIFI_FTM[\s\S]*?OPLUS_FEATURE_WIFI_FTM.*\n', ''),
    'vendor/etc/clstc_config_library.xml': blob_fixup()
        .regex_replace(r'\n.*OPLUS_FEATURE_DSIPLAY[\s\S]*?OPLUS_FEATURE_DSIPLAY.*\n', ''),
    'vendor/etc/media_codecs_sun.xml': blob_fixup()
        .regex_replace('.*media_codecs_(google_audio|google_c2|google_telephony|google_video).*\n', '')
        .regex_replace('media_codecs_vendor_audio', 'media_codecs_dolby_vision'),
    'vendor/etc/seccomp_policy/gnss@2.0-qsap-location.policy': blob_fixup()
        .add_line_if_missing('sched_get_priority_min: 1')
        .add_line_if_missing('sched_get_priority_max: 1'),
    'vendor/lib64/hw/libaudiocorehal.qti.so': blob_fixup()
        .replace_needed('libaudio_aidl_conversion_common_ndk.so', 'libaudio_aidl_conversion_common_ndk_prebuilt.so'),
    'vendor/lib64/android.hardware.bluetooth.audio-impl_prebuilt.so': blob_fixup()
        .replace_needed('libbluetooth_audio_session_aidl.so', 'libbluetooth_audio_session_aidl_prebuilt.so'),
    (
        'vendor/lib64/libVoiceSdk.so',
        'vendor/lib64/libcapiv2uvvendor.so',
        'vendor/lib64/liblistensoundmodel2vendor.so',
    ): blob_fixup()
        .replace_needed('libtensorflowlite_c.so', 'libtensorflowlite_c_vendor.so'),
    'vendor/lib64/libqti-perfd.so': blob_fixup()
        .replace_needed('vendor.qti.hardware.display.config-V5-ndk.so', 'vendor.qti.hardware.display.config-V12-ndk.so'),
    'vendor/lib64/libaudioserviceexampleimpl.so': blob_fixup()
        .add_needed('libaudioutils_shim.so')
        .replace_needed('android.hardware.bluetooth.audio-impl.so', 'android.hardware.bluetooth.audio-impl_prebuilt.so')
        .replace_needed('libaudio_aidl_conversion_common_ndk.so', 'libaudio_aidl_conversion_common_ndk_prebuilt.so')
        .replace_needed('libbluetooth_audio_session_aidl.so', 'libbluetooth_audio_session_aidl_prebuilt.so'),
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
    'vendor/lib64/libwfdmmsrc_proprietary.so': blob_fixup()
        .replace_needed('android.media.audio.common.types-V2-ndk.so', 'android.media.audio.common.types-V3-ndk.so'),
}  # fmt: skip

module = ExtractUtilsModule(
    'sm8750-common',
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
