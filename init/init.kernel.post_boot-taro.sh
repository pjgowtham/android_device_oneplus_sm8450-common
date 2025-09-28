#=============================================================================
# Copyright (c) 2020-2021 Qualcomm Technologies, Inc.
# All Rights Reserved.
# Confidential and Proprietary - Qualcomm Technologies, Inc.
#
# Copyright (c) 2009-2012, 2014-2019, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#=============================================================================

function configure_zram_parameters() {
	MemTotalStr=`cat /proc/meminfo | grep MemTotal`
	MemTotal=${MemTotalStr:16:8}

	low_ram=`getprop ro.config.low_ram`

	# Zram disk - 75% for Go and < 2GB devices .
	# For >2GB Non-Go devices, size = 50% of RAM size. Limit the size to 4GB.
	# And enable lz4 zram compression for Go targets.

	let RamSizeGB="( $MemTotal / 1048576 ) + 1"
	diskSizeUnit=M
	if [ $RamSizeGB -le 2 ]; then
		let zRamSizeMB="( $RamSizeGB * 1024 ) * 3 / 4"
	else
		let zRamSizeMB="( $RamSizeGB * 1024 ) / 2"
	fi

	# use MB avoid 32 bit overflow
	if [ $zRamSizeMB -gt 4096 ]; then
		let zRamSizeMB=4096
	fi

	if [ "$low_ram" == "true" ]; then
		echo lz4 > /sys/block/zram0/comp_algorithm
	fi

	#ifdef OPLUS_FEATURE_ZRAM_OPT
	#Huacai.Zhou@BSP.Kernel.MM, 2021/08/04, add zram opt
	echo lz4 > /sys/block/zram0/comp_algorithm
	echo 160 > /sys/module/zram_opt/parameters/vm_swappiness
	echo 60 > /sys/module/zram_opt/parameters/direct_vm_swappiness
	echo 0 > /proc/sys/vm/page-cluster
	#endif

	if [ -f /sys/block/zram0/disksize ]; then
		if [ -f /sys/block/zram0/use_dedup ]; then
			echo 1 > /sys/block/zram0/use_dedup
		fi
		echo "$zRamSizeMB""$diskSizeUnit" > /sys/block/zram0/disksize

		# ZRAM may use more memory than it saves if SLAB_STORE_USER
		# debug option is enabled.
		if [ -e /sys/kernel/slab/zs_handle ]; then
			echo 0 > /sys/kernel/slab/zs_handle/store_user
		fi
		if [ -e /sys/kernel/slab/zspage ]; then
			echo 0 > /sys/kernel/slab/zspage/store_user
		fi

		mkswap /dev/block/zram0
		swapon /dev/block/zram0 -p 32758
	fi
}

#ifdef OPLUS_FEATURE_ZRAM_OPT
function oplus_configure_zram_parameters() {
    MemTotalStr=`cat /proc/meminfo | grep MemTotal`
    MemTotal=${MemTotalStr:16:8}

    echo lz4 > /sys/block/zram0/comp_algorithm
    echo 160 > /sys/module/zram_opt/parameters/vm_swappiness
    echo 60 > /sys/module/zram_opt/parameters/direct_vm_swappiness
    echo 0 > /proc/sys/vm/page-cluster

    if [ -f /sys/block/zram0/disksize ]; then
        if [ -f /sys/block/zram0/use_dedup ]; then
            echo 1 > /sys/block/zram0/use_dedup
        fi

        if [ $MemTotal -le 524288 ]; then
            #config 384MB zramsize with ramsize 512MB
            echo 402653184 > /sys/block/zram0/disksize
        elif [ $MemTotal -le 1048576 ]; then
            #config 768MB zramsize with ramsize 1GB
            echo 805306368 > /sys/block/zram0/disksize
        elif [ $MemTotal -le 2097152 ]; then
            #config 1GB+256MB zramsize with ramsize 2GB
            echo lz4 > /sys/block/zram0/comp_algorithm
            echo 1342177280 > /sys/block/zram0/disksize
        elif [ $MemTotal -le 3145728 ]; then
            #config 1GB+512MB zramsize with ramsize 3GB
            echo 1610612736 > /sys/block/zram0/disksize
        elif [ $MemTotal -le 4194304 ]; then
            #config 2GB+512MB zramsize with ramsize 4GB
            echo 2684354560 > /sys/block/zram0/disksize
        elif [ $MemTotal -le 6291456 ]; then
            #config 3GB zramsize with ramsize 6GB
            echo 3221225472 > /sys/block/zram0/disksize
        else
            #config 4GB zramsize with ramsize >=8GB
            echo 4294967296 > /sys/block/zram0/disksize
        fi
        mkswap /dev/block/zram0
        swapon /dev/block/zram0 -p 32758
    fi
}

