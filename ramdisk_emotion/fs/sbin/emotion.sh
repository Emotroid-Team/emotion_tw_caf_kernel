#!/system/bin/sh

PATH=/sbin:/system/sbin:/system/bin:/system/xbin
export PATH

BBX=/system/xbin/busybox

sleep 15

# Inicio
mount -o remount,rw -t auto /
mount -o remount,rw -t auto /system
mount -t rootfs -o remount,rw rootfs

if [ -f $BBX ]; then
	chown 0:2000 $BBX
	chmod 0755 $BBX
	$BBX --install -s /system/xbin
	ln -s $BBX /sbin/busybox
	ln -s $BBX /system/bin/busybox
	sync
fi

# Set environment and create symlinks: /bin, /etc, /lib, and /etc/mtab
set_environment ()
{
	# create /bin symlinks
	if [ ! -e /bin ]; then
		$BBX ln -s /system/bin /bin
	fi

	# create /etc symlinks
	if [ ! -e /etc ]; then
		$BBX ln -s /system/etc /etc
	fi

	# create /lib symlinks
	if [ ! -e /lib ]; then
		$BBX ln -s /system/lib /lib
	fi

	# symlink /etc/mtab to /proc/self/mounts
	if [ ! -e /system/etc/mtab ]; then
		$BBX ln -s /proc/self/mounts /system/etc/mtab
	fi
}

if [ -x $BBX ]; then
	set_environment
fi

#Supersu
/system/xbin/daemonsu --auto-daemon &

sync

# kernel custom test
if [ -e /data/emotiontest.log ]; then
	rm /data/emotiontest.log
fi

echo  Kernel script is working !!! >> /data/emotiontest.log
echo "excecuted on $(date +"%d-%m-%Y %r" )" >> /data/emotiontest.log
echo  Done ! >> /data/emotiontest.log

sync

#SSWAP to 1.2gb
/res/ext/sswap.sh

# Execute setenforce to permissive (workaround as it is already permissive that time)
/system/bin/setenforce 0

# Allow untrusted apps to read from debugfs (mitigate SELinux denials)
/system/xbin/supolicy --live \
	"allow untrusted_app debugfs file { open read getattr }" \
	"allow untrusted_app sysfs_lowmemorykiller file { open read getattr }" \
	"allow untrusted_app sysfs_devices_system_iosched file { open read getattr }" \
	"allow untrusted_app persist_file dir { open read getattr }" \
	"allow debuggerd gpu_device chr_file { open read getattr }" \
	"allow netd netd capability fsetid" \
	"allow netd { hostapd dnsmasq } process fork" \
	"allow { system_app shell } dalvikcache_data_file file write" \
	"allow { zygote mediaserver bootanim appdomain }  theme_data_file dir { search r_file_perms r_dir_perms }" \
	"allow { zygote mediaserver bootanim appdomain }  theme_data_file file { r_file_perms r_dir_perms }" \
	"allow system_server { rootfs resourcecache_data_file } dir { open read write getattr add_name setattr create remove_name rmdir unlink link }" \
	"allow system_server resourcecache_data_file file { open read write getattr add_name setattr create remove_name unlink link }" \
	"allow system_server dex2oat_exec file rx_file_perms" \
	"allow mediaserver mediaserver_tmpfs file execute" \
	"allow drmserver theme_data_file file r_file_perms" \
	"allow zygote system_file file write" \
	"allow atfwd property_socket sock_file write" \
	"allow untrusted_app sysfs_display file { open read write getattr add_name setattr remove_name }" \
	"allow debuggerd app_data_file dir search"

# Make internal storage directory
if [ ! -d /data/.emotionkernel ]; then
	mkdir /data/.emotionkernel
fi

# Disable knox
	pm disable com.sec.enterprise.knox.cloudmdm.smdms
	pm disable com.sec.knox.bridge
	pm disable com.sec.enterprise.knox.attestation
	pm disable com.sec.knox.knoxsetupwizardclient
	pm disable com.samsung.knox.rcp.components	
	pm disable com.samsung.android.securitylogagent

# init.d
chmod 755 /system/etc/init.d/ -R
if [ ! -d /system/etc/init.d ]; then
mkdir -p /system/etc/init.d/;
chown -R root.root /system/etc/init.d;
chmod 777 /system/etc/init.d/;
else
/sbin/busybox run-parts /system/etc/init.d
fi;

# frandom permissions
chmod 444 /dev/erandom
chmod 444 /dev/frandom

sync

#Set default values on boot
echo "200000000" > /sys/class/kgsl/kgsl-3d0/devfreq/min_freq
echo "600000000" > /sys/class/kgsl/kgsl-3d0/max_gpuclk
echo "1190400" > /sys/module/cpu_boost/parameters/input_boost_freq
echo "500" > /sys/module/cpu_boost/parameters/input_boost_ms

sync

stop thermal-engine
/system/xbin/busybox run-parts /system/etc/init.d
start thermal-engine

sync

#Fin
mount -t rootfs -o remount,ro rootfs
mount -o remount,ro -t auto /system
mount -o remount,ro -t auto /
