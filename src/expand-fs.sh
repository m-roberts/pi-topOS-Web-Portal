#!/bin/sh

get_variables() {
	ROOT_PART_DEV=$(findmnt / -o source -n)
	ROOT_PART_NAME=$(echo "$ROOT_PART_DEV" | cut -d "/" -f 3)
	ROOT_DEV_NAME=$(echo /sys/block/*/"${ROOT_PART_NAME}" | cut -d "/" -f 4)
	ROOT_DEV="/dev/${ROOT_DEV_NAME}"
	ROOT_PART_NUM=$(cat "/sys/block/${ROOT_DEV_NAME}/${ROOT_PART_NAME}/partition")

	OLD_DISKID=$(fdisk -l "$ROOT_DEV" | sed -n 's/Disk identifier: 0x\([^ ]*\)/\1/p')

	ROOT_DEV_SIZE=$(cat "/sys/block/${ROOT_DEV_NAME}/size")
	TARGET_END=$((ROOT_DEV_SIZE - 1))

	PARTITION_TABLE=$(parted -m "$ROOT_DEV" unit s print | tr -d 's')

	EXT_PART_LINE=$(echo "$PARTITION_TABLE" | grep ":::;" | head -n 1)
	EXT_PART_NUM=$(echo "$EXT_PART_LINE" | cut -d ":" -f 1)
}

fix_partuuid() {
	DISKID="$(fdisk -l "$ROOT_DEV" | sed -n 's/Disk identifier: 0x\([^ ]*\)/\1/p')"

	sed -i "s/${OLD_DISKID}/${DISKID}/g" /etc/fstab
	sed -i "s/${OLD_DISKID}/${DISKID}/" /boot/cmdline.txt
}

main() {
	get_variables

	# Note the Yes in the command to confirm the message:
	# Warning: Partition /dev/mmcblk0p2 is being used. Are you sure you want to continue?
	# This is not required in the second call

	echo "Resizing extended part"
	parted "${ROOT_DEV}" ---pretend-input-tty <<EOF
resizepart
${EXT_PART_NUM}
Yes
${TARGET_END}s
quit
EOF

	echo "Resizing rootfs part"
	parted "${ROOT_DEV}" ---pretend-input-tty <<EOF
resizepart
${ROOT_PART_NUM}
${TARGET_END}s
quit
EOF

	partprobe "$ROOT_DEV"
	fix_partuuid

	sudo resize2fs "$ROOT_PART_DEV"

	return 0
}

if ! grep -q splash /boot/cmdline.txt; then
	sed -i "s/ quiet//g" /boot/cmdline.txt
fi

sync

main

if [ -n "${FAIL_REASON}" ]; then
	echo "${FAIL_REASON}"
fi