function oplus_configure_hybridswap() {
	kernel_version=`uname -r`

	if [[ "$kernel_version" == "5.10"* ]]; then
		echo 160 > /sys/module/oplus_bsp_zram_opt/parameters/vm_swappiness
	else
		echo 160 > /sys/module/zram_opt/parameters/vm_swappiness
	fi

	echo 0 > /proc/sys/vm/page-cluster

	# FIXME: set system memcg pata in init.kernel.post_boot-lahaina.sh temporary
	echo 500 > /dev/memcg/system/memory.app_score
	echo systemserver > /dev/memcg/system/memory.name
}

#/*Add swappiness tunning parameters*/
function oplus_configure_tuning_swappiness() {
	local MemTotalStr=`cat /proc/meminfo | grep MemTotal`
	local MemTotal=${MemTotalStr:16:8}
	local para_path=/proc/sys/vm
	local kernel_version=`uname -r`

	if [[ "$kernel_version" == "5.10"* ]]; then
		para_path=/sys/module/oplus_bsp_zram_opt/parameters
	fi

	if [ $MemTotal -le 6291456 ]; then
		echo 0 > $para_path/vm_swappiness_threshold1
		echo 0 > $para_path/swappiness_threshold1_size
		echo 0 > $para_path/vm_swappiness_threshold2
		echo 0 > $para_path/swappiness_threshold2_size
	elif [ $MemTotal -le 8388608 ]; then
		echo 70  > $para_path/vm_swappiness_threshold1
		echo 2000 > $para_path/swappiness_threshold1_size
		echo 90  > $para_path/vm_swappiness_threshold2
		echo 1500 > $para_path/swappiness_threshold2_size
	else
		echo 70  > $para_path/vm_swappiness_threshold1
		echo 4096 > $para_path/swappiness_threshold1_size
		echo 90  > $para_path/vm_swappiness_threshold2
		echo 2048 > $para_path/swappiness_threshold2_size
	fi
}
#endif /*OPLUS_FEATURE_ZRAM_OPT*/

