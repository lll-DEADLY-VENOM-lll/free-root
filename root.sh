#!/bin/sh

ROOTFS_DIR=$(pwd)/ubuntu-fs
ARCH=$(uname -m)

# Purani 0-byte file aur folder saaf karein
rm -f ubuntu-rootfs.tar.gz
rm -rf "$ROOTFS_DIR"

# Architecture Check
if [ "$ARCH" = "x86_64" ]; then ARCH_ALT=amd64; else ARCH_ALT=arm64; fi

mkdir -p "$ROOTFS_DIR"

echo "--- Step 1: Downloading Ubuntu 22.04 (Forcing IPv4) ---"

# Sabse pehle Ubuntu Official se koshish (Forcing IPv4 with -4)
# Agar official link fail ho toh GitHub mirror use karenge
URL1="http://cdimage.ubuntu.com/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-${ARCH_ALT}.tar.gz"
URL2="https://mirrors.kernel.org/ubuntu-cdimage/ubuntu-base/releases/22.04/release/ubuntu-base-22.04-base-${ARCH_ALT}.tar.gz"

echo "Trying Official Ubuntu Mirror (IPv4)..."
wget -4 --no-check-certificate -O ubuntu-rootfs.tar.gz "$URL1"

if [ ! -s ubuntu-rootfs.tar.gz ]; then
    echo "Official Mirror fail hua. Mirror 2 (Kernel.org) try kar rahe hain..."
    wget -4 --no-check-certificate -O ubuntu-rootfs.tar.gz "$URL2"
fi

# Agar phir bhi fail ho, toh iska matlab firewall block kar raha hai
if [ ! -s ubuntu-rootfs.tar.gz ]; then
    echo "--------------------------------------------------------"
    echo "ERROR: Sabhi mirrors fail ho gaye."
    echo "Kripya yeh command chala kar check karein ki kya internet chal raha hai:"
    echo "curl -I -4 https://www.google.com"
    echo "--------------------------------------------------------"
    exit 1
fi

echo "--- Step 2: Extracting RootFS ---"
tar -xzf ubuntu-rootfs.tar.gz -C "$ROOTFS_DIR" || { echo "Extraction fail!"; exit 1; }
rm ubuntu-rootfs.tar.gz

echo "--- Step 3: Setting up Environment ---"
mkdir -p "$ROOTFS_DIR/usr/local/bin" "$ROOTFS_DIR/etc" "$ROOTFS_DIR/root"
echo "nameserver 1.1.1.1" > "$ROOTFS_DIR/etc/resolv.conf"

echo "Downloading PRoot..."
wget -4 --no-check-certificate -O "$ROOTFS_DIR/usr/local/bin/proot" "https://raw.githubusercontent.com/foxytouxxx/freeroot/main/proot-${ARCH}"
chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"

touch "$ROOTFS_DIR/.installed"

# Launch
clear
echo "Ubuntu 22.04 (ARM64) Started!"
"$ROOTFS_DIR/usr/local/bin/proot" \
  --rootfs="${ROOTFS_DIR}" \
  --link2symlink \
  -0 -w "/root" \
  -b /dev -b /sys -b /proc -b /etc/resolv.conf \
  --kill-on-exit \
  /bin/bash