function configure_read_ahead_kb_values() {
	MemTotalStr=`cat /proc/meminfo | grep MemTotal`
	MemTotal=${MemTotalStr:16:8}

	dmpts=$(ls /sys/block/*/queue/read_ahead_kb | grep -e dm -e mmc)

	# Set 128 for <= 3GB &
	# set 512 for >= 4GB targets.
	if [ $MemTotal -le 3145728 ]; then
		ra_kb=128
	else
		ra_kb=512
	fi
	if [ -f /sys/block/mmcblk0/bdi/read_ahead_kb ]; then
		echo $ra_kb > /sys/block/mmcblk0/bdi/read_ahead_kb
	fi
	if [ -f /sys/block/mmcblk0rpmb/bdi/read_ahead_kb ]; then
		echo $ra_kb > /sys/block/mmcblk0rpmb/bdi/read_ahead_kb
	fi
	for dm in $dmpts; do
		dm_dev=`echo $dm |cut -d/ -f4`
		if [ "$dm_dev" = "" ]; then
			is_erofs=""
		else
			is_erofs=`mount |grep erofs |grep "${dm_dev} "`
		fi
		if [ "$is_erofs" = "" ]; then
			echo $ra_kb > $dm
		else
			echo 128 > $dm
		fi
	done
}

function configure_memory_parameters() {
	# Set Memory parameters.
	#
	# Set per_process_reclaim tuning parameters
	# All targets will use vmpressure range 50-70,
	# All targets will use 512 pages swap size.
	#
	# Set Low memory killer minfree parameters
	# 32 bit Non-Go, all memory configurations will use 15K series
	# 32 bit Go, all memory configurations will use uLMK + Memcg
	# 64 bit will use Google default LMK series.
	#
	# Set ALMK parameters (usually above the highest minfree values)
	# vmpressure_file_min threshold is always set slightly higher
	# than LMK minfree's last bin value for all targets. It is calculated as
	# vmpressure_file_min = (last bin - second last bin ) + last bin
	#
	# Set allocstall_threshold to 0 for all targets.
	#
	MemTotalStr=`cat /proc/meminfo | grep MemTotal`
	MemTotal=${MemTotalStr:16:8}
#ifdef OPLUS_FEATURE_ZRAM_OPT
	# For vts test which has replace system.img
	if [ -L "/product" ]; then
		oplus_configure_zram_parameters
	else
		if [ -f /sys/block/zram0/hybridswap_enable ]; then
			oplus_configure_hybridswap
		else
			oplus_configure_zram_parameters
		fi
	fi
	oplus_configure_tuning_swappiness
#else
#       configure_zram_parameters
#endif /*OPLUS_FEATURE_ZRAM_OPT*/
	configure_read_ahead_kb_values
	echo 100 > /proc/sys/vm/swappiness

	# Disable periodic kcompactd wakeups. We do not use THP, so having many
	# huge pages is not as necessary.
	echo 0 > /proc/sys/vm/compaction_proactiveness

	# With THP enabled, the kernel greatly increases min_free_kbytes over its
	# default value. Disable THP to prevent resetting of min_free_kbytes
	# value during online/offline pages.
	# 11584kb is the standard kernel value of min_free_kbytes for 8Gb of lowmem
	if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
		echo never > /sys/kernel/mm/transparent_hugepage/enabled
	fi

	if [ $MemTotal -le 8388608 ]; then
		echo 40 > /proc/sys/vm/watermark_scale_factor
	else
		echo 16 > /proc/sys/vm/watermark_scale_factor
	fi

	echo 0 > /proc/sys/vm/watermark_boost_factor
	echo 11584 > /proc/sys/vm/min_free_kbytes
}

rev=`cat /sys/devices/soc0/revision`
ddr_type=`od -An -tx /proc/device-tree/memory/ddr_device_type`
ddr_type4="07"
ddr_type5="08"

# Core control parameters for gold
echo 2 > /sys/devices/system/cpu/cpu4/core_ctl/min_cpus
echo 60 > /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres
echo 30 > /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres
echo 100 > /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms
echo 3 > /sys/devices/system/cpu/cpu4/core_ctl/task_thres

# Core control parameters for gold+
echo 0 > /sys/devices/system/cpu/cpu7/core_ctl/min_cpus
echo 60 > /sys/devices/system/cpu/cpu7/core_ctl/busy_up_thres
echo 30 > /sys/devices/system/cpu/cpu7/core_ctl/busy_down_thres
echo 100 > /sys/devices/system/cpu/cpu7/core_ctl/offline_delay_ms
echo 1 > /sys/devices/system/cpu/cpu7/core_ctl/task_thres

# Controls how many more tasks should be eligible to run on gold CPUs
# w.r.t number of gold CPUs available to trigger assist (max number of
# tasks eligible to run on previous cluster minus number of CPUs in
# the previous cluster).
#
# Setting to 1 by default which means there should be at least
# 4 tasks eligible to run on gold cluster (tasks running on gold cores
# plus misfit tasks on silver cores) to trigger assitance from gold+.
echo 1 > /sys/devices/system/cpu/cpu7/core_ctl/nr_prev_assist_thresh

# Disable Core control on silver
echo 0 > /sys/devices/system/cpu/cpu0/core_ctl/enable

# Setting b.L scheduler parameters
echo 95 95 > /proc/sys/walt/sched_upmigrate
echo 85 85 > /proc/sys/walt/sched_downmigrate
echo 400 > /proc/sys/walt/sched_group_upmigrate
echo 380 > /proc/sys/walt/sched_group_downmigrate
echo 1 > /proc/sys/walt/sched_walt_rotate_big_tasks
echo 1000 > /proc/sys/walt/sched_min_task_util_for_colocation
echo 400000000 > /proc/sys/walt/sched_coloc_downmigrate_ns
echo 39000000 39000000 39000000 39000000 39000000 39000000 39000000 5000000 > /proc/sys/walt/sched_coloc_busy_hyst_cpu_ns
echo 240 > /proc/sys/walt/sched_coloc_busy_hysteresis_enable_cpus
echo 10 10 10 10 10 10 10 95 > /proc/sys/walt/sched_coloc_busy_hyst_cpu_busy_pct
echo 5000000 5000000 5000000 5000000 5000000 5000000 5000000 2000000 > /proc/sys/walt/sched_util_busy_hyst_cpu_ns
echo 255 > /proc/sys/walt/sched_util_busy_hysteresis_enable_cpus
echo 15 15 15 15 15 15 15 15 > /proc/sys/walt/sched_util_busy_hyst_cpu_util

# set the threshold for low latency task boost feature which prioritize
# binder activity tasks
echo 325 > /proc/sys/walt/walt_low_latency_task_threshold

# cpuset parameters
echo 0-3 > /dev/cpuset/background/cpus
echo 0-3 > /dev/cpuset/system-background/cpus

# Turn off scheduler boost at the end
echo 0 > /proc/sys/walt/sched_boost

# Reset the RT boost, which is 1024 (max) by default.
echo 0 > /proc/sys/kernel/sched_util_clamp_min_rt_default

# Limit kswapd in cpu0-6
echo `ps -elf | grep -v grep | grep kswapd0 | awk '{print $2}'` > /dev/cpuset/kswapd-like/tasks
echo `ps -elf | grep -v grep | grep kcompactd0 | awk '{print $2}'` > /dev/cpuset/kswapd-like/tasks

# configure governor settings for silver cluster
echo "walt" > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
echo 0 > /sys/devices/system/cpu/cpufreq/policy0/walt/down_rate_limit_us
echo 0 > /sys/devices/system/cpu/cpufreq/policy0/walt/up_rate_limit_us
if [ $rev == "1.0" ]; then
	echo 1190400 > /sys/devices/system/cpu/cpufreq/policy0/walt/hispeed_freq
else
	echo 1267200 > /sys/devices/system/cpu/cpufreq/policy0/walt/hispeed_freq
fi
echo 614400 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
echo 1 > /sys/devices/system/cpu/cpufreq/policy0/walt/pl

# configure input boost settings
if [ $rev == "1.0" ]; then
	echo 1382800 0 0 0 0 0 0 0 > /proc/sys/walt/input_boost/input_boost_freq
else
	echo 1171200 0 0 0 0 0 0 0 > /proc/sys/walt/input_boost/input_boost_freq
fi
echo 100 > /proc/sys/walt/input_boost/input_boost_ms

# configure governor settings for gold cluster
echo "walt" > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor
echo 0 > /sys/devices/system/cpu/cpufreq/policy4/walt/down_rate_limit_us
echo 0 > /sys/devices/system/cpu/cpufreq/policy4/walt/up_rate_limit_us
if [ $rev == "1.0" ]; then
	echo 1497600 > /sys/devices/system/cpu/cpufreq/policy4/walt/hispeed_freq
else
	echo 1555200 > /sys/devices/system/cpu/cpufreq/policy4/walt/hispeed_freq
fi
echo 1 > /sys/devices/system/cpu/cpufreq/policy4/walt/pl
echo "80 2112000:95" > /sys/devices/system/cpu/cpufreq/policy4/walt/target_loads

# config cpufreq_bouncing parameters for gold cluster
echo "1,1,13,30,2,50,1,50"  > /sys/module/cpufreq_bouncing/parameters/config

# configure governor settings for gold+ cluster
echo "walt" > /sys/devices/system/cpu/cpufreq/policy7/scaling_governor
echo 0 > /sys/devices/system/cpu/cpufreq/policy7/walt/down_rate_limit_us
echo 0 > /sys/devices/system/cpu/cpufreq/policy7/walt/up_rate_limit_us
if [ $rev == "1.0" ]; then
	echo 1536000 > /sys/devices/system/cpu/cpufreq/policy7/walt/hispeed_freq
else
	echo 1728000 > /sys/devices/system/cpu/cpufreq/policy7/walt/hispeed_freq
fi
echo 1 > /sys/devices/system/cpu/cpufreq/policy7/walt/pl
echo "80 2380800:95" > /sys/devices/system/cpu/cpufreq/policy7/walt/target_loads

# config cpufreq_bouncing parameters for gold+ cluster
echo "2,1,14,30,2,50,1,50"  > /sys/module/cpufreq_bouncing/parameters/config

#config power effiecny tunning parameters
echo 1 > /sys/module/cpufreq_effiency/parameters/affect_mode
echo "307200,45000,1363200,52000,0"  > /sys/module/cpufreq_effiency/parameters/cluster0_effiency
echo "633600,50000,1996800,55000,0"  > /sys/module/cpufreq_effiency/parameters/cluster1_effiency
echo "806400,55000,2054400,60000,0"  > /sys/module/cpufreq_effiency/parameters/cluster2_effiency

# configure bus-dcvs
bus_dcvs="/sys/devices/system/cpu/bus_dcvs"

for device in $bus_dcvs/*
do
	cat $device/hw_min_freq > $device/boost_freq
done

for llccbw in $bus_dcvs/LLCC/*bwmon-llcc
do
	echo "4577 7110 9155 12298 14236 15258" > $llccbw/mbps_zones
	echo 4 > $llccbw/sample_ms
	echo 80 > $llccbw/io_percent
	echo 20 > $llccbw/hist_memory
	echo 10 > $llccbw/hyst_length
	echo 30 > $llccbw/down_thres
	echo 0 > $llccbw/guard_band_mbps
	echo 250 > $llccbw/up_scale
	echo 1600 > $llccbw/idle_mbps
	echo 806000 > $llccbw/max_freq
	echo 40 > $llccbw/window_ms
done

for ddrbw in $bus_dcvs/DDR/*bwmon-ddr
do
	echo "1720 2086 2929 3879 6515 7980 12191" > $ddrbw/mbps_zones
	echo 4 > $ddrbw/sample_ms
	echo 80 > $ddrbw/io_percent
	echo 20 > $ddrbw/hist_memory
	echo 10 > $ddrbw/hyst_length
	echo 30 > $ddrbw/down_thres
	echo 0 > $ddrbw/guard_band_mbps
	echo 250 > $ddrbw/up_scale
	echo 1600 > $ddrbw/idle_mbps
	echo 2092000 > $ddrbw/max_freq
	echo 40 > $ddrbw/window_ms
done

for latfloor in $bus_dcvs/*/*latfloor
do
	echo 25000 > $latfloor/ipm_ceil
done

for l3gold in $bus_dcvs/L3/*gold
do
	echo 4000 > $l3gold/ipm_ceil
done

for l3prime in $bus_dcvs/L3/*prime
do
	echo 20000 > $l3prime/ipm_ceil
done

for ddrprime in $bus_dcvs/DDR/*prime
do
	echo 25 > $ddrprime/freq_scale_pct
	echo 1881 > $ddrprime/freq_scale_limit_mhz
done

for qosgold in $bus_dcvs/DDRQOS/*gold
do
	echo 50 > $qosgold/ipm_ceil
done

if [ "$rev" == "1.0" ]; then
	echo Y > /sys/devices/system/cpu/qcom_lpm/parameters/sleep_disabled
	echo 1 > /sys/devices/system/cpu/cpu0/cpuidle/state1/disable
	echo 1 > /sys/devices/system/cpu/cpu1/cpuidle/state1/disable
	echo 1 > /sys/devices/system/cpu/cpu2/cpuidle/state1/disable
	echo 1 > /sys/devices/system/cpu/cpu3/cpuidle/state1/disable
	echo 1 > /sys/devices/system/cpu/cpu4/cpuidle/state1/disable
	echo 1 > /sys/devices/system/cpu/cpu5/cpuidle/state1/disable
	echo 1 > /sys/devices/system/cpu/cpu6/cpuidle/state1/disable
	echo 1 > /sys/devices/system/cpu/cpu7/cpuidle/state1/disable
	echo 0 > "/sys/devices/platform/hypervisor/hypervisor:qcom,gh-watchdog/wakeup_enable"
else
	echo N > /sys/devices/system/cpu/qcom_lpm/parameters/sleep_disabled
fi

echo s2idle > /sys/power/mem_sleep
configure_memory_parameters

# Let kernel know our image version/variant/crm_version
if [ -f /sys/devices/soc0/select_image ]; then
	image_version="10:"
	image_version+=`getprop ro.build.id`
	image_version+=":"
	image_version+=`getprop ro.build.version.incremental`
	image_variant=`getprop ro.product.name`
	image_variant+="-"
	image_variant+=`getprop ro.build.type`
	oem_version=`getprop ro.build.version.codename`
	echo 10 > /sys/devices/soc0/select_image
	echo $image_version > /sys/devices/soc0/image_version
	echo $image_variant > /sys/devices/soc0/image_variant
	echo $oem_version > /sys/devices/soc0/image_crm_version
fi

# Change console log level as per console config property
console_config=`getprop persist.vendor.console.silent.config`
case "$console_config" in
	"1")
		echo "Enable console config to $console_config"
		echo 0 > /proc/sys/kernel/printk
	;;
	*)
		echo "Enable console config to $console_config"
	;;
esac

chown -h system.system /sys/devices/system/cpu/cpufreq/policy0/schedutil/target_loads
chown -h system.system /sys/devices/system/cpu/cpufreq/policy4/schedutil/target_loads
chown -h system.system /sys/devices/system/cpu/cpufreq/policy7/schedutil/target_loads

#config fg and top cpu shares
echo 5120 > /dev/cpuctl/top-app/cpu.shares
echo 4096 > /dev/cpuctl/foreground/cpu.shares

setprop vendor.post_boot.parsed 1
